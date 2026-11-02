/// 可选识别语言，code 为 SenseVoice 的 language 参数值。
enum AsrLanguage {
  mandarin('zh', '普通话'),
  cantonese('yue', '粤语'),
  english('en', '英语');

  const AsrLanguage(this.code, this.label);

  final String code;
  final String label;

  /// PRD 4.1：仅勾选一种时强制该语言，勾选两种或三种时用 auto。
  static String languageParamFor(Set<AsrLanguage> enabled) =>
      enabled.length == 1 ? enabled.first.code : 'auto';
}
