import 'dart:collection';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'asr_engine.dart';
import 'audio_utils.dart';
import 'tag_formatter.dart';

// ---- 主 Isolate 与推理 Isolate 之间的消息 ----

class WorkerInit {
  const WorkerInit({
    required this.replyTo,
    required this.vadModelPath,
    required this.modelType,
    required this.modelPath,
    required this.tokensPath,
    required this.decodeParam,
    required this.allowedLanguages,
  });

  final SendPort replyTo;
  final String vadModelPath;

  /// 模型配置中的 type："sense_voice" / "telespeech_ctc"
  final String modelType;
  final String modelPath;
  final String tokensPath;
  final String? decodeParam;
  final Set<String> allowedLanguages;
}

class WorkerReady {
  const WorkerReady();
}

class WorkerFailed {
  const WorkerFailed(this.message);

  final String message;
}

class WorkerLanguages {
  const WorkerLanguages(this.decodeParam, this.allowedLanguages);

  final String? decodeParam;
  final Set<String> allowedLanguages;
}

/// 停止拾音：把尚未结束的语音按句尾处理，然后清空状态。
class WorkerFlush {
  const WorkerFlush();
}

class WorkerShutdown {
  const WorkerShutdown();
}

/// 推理 Isolate 入口（PRD 第 3 章）：VAD 切句，说话中周期性重解码出临时结果，
/// 句尾整段解码出定稿结果。模型只在启动时加载一次。
void sherpaWorkerMain(WorkerInit init) {
  final inbox = ReceivePort();
  init.replyTo.send(inbox.sendPort);

  final _SherpaPipeline pipeline;
  try {
    sherpa.initBindings();
    pipeline = _SherpaPipeline(init);
  } catch (e) {
    init.replyTo.send(WorkerFailed('$e'));
    inbox.close();
    return;
  }
  init.replyTo.send(const WorkerReady());

  inbox.listen((message) {
    try {
      switch (message) {
        case Uint8List bytes:
          pipeline.acceptPcm(bytes);
        case WorkerLanguages(:final decodeParam, :final allowedLanguages):
          pipeline.setLanguages(decodeParam, allowedLanguages);
        case WorkerFlush():
          pipeline.flush();
        case WorkerShutdown():
          pipeline.free();
          inbox.close();
      }
    } catch (e) {
      init.replyTo.send(WorkerFailed('$e'));
    }
  });
}

class _SherpaPipeline {
  _SherpaPipeline(WorkerInit init)
    : _out = init.replyTo,
      _init = init,
      _allowed = init.allowedLanguages,
      _currentParam = init.decodeParam {
    _vad = sherpa.VoiceActivityDetector(
      config: sherpa.VadModelConfig(
        sileroVad: sherpa.SileroVadModelConfig(
          model: init.vadModelPath,
          // PRD 4.3：停顿 400ms 判定句尾；单句最长 15s（第 3 章）。
          minSilenceDuration: 0.4,
          minSpeechDuration: 0.25,
          maxSpeechDuration: 15,
          windowSize: _windowSize,
        ),
        sampleRate: _sampleRate,
        debug: false,
      ),
      bufferSizeInSeconds: 30,
    );
    _recognizer = sherpa.OfflineRecognizer(_recognizerConfig(init.decodeParam));
  }

  static const _sampleRate = 16000;
  static const _windowSize = 512;

  /// 每新增约 300ms 音频重解码一次临时结果。
  static const _partialInterval = _sampleRate * 3 ~/ 10;

  /// 检测到说话时向前补的音频（约 0.5s），避免句首被截掉。
  static const _prerollWindows = 16;

  final SendPort _out;
  final WorkerInit _init;
  late final sherpa.VoiceActivityDetector _vad;
  late final sherpa.OfflineRecognizer _recognizer;
  Set<String> _allowed;
  String? _currentParam;

  final _decoder = Pcm16Decoder();
  final _windower = SampleWindower(_windowSize);
  final _preroll = ListQueue<Float32List>();
  final _utterance = <Float32List>[];
  bool _speaking = false;
  int _sinceLastPartial = 0;

