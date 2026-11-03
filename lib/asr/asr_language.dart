/// 可选识别语言，code 为模型配置中的语言 id（普通话、粤语、英语等与 SenseVoice 的
/// language 参数值相同）。
enum AsrLanguage {
  mandarin('zh'),
  cantonese('yue'),
  english('en'),
  french('fr'),
  german('de'),
  henan('henan'),
  sichuan('sichuan'),
  dongbei('dongbei'),
  shandong('shandong'),
  shanghai('shanghai'),
  minnan('minnan');

  const AsrLanguage(this.code);

  final String code;

  /// PRD 4.1：仅勾选一种时强制该语言，勾选两种或三种时用 auto。
  static String languageParamFor(Set<AsrLanguage> enabled) =>
      enabled.length == 1 ? enabled.first.code : 'auto';
}
