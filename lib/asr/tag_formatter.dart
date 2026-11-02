/// SenseVoice 标签处理（PRD 4.3）。
///
/// sherpa-onnx 的结果中 lang / emotion / event 形如 `<|zh|>`、`<|HAPPY|>`、
/// `<|Laughter|>`，且大小写不统一。
class TagFormatter {
  TagFormatter._();

  static final _tagPattern = RegExp(r'<\|[^|>]*\|>');

  static const _eventEmoji = {'laughter': '😄', 'applause': '👏', 'cry': '😢'};

  /// `<|Laughter|>` -> `Laughter`；空串或纯空白返回 null。
  static String? normalize(String raw) {
    final value = raw.replaceAll('<|', '').replaceAll('|>', '').trim();
    return value.isEmpty ? null : value;
  }

  /// 需要上屏的事件返回“表情 [名称]”，其余（Speech、BGM 等）返回 null。
  /// [name] 给出当前界面语言下的事件名称。
  static String? eventLabel(String? event, String? Function(String) name) {
    if (event == null) return null;
    final emoji = _eventEmoji[event.toLowerCase()];
    final text = name(event);
    if (emoji == null || text == null) return null;
    return '$emoji [$text]';
  }

  /// 剔除文本中残留的所有 `<|...|>` 标签。
  static String cleanText(String text) =>
      text.replaceAll(_tagPattern, '').trim();
}
