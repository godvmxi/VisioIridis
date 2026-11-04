import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../model_store/config_repository.dart';
import 'model_providers.dart';
import 'region_detector.dart';
import 'settings.dart';

const _overseasConfigUrl =
    'https://raw.githubusercontent.com/godvmxi/VisioIridisConfig/refs/heads/master/model_config.json';
const _mainlandConfigUrl =
    'https://raw.giteeusercontent.com/godvmxi/VisioIridisConfig/raw/master/model_config_cn.json';

class ConfigUpdateInfo {
  const ConfigUpdateInfo({
    required this.newVersion,
    required this.currentVersion,
    required this.region,
  });

  final int newVersion;
  final int currentVersion;
  final RegionResult region;
}

final configUpdateProvider =
    AsyncNotifierProvider<ConfigUpdateNotifier, ConfigUpdateInfo?>(
      ConfigUpdateNotifier.new,
    );

class ConfigUpdateNotifier extends AsyncNotifier<ConfigUpdateInfo?> {
  static const _notifiedKey = 'config.notifiedVersion';

  @override
  Future<ConfigUpdateInfo?> build() async {
    final currentConfig = await ref.watch(modelConfigProvider.future);
    final region = await ref.watch(regionProvider.future);

    // 地区未知时跳过，等探测完成后重新触发
    if (region == RegionResult.unknown) return null;

    final prefs = ref.read(sharedPreferencesProvider);
    final notifiedVersion = prefs.getInt(_notifiedKey) ?? 0;

    final urlOverride = region == RegionResult.mainland
        ? _mainlandConfigUrl
        : _overseasConfigUrl;
    final stampSuffix = region == RegionResult.mainland ? '_cn' : '_global';

    final repo = ConfigRepository(
      loadBuiltin: () => rootBundle.loadString(
        region == RegionResult.mainland
            ? 'assets/config/model_config_cn.json'
            : 'assets/config/model_config.json',
      ),
      storageDir: await getApplicationSupportDirectory(),
      remoteConfigUrlOverride: urlOverride,
      stampSuffix: stampSuffix,
    );

    final newConfig = await repo.refresh(currentConfig);
    if (newConfig == null) return null;
    if (newConfig.configVersion <= notifiedVersion) return null;

    return ConfigUpdateInfo(
      newVersion: newConfig.configVersion,
      currentVersion: currentConfig.configVersion,
      region: region,
    );
  }

  /// 记录弹窗已展示，防止重复弹出。
  void markShown() {
    final update = state.asData?.value;
    if (update == null) return;
    ref.read(sharedPreferencesProvider).setInt(_notifiedKey, update.newVersion);
    state = const AsyncData(null);
  }

  /// 标记已展示，并重新加载模型配置（使新配置立即生效）。
  void acceptAndReload() {
    markShown();
    ref.invalidate(modelConfigProvider);
  }
}