  bool get _hasLanguageTags => _init.modelType == 'sense_voice';

  sherpa.OfflineRecognizerConfig _recognizerConfig(String? language) {
    final sherpa.OfflineModelConfig model;
    switch (_init.modelType) {
      case 'sense_voice':
        model = sherpa.OfflineModelConfig(
          senseVoice: sherpa.OfflineSenseVoiceModelConfig(
            model: _init.modelPath,
            language: language ?? '',
            useInverseTextNormalization: true,
          ),
          tokens: _init.tokensPath,
          numThreads: 2,
          debug: false,
        );
      case 'telespeech_ctc':
        model = sherpa.OfflineModelConfig(
          telespeechCtc: _init.modelPath,
          tokens: _init.tokensPath,
          modelType: 'telespeech_ctc',
          numThreads: 2,
          debug: false,
        );
      default:
        throw UnsupportedError('不支持的模型类型: ${_init.modelType}');
    }
    return sherpa.OfflineRecognizerConfig(model: model);
  }

  void acceptPcm(Uint8List bytes) {
    for (final window in _windower.add(_decoder.convert(bytes))) {
      _acceptWindow(window);
    }
  }

  void _acceptWindow(Float32List window) {
    _vad.acceptWaveform(window);

    if (!_speaking && _vad.isDetected()) {
      _speaking = true;
      _utterance
        ..clear()
        ..addAll(_preroll);
      _preroll.clear();
      _sinceLastPartial = 0;
    }
    if (_speaking) {
      _utterance.add(window);
      _sinceLastPartial += window.length;
    } else {
      _preroll.add(window);
      if (_preroll.length > _prerollWindows) _preroll.removeFirst();
    }

    if (_drainSegments()) return;

    if (_speaking && _sinceLastPartial >= _partialInterval) {
      _sinceLastPartial = 0;
      final result = _decode(concatSamples(_utterance));
      _out.send(AsrPartial(result.text));
    }
  }

  /// 取出 VAD 已切好的句子并输出定稿结果。有输出时返回 true。
  bool _drainSegments() {
    var emitted = false;
    while (!_vad.isEmpty()) {
      final segment = _vad.front();
      _vad.pop();
      _emitFinal(segment.samples);
      emitted = true;
    }
    if (emitted) {
      _speaking = false;
      _utterance.clear();
    }
    return emitted;
  }

  void _emitFinal(Float32List samples) {
    var result = _decode(samples);
    if (_hasLanguageTags) {
      final forced = fallbackLanguage(
        TagFormatter.normalize(result.lang),
        _allowed,
      );
      if (forced != null) result = _decodeWithLanguage(samples, forced);
    }
    _out.send(
      AsrFinal(
        result.text,
        lang: result.lang,
        emotion: result.emotion,
        event: result.event,
      ),
    );
  }

  /// 临时切换语言参数重解码一次（PRD 4.1 语种校验），完成后恢复。
  sherpa.OfflineRecognizerResult _decodeWithLanguage(
    Float32List samples,
    String language,
  ) {
    _recognizer.setConfig(_recognizerConfig(language));
    try {
      return _decode(samples);
    } finally {
      _recognizer.setConfig(_recognizerConfig(_currentParam));
    }
  }

  sherpa.OfflineRecognizerResult _decode(Float32List samples) {
    final stream = _recognizer.createStream();
    try {
      stream.acceptWaveform(samples: samples, sampleRate: _sampleRate);
      _recognizer.decode(stream);
      return _recognizer.getResult(stream);
    } finally {
      stream.free();
    }
  }

  void setLanguages(String? decodeParam, Set<String> allowed) {
    _allowed = allowed;
    _currentParam = decodeParam;
    _recognizer.setConfig(_recognizerConfig(decodeParam));
  }

  void flush() {
    _vad.flush();
    _drainSegments();
    _vad.reset();
    _decoder.reset();
    _windower.reset();
    _preroll.clear();
    _utterance.clear();
    _speaking = false;
  }

  void free() {
    _vad.free();
    _recognizer.free();
  }
}
