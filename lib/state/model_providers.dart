import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../model_store/bundled_model_store.dart';
import '../model_store/config_repository.dart';
import '../model_store/downloader.dart';
import '../model_store/model_config.dart';
import '../model_store/model_repository.dart';
import 'region_detector.dart';

/// 当前生效的模型配置。远程检查由 configUpdateProvider 负责（PRD 4.5.1、4.5.6）。
final modelConfigProvider = FutureProvider<ModelConfig>((ref) async {
  // 读缓存区域（首次探测前为 unknown，视作国际版）
  final region = switch (ref.watch(regionProvider)) {
    AsyncData(:final value) => value,
    _ => RegionResult.unknown,
  };
  final isCN = region == RegionResult.mainland;

  final repo = ConfigRepository(
    loadBuiltin: () => rootBundle.loadString(
      isCN
          ? 'assets/config/model_config_cn.json'
          : 'assets/config/model_config.json',
    ),
    storageDir: await getApplicationSupportDirectory(),
    stampSuffix: isCN ? '_cn' : '_global',
  );
  return repo.load();
});

/// 随 APK 内置的模型；在 main() 中用读取到的 manifest 覆盖，默认没有内置模型。
final bundledModelsProvider = Provider<BundledModels>(
  (ref) => BundledModels.empty,
);

final modelCacheProvider = FutureProvider<ModelCache>(
  (ref) async => ModelCache(await getApplicationCacheDirectory()),
);

final downloaderProvider = Provider<Downloader>((ref) => HttpDownloader());

/// 正在准备的模型及进度；为 null 表示当前没有准备任务。
class PrepState {
  const PrepState({required this.modelName, this.progress});

  final String modelName;
  final PrepProgress? progress;
}

final modelPrepProvider = NotifierProvider<ModelPrepController, PrepState?>(
  ModelPrepController.new,
);

class ModelPrepController extends Notifier<PrepState?> {
  bool _cancelled = false;

  @override
  PrepState? build() => null;

  Future<void> run(
    String modelName,
    Future<void> Function(
      void Function(PrepProgress) onProgress,
      CancelCheck isCancelled,
    )
    task,
  ) async {
    _cancelled = false;
    state = PrepState(modelName: modelName);
    PrepProgress? last;
    try {
      await task((progress) {
        // 下载时每个数据块都会回调，只在阶段变化或进度推进 0.5% 时刷新界面。
        final step = progress.total ~/ 200;
        if (last != null &&
            last!.phase == progress.phase &&
            last!.fileName == progress.fileName &&
            progress.done - last!.done < step &&
            progress.done != progress.total) {
          return;
        }
        last = progress;
        if (ref.mounted) {
          state = PrepState(modelName: modelName, progress: progress);
        }
      }, () => _cancelled);
    } finally {
      if (ref.mounted) state = null;
    }
  }

  void cancel() => _cancelled = true;
}
