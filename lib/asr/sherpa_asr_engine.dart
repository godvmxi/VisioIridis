import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../model_store/model_selector.dart';
import 'asr_engine.dart';
import 'asr_language.dart';
import 'prepared_model.dart';
import 'sherpa_worker.dart';

/// 真实识别引擎：record 采集 16kHz 单声道 PCM，交给常驻的推理 Isolate
/// （sherpa-onnx Silero-VAD + SenseVoice/TeleSpeech）处理。
class SherpaAsrEngine implements AsrEngine {
  final _events = StreamController<AsrEvent>.broadcast();
  final _recorder = AudioRecorder();

  Isolate? _isolate;
  ReceivePort? _inbox;
  SendPort? _worker;
  PreparedModel? _loaded;
  StreamSubscription<Uint8List>? _audio;

  @override
  Stream<AsrEvent> get events => _events.stream;

  @override
  Future<void> start(PreparedModel model, Set<AsrLanguage> languages) async {
    if (!await _recorder.hasPermission()) {
      throw const AsrStartException('需要麦克风权限才能识别');
    }
    if (_loaded?.asrModelDir != model.asrModelDir) {
      await _shutdownWorker();
      await _spawnWorker(model, languages);
    } else {
      updateLanguages(languages);
    }

    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
      noiseSuppress: true,
    ));
    _audio = stream.listen(
      (chunk) => _worker?.send(chunk),
      onError: (Object e) => _fail('录音中断：$e'),
    );
    await WakelockPlus.enable();
  }

  @override
  Future<void> stop() async {
    await _audio?.cancel();
    _audio = null;
    await _recorder.stop();
    _worker?.send(const WorkerFlush());
    await WakelockPlus.disable();
  }

  @override
  void updateLanguages(Set<AsrLanguage> languages) {
    final model = _loaded;
    if (model == null) return;
    final codes = languages.map((l) => l.code).toSet();
    _worker?.send(
        WorkerLanguages(decodeParamFor(model.asrModel, codes), codes));
  }

  @override
  void dispose() {
    _audio?.cancel();
    _recorder.dispose();
    _shutdownWorker();
    _events.close();
  }

  Future<void> _spawnWorker(
      PreparedModel model, Set<AsrLanguage> languages) async {
    final inbox = ReceivePort();
    final ready = Completer<void>();
    final codes = languages.map((l) => l.code).toSet();

    inbox.listen((message) {
      switch (message) {
        case SendPort port:
          _worker = port;
        case WorkerReady():
          ready.complete();
        case WorkerFailed(:final message):
          if (!ready.isCompleted) {
            ready.completeError(AsrStartException('模型加载失败：$message'));
          } else {
            _fail('识别出错：$message');
          }
        case AsrEvent event:
          _events.add(event);
      }
    });

    _inbox = inbox;
    _isolate = await Isolate.spawn(
      sherpaWorkerMain,
      WorkerInit(
        replyTo: inbox.sendPort,
        vadModelPath: model.vadModelPath,
        modelType: model.asrModel.type,
        modelPath: model.modelPath,
        tokensPath: model.tokensPath,
        decodeParam: decodeParamFor(model.asrModel, codes),
        allowedLanguages: codes,
      ),
      debugName: 'sherpa-asr',
    );
    try {
      await ready.future;
      _loaded = model;
    } catch (_) {
      await _shutdownWorker();
      rethrow;
    }
  }

  Future<void> _shutdownWorker() async {
    _worker?.send(const WorkerShutdown());
    _worker = null;
    _inbox?.close();
    _inbox = null;
    // 给 Isolate 释放原生资源的时间，再强制结束。
    final isolate = _isolate;
    _isolate = null;
    _loaded = null;
    if (isolate != null) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      isolate.kill();
    }
  }

  void _fail(String message) {
    stop();
    _events.add(AsrError(message));
  }
}

class AsrStartException implements Exception {
  const AsrStartException(this.message);

  final String message;

  @override
  String toString() => message;
}
