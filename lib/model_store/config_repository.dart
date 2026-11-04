import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'model_config.dart';

/// 模型配置的加载与远程更新（PRD 4.5.1）。
class ConfigRepository {
  ConfigRepository({
    required this.loadBuiltin,
    required this.storageDir,
    HttpClient? client,
    DateTime Function()? now,

    /// 覆盖配置中的 remoteConfigUrl（用于按地区选择 GitHub / Gitee）。
    this.remoteConfigUrlOverride,

    /// stamp 文件后缀，用于区分不同地区的检查时间（避免跨地区的 24h 冷却竞争）。
    String stampSuffix = '',
  }) : _client = client ?? HttpClient(),
       _now = now ?? DateTime.now,
       _stampSuffix = stampSuffix;

  static const checkInterval = Duration(hours: 24);
  static const timeout = Duration(seconds: 5);

  /// 读取内置默认配置（assets/config/model_config.json）。
  final Future<String> Function() loadBuiltin;

  /// 保存”最近可用配置”的应用私有目录。
  final Directory storageDir;
  final HttpClient _client;
  final DateTime Function() _now;
  final String? remoteConfigUrlOverride;
  final String _stampSuffix;

  File get _cachedFile =>
      File('${storageDir.path}/model_config$_stampSuffix.json');
  File get _stampFile =>
      File('${storageDir.path}/model_config.checked$_stampSuffix');

  /// 最近可用的远程配置优先，否则用内置默认配置。
  Future<ModelConfig> load() async {
    try {
      if (await _cachedFile.exists()) {
        return ModelConfig.parse(await _cachedFile.readAsString());
      }
    } on FormatException {
      // 缓存的配置格式已不受支持，退回内置配置。
    }
    return ModelConfig.parse(await loadBuiltin());
  }

  /// 检查远程配置。只有比 [current] 新且格式受支持时才保存并返回，
  /// 任何失败都静默返回 null。保存的配置在下次 [load] 时生效。
  ///
  /// stamp 只在 HTTP 请求成功后写入，失败不占用冷却时间。
  Future<ModelConfig?> refresh(ModelConfig current) async {
    try {
      if (await _stampFile.exists()) {
        final last = DateTime.parse(await _stampFile.readAsString());
        if (_now().difference(last) < checkInterval) return null;
      }
      final uri = Uri.tryParse(
        remoteConfigUrlOverride ?? current.remoteConfigUrl,
      );
      if (uri == null || uri.scheme != 'https') return null;

      final body = await _get(uri).timeout(timeout);

      // stamp 写在 HTTP 成功之后，失败不消耗冷却时间
      await storageDir.create(recursive: true);
      await _stampFile.writeAsString(_now().toIso8601String());

      final remote = acceptRemote(current, body);
      if (remote != null) await _cachedFile.writeAsString(body);
      return remote;
    } catch (_) {
      return null;
    }
  }

  /// 远程配置格式受支持且 configVersion 更大时返回解析结果，否则返回 null。
  static ModelConfig? acceptRemote(ModelConfig current, String body) {
    try {
      final remote = ModelConfig.parse(body);
      return remote.configVersion > current.configVersion ? remote : null;
    } on FormatException {
      return null;
    }
  }

  Future<String> _get(Uri uri) async {
    final request = await _client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException('HTTP ${response.statusCode}', uri: uri);
    }
    return response.transform(utf8.decoder).join();
  }
}
