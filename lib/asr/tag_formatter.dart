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

  /// 只有空白与标点（如“。”“.”“，”）的文本。
  static final _punctuationOnly = RegExp(r'^[\p{P}\s]*$', unicode: true);

  /// 剔除文本中残留的所有 `<|...|>` 标签；只剩空白或标点时返回空串，不上屏。
  static String cleanText(String text) {
    final cleaned = text.replaceAll(_tagPattern, '').trim();
    return _punctuationOnly.hasMatch(cleaned) ? '' : cleaned;
  }
}
