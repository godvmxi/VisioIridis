import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model_store/model_config.dart';
import '../model_store/model_selector.dart';
import 'asr_controller.dart';
import 'model_providers.dart';
import 'settings.dart';

/// 按当前勾选的语言与设置页的模型偏好选出的识别模型（PRD 4.5.3、4.6）；
/// 配置未加载或没有可用模型时为 null。
final currentModelProvider = Provider<AsrModelDef?>((ref) {
  final config = ref.watch(modelConfigProvider).value;
  if (config == null) return null;
  final languages = ref
      .watch(asrControllerProvider.select((s) => s.enabledLanguages))
      .map((l) => l.code)
      .toSet();
  final preferred = ref.watch(
    settingsProvider.select((s) => s.modelPreferences),
  );
  return selectModel(config, languages, preferred: preferred);
});
