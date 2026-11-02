import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../asr/prepared_model.dart';
import '../model_store/downloader.dart';
import '../model_store/model_config.dart';
import '../model_store/model_repository.dart';
import '../model_store/model_selector.dart';
import '../model_store/model_store.dart';
import '../state/asr_controller.dart';
import '../state/model_providers.dart';
import '../state/settings.dart';

final modelPreparerProvider = Provider<ModelPreparer>(ModelPreparer.new);

/// 点击“开始识别”前确保所需模型已就绪（PRD 4.5.3、4.5.5）。
class ModelPreparer {
  ModelPreparer(this._ref);

  final Ref _ref;

  /// 返回就绪模型的路径；用户取消或失败返回 null（失败时已提示）。
  Future<PreparedModel?> ensureReady(BuildContext context) async {
    try {
      final config = await _ref.read(modelConfigProvider.future);
      final languages = _ref
          .read(asrControllerProvider)
          .enabledLanguages
          .map((l) => l.code)
          .toSet();
      final model = selectModel(config, languages,
          preferred: _ref.read(settingsProvider).modelPreferences);
      if (model == null) {
        if (context.mounted) _toast(context, '当前语言组合没有可用的识别模型');
        return null;
      }

      final cache = await _ref.read(modelCacheProvider.future);
      final required = <ModelDef>[config.vad, model];
      final prepared = PreparedModel(
        vadModelPath: cache.fileFor(config.vad, config.vad.files.first).path,
        asrModel: model,
        asrModelDir: cache.dirFor(model).path,
      );
      if (await _allReady(cache, required)) return prepared;

      final repo = ModelRepository(
        cache: cache,
        stores: await _stores(),
        downloader: _ref.read(downloaderProvider),
      );
      var downloadBytes = 0;
      for (final m in required) {
        downloadBytes += (await repo.plan(m)).downloadBytes;
      }
      if (downloadBytes > 0) {
        if (!context.mounted) return null;
        if (!await _confirmDownload(context, model.name, downloadBytes)) {
          return null;
        }
      }

      await _ref.read(modelPrepProvider.notifier).run(
        model.name,
        (onProgress, isCancelled) async {
          for (final m in required) {
            await repo.ensure(m,
                onProgress: onProgress, isCancelled: isCancelled);
          }
        },
      );
      return prepared;
    } on DownloadCancelled {
      return null;
    } catch (e) {
      if (context.mounted) _toast(context, '模型准备失败：$e');
      return null;
    }
  }

  static Future<bool> _allReady(ModelCache cache, List<ModelDef> models) async {
    for (final m in models) {
      if (!await cache.isReady(m)) return false;
    }
    return true;
  }

  /// 模型长期保存在应用专属外置目录；盒子出厂时也可通过 adb 预置到这里。
  static Future<List<ModelStore>> _stores() async {
    final appDir = await getExternalStorageDirectory();
    return [if (appDir != null) DirectoryModelStore(appDir)];
  }

  static Future<bool> _confirmDownload(
      BuildContext context, String modelName, int bytes) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('下载识别模型'),
        content: Text(
          '需要下载「$modelName」及语音检测模型，共 ${formatMegabytes(bytes)}。\n'
          '建议连接 Wi-Fi 后再下载。',
          style: const TextStyle(fontSize: 17, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('下载'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

String formatMegabytes(int bytes) =>
    '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
