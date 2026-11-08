import 'model_config.dart';

/// 支持语言 [language] 的模型，按该语言打分从高到低排列；打分相同时文件总大小更小的在前。
List<AsrModelDef> modelsFor(ModelConfig config, String language) {
  int score(AsrModelDef m) =>
      m.languages.firstWhere((s) => s.lang == language).score;
  return [
    for (final m in config.asrModels)
      if (m.languages.any((s) => s.lang == language)) m,
  ]..sort((a, b) {
    final byScore = score(b).compareTo(score(a));
    return byScore != 0 ? byScore : a.totalSize.compareTo(b.totalSize);
  });
}

/// 设置页选择的模型（PRD 4.5.3、4.6）：语种 → 方言 [language] → 模型 [modelId]。
///
/// [modelId] 为 null 或在配置中已不存在时，取支持 [language] 且打分最高的模型，
/// 其中 [preferred]（如随 APK 内置的模型）支持该语言时优先；
/// 该语言没有可用模型时退回第一个模型，配置中没有模型时返回 null。
AsrModelDef? resolveModel(
  ModelConfig config,
  String language,
  String? modelId, {
  Set<String> preferred = const {},
}) {
  final chosen = config.asrModels.where((m) => m.id == modelId).firstOrNull;
  if (chosen != null) return chosen;
  final candidates = modelsFor(config, language);
  return candidates.where((m) => preferred.contains(m.id)).firstOrNull ??
      candidates.firstOrNull ??
      config.asrModels.firstOrNull;
}

/// 识别时实际使用的语言：[language] 为 null 或模型不支持时为自动（null）。
String? effectiveLanguage(AsrModelDef model, String? language) =>
    model.languages.any((s) => s.lang == language) ? language : null;

/// 识别时允许的语言：自动时为模型支持的全部语言，否则只有 [language]。
Set<String> allowedLanguages(AsrModelDef model, String? language) {
  final effective = effectiveLanguage(model, language);
  return effective == null
      ? {for (final s in model.languages) s.lang}
      : {effective};
}

/// 传给模型的语言参数：单语言用其 decodeParam，多语言用 autoDecodeParam；
/// 空串或模型不支持该语言时不传参，返回 null。
String? decodeParamFor(AsrModelDef model, Set<String> languages) {
  final String param;
  if (languages.length == 1) {
    final support = model.languages
        .where((s) => s.lang == languages.first)
        .firstOrNull;
    param = support?.decodeParam ?? '';
  } else {
    param = model.autoDecodeParam;
  }
  return param.isEmpty ? null : param;
}
