import 'asr_language.dart';

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

/// 识别引擎接口。真实实现为 sherpa-onnx（VAD + SenseVoice），
/// 在接入模型前用 MockAsrEngine 驱动 UI。
abstract class AsrEngine {
  Stream<AsrEvent> get events;

  Future<void> start(Set<AsrLanguage> languages);

  Future<void> stop();

  /// 识别中切换语言勾选时调用，下一句开始生效。
  void updateLanguages(Set<AsrLanguage> languages);

  void dispose();
}
