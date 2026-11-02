import 'dart:io';

import 'downloader.dart';
import 'model_config.dart';
import 'model_store.dart';

/// cache 目录中的模型（推理时实际加载的位置）。
class ModelCache {
  ModelCache(this.root);

  final Directory root;

  Directory dirFor(ModelDef model) =>
      Directory('${root.path}/${model.relativeDir}');

  File fileFor(ModelDef model, ModelFile file) =>
      File('${dirFor(model).path}/${file.name}');

  /// 只比较大小，不算 sha256，避免每次启动耗时数秒（PRD 4.5.5 第 1 步）。
  Future<bool> isFileReady(ModelDef model, ModelFile file) async {
    final f = fileFor(model, file);
    return await f.exists() && await f.length() == file.size;
  }

  Future<bool> isReady(ModelDef model) async {
    for (final file in model.files) {
      if (!await isFileReady(model, file)) return false;
    }
    return true;
  }
}

enum PrepPhase { copying, downloading, verifying, saving }

class PrepProgress {
  const PrepProgress({
    required this.phase,
    required this.fileName,
    this.done = 0,
    this.total = 0,
  });

  final PrepPhase phase;
  final String fileName;

  /// 已处理字节数；[total] 为 0 表示进度未知。
  final int done;
  final int total;
}

/// 获取模型前的检查结果，用于下载前向用户确认大小。
class ModelPlan {
  const ModelPlan({required this.fromStore, required this.toDownload});

  final List<ModelFile> fromStore;
  final List<ModelFile> toDownload;

  int get downloadBytes => toDownload.fold(0, (sum, f) => sum + f.size);
}

class ModelIntegrityException implements Exception {
  const ModelIntegrityException(this.fileName);

  final String fileName;

  @override
  String toString() => '$fileName 校验失败';
}

/// 按 PRD 4.5.5 获取模型：cache → 外置存储 → 下载。
class ModelRepository {
  ModelRepository({
    required this.cache,
    required this.stores,
    required this.downloader,
    Future<String> Function(String path)? hash,
  }) : _hash = hash ?? sha256OfFile;

  final ModelCache cache;

  /// 按顺序查找；下载的文件保存到第一个。
  final List<ModelStore> stores;
  final Downloader downloader;
  final Future<String> Function(String path) _hash;

  String _relPath(ModelDef model, ModelFile file) =>
      '${model.relativeDir}/${file.name}';

  Future<ModelPlan> plan(ModelDef model) async {
    final fromStore = <ModelFile>[];
    final toDownload = <ModelFile>[];
    for (final file in model.files) {
      if (await cache.isFileReady(model, file)) continue;
      if (await _findStore(model, file) != null) {
        fromStore.add(file);
      } else {
        toDownload.add(file);
      }
    }
    return ModelPlan(fromStore: fromStore, toDownload: toDownload);
  }

  /// 确保模型的所有文件都在 cache 中且校验通过，返回模型目录。
  Future<Directory> ensure(
    ModelDef model, {
    void Function(PrepProgress)? onProgress,
    CancelCheck? isCancelled,
  }) async {
    for (final file in model.files) {
      if (isCancelled?.call() ?? false) throw const DownloadCancelled();
      if (await cache.isFileReady(model, file)) continue;

      final target = cache.fileFor(model, file);
      await target.parent.create(recursive: true);
      final part = File('${target.path}.part');

      if (await _restoreFromStore(model, file, part, onProgress)) {
        await part.rename(target.path);
        continue;
      }

      await downloader.fetch(
        file.urls,
        part,
        file.size,
        isCancelled: isCancelled,
        onProgress: (done, total) => onProgress?.call(PrepProgress(
          phase: PrepPhase.downloading,
          fileName: file.name,
          done: done,
          total: total,
        )),
      );
      onProgress?.call(
          PrepProgress(phase: PrepPhase.verifying, fileName: file.name));
      if (await _hash(part.path) != file.sha256) {
        await part.delete();
        throw ModelIntegrityException(file.name);
      }
      if (stores.isNotEmpty) {
        onProgress?.call(
            PrepProgress(phase: PrepPhase.saving, fileName: file.name));
        await stores.first.copyFromLocal(part, _relPath(model, file));
      }
      await part.rename(target.path);
    }
    return cache.dirFor(model);
  }

  Future<ModelStore?> _findStore(ModelDef model, ModelFile file) async {
    final rel = _relPath(model, file);
    for (final store in stores) {
      if (await store.sizeOf(rel) == file.size) return store;
    }
    return null;
  }

  /// 外置存储中有大小一致的文件时复制到 [part] 并校验 sha256。
  /// 文件可能被用户或其他 App 改动，校验不通过则返回 false，改为重新下载。
  Future<bool> _restoreFromStore(
    ModelDef model,
    ModelFile file,
    File part,
    void Function(PrepProgress)? onProgress,
  ) async {
    final store = await _findStore(model, file);
    if (store == null) return false;
    onProgress?.call(PrepProgress(phase: PrepPhase.copying, fileName: file.name));
    await store.copyToLocal(_relPath(model, file), part);
    onProgress?.call(
        PrepProgress(phase: PrepPhase.verifying, fileName: file.name));
    if (await _hash(part.path) == file.sha256) return true;
    await part.delete();
    return false;
  }
}
