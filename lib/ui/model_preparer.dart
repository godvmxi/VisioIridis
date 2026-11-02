import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../asr/prepared_model.dart';
import '../l10n/l10n.dart';
import '../model_store/downloader.dart';
import '../model_store/model_config.dart';
import '../model_store/model_repository.dart';
import '../model_store/model_selector.dart';
import '../model_store/model_store.dart';
import '../state/asr_controller.dart';
import '../state/model_providers.dart';
import '../state/settings.dart';

final modelPreparerProvider = Provider<ModelPreparer>(ModelPreparer.new);

/// 模型长期保存在应用专属外置目录；盒子出厂时也可通过 adb 预置到这里。
final modelStoresProvider = FutureProvider<List<ModelStore>>((ref) async {
  final appDir = await getExternalStorageDirectory();
  return [if (appDir != null) DirectoryModelStore(appDir)];
});

/// 点击“开始识别”前确保所需模型已就绪（PRD 4.5.3、4.5.5）。
class ModelPreparer {
  ModelPreparer(this._ref);

  final Ref _ref;

  /// 上次成功启动识别时使用的模型 id，用于检测模型是否发生变化。
  static const lastModelKey = 'model.lastUsed';

  /// 返回就绪模型的路径；用户取消或失败返回 null（失败时已提示）。
  ///
  /// 启动前比较本次选出的模型与上次使用的模型：模型变化且需要下载时弹窗说明，
  /// 上次的模型仍可用时允许先继续使用它；无需下载时只提示已切换。
  Future<PreparedModel?> ensureReady(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      final config = await _ref.read(modelConfigProvider.future);
      final languages = _ref
          .read(asrControllerProvider)
          .enabledLanguages
          .map((l) => l.code)
          .toSet();
      final model = selectModel(
        config,
        languages,
        preferred: _ref.read(settingsProvider).modelPreferences,
      );
      if (model == null) {
        if (context.mounted) _toast(context, l10n.noModelForLanguages);
        return null;
      }

      final prefs = _ref.read(sharedPreferencesProvider);
      final lastId = prefs.getString(lastModelKey);
      final previous = lastId == model.id
          ? null
          : config.asrModels.where((m) => m.id == lastId).firstOrNull;

      final cache = await _ref.read(modelCacheProvider.future);
      PreparedModel preparedFor(AsrModelDef m) => PreparedModel(
        vadModelPath: cache.fileFor(config.vad, config.vad.files.first).path,
        asrModel: m,
        asrModelDir: cache.dirFor(m).path,
      );
      Future<PreparedModel> use(AsrModelDef m) async {
        await prefs.setString(lastModelKey, m.id);
        return preparedFor(m);
      }

      final required = <ModelDef>[config.vad, model];
      if (await _allReady(cache, required)) {
        if (previous != null && context.mounted) {
          _toast(context, l10n.modelSwitched(model.name));
        }
        return await use(model);
      }

      final repo = ModelRepository(
        cache: cache,
        stores: await _ref.read(modelStoresProvider.future),
        downloader: _ref.read(downloaderProvider),
      );
      var downloadBytes = 0;
      for (final m in required) {
        downloadBytes += (await repo.plan(m)).downloadBytes;
      }
      if (downloadBytes > 0) {
        // 上次的模型支持当前语言且已就绪时，可以先继续用它。
        final fallback =
            previous != null &&
                languages.every(
                  (l) => previous.languages.any((s) => s.lang == l),
                ) &&
                await _allReady(cache, [config.vad, previous])
            ? previous
            : null;
        if (!context.mounted) return null;
        final choice = await _confirmDownload(
          context,
          model: model,
          previous: previous,
          fallback: fallback,
          bytes: downloadBytes,
        );
        switch (choice) {
          case _DownloadChoice.cancel:
            return null;
          case _DownloadChoice.useFallback:
            return await use(fallback!);
          case _DownloadChoice.download:
            break;
        }
      } else if (previous != null && context.mounted) {
        _toast(context, l10n.modelSwitched(model.name));
      }

      await _ref.read(modelPrepProvider.notifier).run(model.name, (
        onProgress,
        isCancelled,
      ) async {
        for (final m in required) {
          await repo.ensure(
            m,
            onProgress: onProgress,
            isCancelled: isCancelled,
          );
        }
      });
      return await use(model);
    } on DownloadCancelled {
      return null;
    } catch (e) {
      if (context.mounted) _toast(context, l10n.modelPrepFailed('$e'));
      return null;
    }
  }

  static Future<bool> _allReady(ModelCache cache, List<ModelDef> models) async {
    for (final m in models) {
      if (!await cache.isReady(m)) return false;
    }
    return true;
  }

  static Future<_DownloadChoice> _confirmDownload(
    BuildContext context, {
    required AsrModelDef model,
    required AsrModelDef? previous,
    required AsrModelDef? fallback,
    required int bytes,
  }) async {
    final l10n = AppLocalizations.of(context);
    final size = formatMegabytes(bytes);
    final message = [
      if (previous != null) l10n.modelChangedFrom(previous.name, model.name),
      previous == null
          ? l10n.downloadNeededWithVad(model.name, size)
          : l10n.downloadNeeded(model.name, size),
      l10n.wifiSuggestion,
    ].join('\n');
    final choice = await showDialog<_DownloadChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          previous == null ? l10n.downloadModelTitle : l10n.modelChangedTitle,
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 17, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _DownloadChoice.cancel),
            child: Text(l10n.cancel),
          ),
          if (fallback != null)
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, _DownloadChoice.useFallback),
              child: Text(l10n.useModelFirst(fallback.name)),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _DownloadChoice.download),
            child: Text(l10n.download),
          ),
        ],
      ),
    );
    return choice ?? _DownloadChoice.cancel;
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _DownloadChoice { cancel, useFallback, download }

String formatMegabytes(int bytes) =>
    '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
