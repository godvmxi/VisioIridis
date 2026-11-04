import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model_store/model_config.dart';
import '../model_store/model_selector.dart';
import 'model_providers.dart';
import 'settings.dart';

/// 设置页“语种 → 方言 → 模型”选出的识别模型（PRD 4.5.3、4.6）；
/// 配置未加载或没有可用模型时为 null。
final currentModelProvider = Provider<AsrModelDef?>((ref) {
  final config = ref.watch(modelConfigProvider).value;
  if (config == null) return null;
  final language = ref.watch(settingsProvider.select((s) => s.asrLanguage));
  final model = ref.watch(settingsProvider.select((s) => s.asrModel));
  return resolveModel(config, language, model);
});

/// 顶部栏选择的识别语言；null 表示自动识别当前模型支持的全部语言。
/// 当前模型不支持已选语言时也视为自动。
final decodeLanguageProvider = Provider<String?>((ref) {
  final model = ref.watch(currentModelProvider);
  final language = ref.watch(settingsProvider.select((s) => s.decodeLanguage));
  return model == null ? language : effectiveLanguage(model, language);
});
