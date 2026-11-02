import '../asr/tag_formatter.dart';

/// 一条已定稿的字幕（PRD 6.2）。
class SubtitleItem {
  const SubtitleItem({
    required this.id,
    required this.timestamp,
    required this.text,
    this.lang,
    this.emotionTag,
    this.eventTag,
  });

  final String id;
  final DateTime timestamp;
  final String text;

  /// SenseVoice 检测语种："zh" / "yue" / "en"
  final String? lang;

  /// 情绪："HAPPY" / "SAD" 等
  final String? emotionTag;

  /// 音频事件："Laughter" / "Applause" / "Cry" 等
  final String? eventTag;

  String get formattedTime =>
      "[${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}]";

  /// 上屏文本：事件标签（如 😄 [笑声]）置于句首。
  String get displayText {
    final label = TagFormatter.eventLabel(eventTag);
    if (label == null) return text;
    return text.isEmpty ? label : '$label $text';
  }
}
