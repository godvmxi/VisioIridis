/// SenseVoice 标签处理（PRD 4.3）。
///
/// sherpa-onnx 的结果中 lang / emotion / event 形如 `<|zh|>`、`<|HAPPY|>`、
/// `<|Laughter|>`，且大小写不统一。
class TagFormatter {
  TagFormatter._();

  static final _tagPattern = RegExp(r'<\|[^|>]*\|>');

  static const _eventLabels = {
    'laughter': '😄 [笑声]',
    'applause': '👏 [掌声]',
    'cry': '😢 [哭泣声]',
  };

  /// `<|Laughter|>` -> `Laughter`；空串或纯空白返回 null。
  static String? normalize(String raw) {
    final value = raw.replaceAll('<|', '').replaceAll('|>', '').trim();
    return value.isEmpty ? null : value;
  }

  /// 需要上屏的事件返回显示文本，其余（Speech、BGM 等）返回 null。
  static String? eventLabel(String? event) =>
      event == null ? null : _eventLabels[event.toLowerCase()];

  /// 剔除文本中残留的所有 `<|...|>` 标签。
  static String cleanText(String text) =>
      text.replaceAll(_tagPattern, '').trim();
}
