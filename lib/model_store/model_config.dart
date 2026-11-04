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
    this.languageGroups = const [],
  });

  /// 当前 App 支持的配置格式版本。
  /// 2：语言支持由 0–100 的 weight 改为 0–10 的 score 打分。
  static const supportedSchemaVersion = 2;

  final int schemaVersion;
  final int configVersion;
  final String remoteConfigUrl;
  final List<LanguageDef> languages;

  /// 语种（如“中文”），其下的方言见 [LanguageDef.group]。旧配置没有此字段。
  final List<LanguageGroup> languageGroups;
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
        languageGroups: json['languageGroups'] == null
            ? const []
            : _list(json['languageGroups'], LanguageGroup.fromJson),
      );
    } on TypeError catch (e) {
      throw FormatException('配置字段缺失或类型错误: $e');
    }
  }

  /// 按顺序排列的语种。旧配置没有语种时，每种语言自成一个语种（id 与语言相同）。
  List<LanguageGroup> get groups {
    final declared = {for (final g in languageGroups) g.id: g};
    final result = <String, LanguageGroup>{};
    for (final l in sortedLanguages) {
      final id = l.group ?? l.id;
      result[id] ??=
          declared[id] ?? LanguageGroup(id: id, name: l.name, order: l.order);
    }
    return result.values.toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  /// 语种 [groupId] 下的语言（方言），按顺序排列。
  List<LanguageDef> languagesIn(String groupId) => [
    for (final l in sortedLanguages)
      if ((l.group ?? l.id) == groupId) l,
  ];

  List<LanguageDef> get sortedLanguages =>
      [...languages]..sort((a, b) => a.order.compareTo(b.order));

  LanguageDef? languageById(String id) =>
      languages.where((l) => l.id == id).firstOrNull;
}

/// 语种，如“中文”，其下包含普通话、粤语等方言。
class LanguageGroup {
  const LanguageGroup({
    required this.id,
    required this.name,
    required this.order,
  });

  factory LanguageGroup.fromJson(Map<String, dynamic> json) => LanguageGroup(
    id: json['id'] as String,
    name: json['name'] as String,
    order: json['order'] as int,
  );

  final String id;
  final String name;
  final int order;
}

class LanguageDef {
  const LanguageDef({
    required this.id,
    required this.name,
    required this.defaultEnabled,
    required this.order,
    this.group,
  });

  factory LanguageDef.fromJson(Map<String, dynamic> json) => LanguageDef(
    id: json['id'] as String,
    name: json['name'] as String,
    defaultEnabled: json['defaultEnabled'] as bool,
    order: json['order'] as int,
    group: json['group'] as String?,
  );

  final String id;
  final String name;
  final bool defaultEnabled;
  final int order;

  /// 所属语种 id；为 null 时自成一个语种。
  final String? group;
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
