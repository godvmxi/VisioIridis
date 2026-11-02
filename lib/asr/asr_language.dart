/// 可选识别语言，code 为 SenseVoice 的 language 参数值。
enum AsrLanguage {
  mandarin('zh'),
  cantonese('yue'),
  english('en');

  const AsrLanguage(this.code);

  final String code;

  /// PRD 4.1：仅勾选一种时强制该语言，勾选两种或三种时用 auto。
  static String languageParamFor(Set<AsrLanguage> enabled) =>
      enabled.length == 1 ? enabled.first.code : 'auto';
}
