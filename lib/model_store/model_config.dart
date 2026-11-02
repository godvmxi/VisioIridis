import 'dart:convert';

/// 模型配置（PRD 4.5.2）。
class ModelConfig {
  const ModelConfig({
    required this.schemaVersion,
    required this.configVersion,
    required this.remoteConfigUrl,
    required this.languages,
    required this.vad,
    required this.asrModels,
  });

  /// 当前 App 支持的配置格式版本。
  /// 2：语言支持由 0–100 的 weight 改为 0–10 的 score 打分。
  static const supportedSchemaVersion = 2;

  final int schemaVersion;
  final int configVersion;
  final String remoteConfigUrl;
  final List<LanguageDef> languages;
  final ModelDef vad;
  final List<AsrModelDef> asrModels;

  /// 解析配置 JSON。格式版本不受支持或字段缺失时抛出 [FormatException]。
  static ModelConfig parse(String source) {
    final json = jsonDecode(source);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('配置根节点必须是对象');
    }
    final schema = json['schemaVersion'];
    if (schema != supportedSchemaVersion) {
      throw FormatException('不支持的配置格式版本: $schema');
    }
    try {
      return ModelConfig(
        schemaVersion: schema as int,
        configVersion: json['configVersion'] as int,
        remoteConfigUrl: json['remoteConfigUrl'] as String,
        languages: _list(json['languages'], LanguageDef.fromJson),
        vad: ModelDef.fromJson(json['vad'] as Map<String, dynamic>),
        asrModels: _list(json['asrModels'], AsrModelDef.fromJson),
      );
    } on TypeError catch (e) {
      throw FormatException('配置字段缺失或类型错误: $e');
    }
  }
}

class LanguageDef {
  const LanguageDef({
    required this.id,
    required this.name,
    required this.defaultEnabled,
    required this.order,
  });

  factory LanguageDef.fromJson(Map<String, dynamic> json) => LanguageDef(
        id: json['id'] as String,
        name: json['name'] as String,
        defaultEnabled: json['defaultEnabled'] as bool,
        order: json['order'] as int,
      );

  final String id;
  final String name;
  final bool defaultEnabled;
  final int order;
}

class ModelDef {
  const ModelDef({
    required this.id,
    required this.version,
    required this.files,
  });

  factory ModelDef.fromJson(Map<String, dynamic> json) => ModelDef(
        id: json['id'] as String,
        version: json['version'] as String,
        files: _list(json['files'], ModelFile.fromJson),
      );

  final String id;

  /// 存储目录名，变化即视为新模型。
  final String version;
  final List<ModelFile> files;

  /// 在外置存储与 cache 中的相对目录（PRD 4.5.5）。
  String get relativeDir => 'models/$id/$version';

  int get totalSize => files.fold(0, (sum, f) => sum + f.size);
}

class AsrModelDef extends ModelDef {
  const AsrModelDef({
    required super.id,
    required super.version,
    required super.files,
    required this.name,
    required this.type,
    required this.license,
    required this.languages,
    required this.autoDecodeParam,
  });

  factory AsrModelDef.fromJson(Map<String, dynamic> json) {
    final base = ModelDef.fromJson(json);
    return AsrModelDef(
      id: base.id,
      version: base.version,
      files: base.files,
      name: json['name'] as String,
      type: json['type'] as String,
      license: json['license'] as String,
      languages: _list(json['languages'], LanguageSupport.fromJson),
      autoDecodeParam: json['autoDecodeParam'] as String,
    );
  }

  final String name;

  /// sherpa-onnx 模型类型："sense_voice" / "telespeech_ctc"
  final String type;
  final String license;
  final List<LanguageSupport> languages;
  final String autoDecodeParam;
}

class ModelFile {
  const ModelFile({
    required this.name,
    required this.size,
    required this.sha256,
    required this.urls,
  });

  factory ModelFile.fromJson(Map<String, dynamic> json) => ModelFile(
        name: json['name'] as String,
        size: json['size'] as int,
        sha256: (json['sha256'] as String).toLowerCase(),
        urls: (json['urls'] as List).cast<String>(),
      );

  final String name;
  final int size;
  final String sha256;

  /// 按顺序尝试的下载地址。
  final List<String> urls;
}

class LanguageSupport {
  const LanguageSupport({
    required this.lang,
    required this.score,
    required this.decodeParam,
  });

  factory LanguageSupport.fromJson(Map<String, dynamic> json) =>
      LanguageSupport(
        lang: json['lang'] as String,
        score: json['score'] as int,
        decodeParam: json['decodeParam'] as String,
      );

  final String lang;

  /// 识别质量打分，0–10 分，越高越优先（PRD 4.5.2）。
  final int score;

  /// 空串表示该模型不支持指定语言。
  final String decodeParam;
}

List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) fromJson) =>
    (raw as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
