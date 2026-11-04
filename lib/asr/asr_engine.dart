import 'prepared_model.dart';

/// 识别引擎输出的事件。
sealed class AsrEvent {
  const AsrEvent();
}

/// 说话过程中周期性重解码得到的临时结果（PRD 第 3 章）。
class AsrPartial extends AsrEvent {
  const AsrPartial(this.text);

  final String text;
}

/// VAD 判定句尾后整段解码得到的定稿结果。
/// lang / emotion / event 为 sherpa-onnx 原始标签，如 `<|zh|>`。
class AsrFinal extends AsrEvent {
  const AsrFinal(
    this.text, {
    this.lang = '',
    this.emotion = '',
    this.event = '',
  });

  final String text;
  final String lang;
  final String emotion;
  final String event;
}

/// 识别的声音来源（PRD 4.8）。
enum AudioInput { microphone, systemAudio }

/// 引擎给出的提示或错误的种类，由界面按当前界面语言转成文字。
enum AsrIssue {
  micPermissionDenied,
  recordingInterrupted,
  speakerDenied,
  speakerEnded,
  switchBackFailed,
  modelLoadFailed,
  recognitionFailed,
}

/// 声音来源被引擎自动切换（如系统声音录制被用户结束后回到麦克风）。
class AsrInputChanged extends AsrEvent {
  const AsrInputChanged(this.input, this.reason);

  final AudioInput input;
  final AsrIssue reason;
}

/// 识别过程中的错误（如麦克风被占用），收到后识别已停止。
class AsrError extends AsrEvent {
  const AsrError(this.issue, [this.detail = '']);

  final AsrIssue issue;

  /// 系统或模型给出的原始错误信息，不翻译。
  final String detail;
}

/// 开始识别或切换声音来源失败。
class AsrStartException implements Exception {
  const AsrStartException(this.issue, [this.detail = '']);

  final AsrIssue issue;
  final String detail;

  @override
  String toString() => detail.isEmpty ? issue.name : '${issue.name}: $detail';
}

/// 识别引擎接口。真实实现为 SherpaAsrEngine（VAD + SenseVoice），
/// MockAsrEngine 用于无模型时演示 UI。
abstract class AsrEngine {
  Stream<AsrEvent> get events;

  /// 加载模型（已加载同一模型时跳过）并开始拾音。失败时抛出异常。
  /// [language] 为识别语言 id，null 表示自动识别模型支持的全部语言。
  Future<void> start(PreparedModel model, String? language);

  Future<void> stop();

  /// 识别中切换识别语言时调用，下一句开始生效。
  void updateLanguage(String? language);

  /// 识别中切换声音来源；当前句按句尾处理。切换失败时回到麦克风并抛出异常。
  Future<void> setAudioInput(AudioInput input);

  /// 更新强制切断超时（秒），0 表示关闭。可在识别前或识别中调用。
  void updateForceSplitSeconds(int seconds);

  void dispose();
}
