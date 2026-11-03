import '../model_store/model_config.dart';

/// 已就绪、可直接加载的模型文件路径。
class PreparedModel {
  const PreparedModel({
    required this.vadModelPath,
    required this.asrModel,
    required this.asrModelDir,
  });

  final String vadModelPath;
  final AsrModelDef asrModel;
  final String asrModelDir;

  /// 约定：单文件模型的目录中唯一的 .onnx 文件为模型，tokens.txt 为词表；
  /// 编码器-解码器模型（如 Whisper）的文件名分别含 encoder 与 decoder。
  String get modelPath => _path((f) => f.endsWith('.onnx'));

  String get encoderPath => _path((f) => f.contains('encoder'));

  String get decoderPath => _path((f) => f.contains('decoder'));

  String get tokensPath => '$asrModelDir/tokens.txt';

  /// 没有匹配的文件时返回空串，由用不到该文件的模型类型忽略。
  String _path(bool Function(String name) test) {
    final file = asrModel.files.where((f) => test(f.name)).firstOrNull;
    return file == null ? '' : '$asrModelDir/${file.name}';
  }
}
