import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../model_store/config_repository.dart';
import '../model_store/downloader.dart';
import '../model_store/model_config.dart';
import '../model_store/model_repository.dart';

/// 当前生效的模型配置。远程更新在后台检查，下次启动生效（PRD 4.5.1）。
final modelConfigProvider = FutureProvider<ModelConfig>((ref) async {
  final repo = ConfigRepository(
    loadBuiltin: () => rootBundle.loadString('assets/config/model_config.json'),
    storageDir: await getApplicationSupportDirectory(),
  );
  final config = await repo.load();
  unawaited(repo.refresh(config));
  return config;
});

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

final modelPrepProvider =
    NotifierProvider<ModelPrepController, PrepState?>(ModelPrepController.new);

class ModelPrepController extends Notifier<PrepState?> {
  bool _cancelled = false;

  @override
  PrepState? build() => null;

  Future<void> run(
    String modelName,
    Future<void> Function(
      void Function(PrepProgress) onProgress,
      CancelCheck isCancelled,
    ) task,
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
