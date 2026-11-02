import 'model_config.dart';

/// PRD 4.5.3：在支持全部已勾选语言的模型中选择。
///
/// [preferred] 为设置页中“语言 → 指定模型”的选择（PRD 4.6）。被越多已勾选语言
/// 指定的模型越优先；指定次数相同时选打分之和最高的，再相同时选文件总大小更小的。
/// 指定的模型不支持全部已勾选语言时不会被选中。没有任何模型支持时返回 null。
AsrModelDef? selectModel(
  ModelConfig config,
  Set<String> languages, {
  Map<String, String> preferred = const {},
}) {
  AsrModelDef? best;
  (int, int)? bestScore;
  for (final model in config.asrModels) {
    final scores = {for (final s in model.languages) s.lang: s.score};
    if (!languages.every(scores.containsKey)) continue;
    final votes = languages.where((l) => preferred[l] == model.id).length;
    final total = languages.fold(0, (sum, lang) => sum + scores[lang]!);
    final score = (votes, total);
    if (bestScore == null ||
        _compare(score, bestScore) > 0 ||
        (_compare(score, bestScore) == 0 &&
            model.totalSize < best!.totalSize)) {
      best = model;
      bestScore = score;
    }
  }
  return best;
}

int _compare((int, int) a, (int, int) b) =>
    a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2);

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
