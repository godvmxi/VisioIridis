import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../model_store/model_selector.dart';
import '../platform/keep_alive.dart';
import '../platform/system_audio.dart';
import 'asr_engine.dart';
import 'asr_language.dart';
import 'prepared_model.dart';
import 'sherpa_worker.dart';

/// 真实识别引擎：采集 16kHz 单声道 PCM（麦克风或系统播放的声音），交给常驻的
/// 推理 Isolate（sherpa-onnx Silero-VAD + SenseVoice/TeleSpeech）处理。
class SherpaAsrEngine implements AsrEngine {
  final _events = StreamController<AsrEvent>.broadcast();
  final _recorder = AudioRecorder();

  Isolate? _isolate;
  ReceivePort? _inbox;
  SendPort? _worker;
  PreparedModel? _loaded;
  StreamSubscription<Uint8List>? _audio;
  AudioInput _input = AudioInput.microphone;

  @override
  Stream<AsrEvent> get events => _events.stream;

  @override
  Future<void> start(PreparedModel model, Set<AsrLanguage> languages) async {
    if (!await _recorder.hasPermission()) {
      throw const AsrStartException(AsrIssue.micPermissionDenied);
    }
    if (_loaded?.asrModelDir != model.asrModelDir) {
      await _shutdownWorker();
      await _spawnWorker(model, languages);
    } else {
      updateLanguages(languages);
    }

    await _startInput(AudioInput.microphone);
    await WakelockPlus.enable();
    // Android 14+ 要求麦克风前台服务在 App 处于前台时启动，即此刻。
    await KeepAlive.start();
  }

  @override
  Future<void> stop() async {
    await _stopInput();
    await WakelockPlus.disable();
    await KeepAlive.stop();
  }

  @override
  Future<void> setAudioInput(AudioInput input) async {
    if (input == _input || _audio == null) return;
    await _stopInput();
    try {
      await _startInput(input);
    } catch (_) {
      await _startInput(AudioInput.microphone);
      rethrow;
    }
  }

  /// 开始从 [input] 读取 PCM 并送入推理 Isolate。
  Future<void> _startInput(AudioInput input) async {
    final Stream<Uint8List> stream;
    switch (input) {
      case AudioInput.microphone:
        stream = await _recorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
            noiseSuppress: true,
          ),
        );
      case AudioInput.systemAudio:
        // 先订阅再请求授权，避免漏掉授权后立即到来的数据。
        stream = SystemAudioCapture.pcm;
    }
    _input = input;
    _audio = stream.listen(
      (chunk) => _worker?.send(chunk),
      onError: (Object e) => _fail(AsrIssue.recordingInterrupted, '$e'),
      onDone: input == AudioInput.systemAudio ? _onSystemAudioEnded : null,
    );
    if (input == AudioInput.systemAudio && !await SystemAudioCapture.start()) {
      await _audio?.cancel();
      _audio = null;
      _input = AudioInput.microphone;
      throw const AsrStartException(AsrIssue.speakerDenied);
    }
  }

  Future<void> _stopInput() async {
    final input = _input;
    await _audio?.cancel();
    _audio = null;
    _input = AudioInput.microphone;
    switch (input) {
      case AudioInput.microphone:
        await _recorder.stop();
      case AudioInput.systemAudio:
        await SystemAudioCapture.stop();
    }
    // 换来源或停止时，把正在说的句子按句尾处理。
    _worker?.send(const WorkerFlush());
  }

  /// 系统声音录制被用户或系统结束（如在通知栏停止）时自动回到麦克风。
  Future<void> _onSystemAudioEnded() async {
    if (_input != AudioInput.systemAudio || _audio == null) return;
    _audio = null;
    _input = AudioInput.microphone;
    _worker?.send(const WorkerFlush());
    try {
      await _startInput(AudioInput.microphone);
      _events.add(
        const AsrInputChanged(AudioInput.microphone, AsrIssue.speakerEnded),
      );
    } catch (e) {
      _fail(AsrIssue.switchBackFailed, '$e');
    }
  }

  @override
  void updateLanguages(Set<AsrLanguage> languages) {
    final model = _loaded;
    if (model == null) return;
    final codes = languages.map((l) => l.code).toSet();
    _worker?.send(
      WorkerLanguages(decodeParamFor(model.asrModel, codes), codes),
    );
  }

  @override
  void dispose() {
    _audio?.cancel();
    _recorder.dispose();
    _shutdownWorker();
    _events.close();
  }

  Future<void> _spawnWorker(
    PreparedModel model,
    Set<AsrLanguage> languages,
  ) async {
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
            ready.completeError(
              AsrStartException(AsrIssue.modelLoadFailed, message),
            );
          } else {
            _fail(AsrIssue.recognitionFailed, message);
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

  void _fail(AsrIssue issue, String detail) {
    stop();
    _events.add(AsrError(issue, detail));
  }
}
