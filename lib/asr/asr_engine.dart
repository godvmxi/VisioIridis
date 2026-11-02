import 'asr_language.dart';
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

/// 识别过程中的错误（如麦克风被占用），收到后识别已停止。
class AsrError extends AsrEvent {
  const AsrError(this.message);

  final String message;
}

/// 识别引擎接口。真实实现为 SherpaAsrEngine（VAD + SenseVoice），
/// MockAsrEngine 用于无模型时演示 UI。
abstract class AsrEngine {
  Stream<AsrEvent> get events;

  /// 加载模型（已加载同一模型时跳过）并开始拾音。失败时抛出异常。
  Future<void> start(PreparedModel model, Set<AsrLanguage> languages);

  Future<void> stop();

  /// 识别中切换语言勾选时调用，下一句开始生效。
  void updateLanguages(Set<AsrLanguage> languages);

  void dispose();
}
