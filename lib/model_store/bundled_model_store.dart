import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'model_store.dart';

/// 随 APK 内置的模型文件。
///
/// 内置版 APK 由 CI 在构建前运行 `tool/bundle_model.py` 生成
/// `assets/bundled_models/` 下的模型文件与 manifest.json；普通版的 manifest 为空。
class BundledModels {
  const BundledModels({this.modelIds = const {}, this.files = const {}});

  static const empty = BundledModels();
  static const manifestAsset = 'assets/bundled_models/manifest.json';

  /// 内置的 ASR 模型 id，选择默认模型时优先使用。
  final Set<String> modelIds;

  /// relPath（`models/<id>/<version>/<文件名>`）→ (asset 路径, 字节数)。
  final Map<String, ({String asset, int size})> files;

  bool get isEmpty => files.isEmpty;

  factory BundledModels.fromJson(Map<String, dynamic> json) {
    final files = <String, ({String asset, int size})>{};
    final rawFiles = json['files'] as Map<String, dynamic>? ?? const {};
    for (final MapEntry(:key, :value) in rawFiles.entries) {
      final entry = value as Map<String, dynamic>;
      files[key] = (
        asset: entry['asset'] as String,
        size: (entry['size'] as num).toInt(),
      );
    }
    return BundledModels(
      modelIds: {
        for (final id in json['models'] as List? ?? const []) id as String,
      },
      files: files,
    );
  }

  /// 读取内置 manifest；不存在或格式错误时视为没有内置模型。
  static Future<BundledModels> load([AssetBundle? bundle]) async {
    try {
      final text = await (bundle ?? rootBundle).loadString(manifestAsset);
      return BundledModels.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      return empty;
    }
  }
}

/// 从 APK assets 中读取内置模型。
///
/// 模型文件有数百 MB，不能用 rootBundle.load 一次读入内存，
/// 由原生端（MainActivity）以流的方式直接复制到目标文件。
class BundledModelStore implements ModelStore {
  BundledModelStore(this.models);

  static const _channel = MethodChannel('visio_iridis/bundled_models');

  final BundledModels models;

  @override
  String get label => '内置模型';

  @override
  Future<int?> sizeOf(String relPath) async => models.files[relPath]?.size;

  @override
  Future<void> copyToLocal(String relPath, File dest) async {
    final entry = models.files[relPath];
    if (entry == null) throw FileSystemException('未内置该文件', relPath);
    await _channel.invokeMethod<void>('copyAsset', {
      'asset': entry.asset,
      'dest': dest.path,
    });
  }

  /// 内置模型只读；下载的文件保存到其他存储。
  @override
  Future<void> copyFromLocal(File src, String relPath) async =>
      throw UnsupportedError('内置模型只读');
}
