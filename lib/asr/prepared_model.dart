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

  /// 约定：模型目录中唯一的 .onnx 文件为模型，tokens.txt 为词表。
  String get modelPath =>
      '$asrModelDir/${asrModel.files.firstWhere((f) => f.name.endsWith('.onnx')).name}';

  String get tokensPath => '$asrModelDir/tokens.txt';
}
