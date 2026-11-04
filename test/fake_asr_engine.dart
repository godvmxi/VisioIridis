import 'dart:async';

import 'package:seevoice/asr/asr_engine.dart';
import 'package:seevoice/asr/prepared_model.dart';
import 'package:seevoice/model_store/model_config.dart';

/// 测试用的模型路径，文件并不存在。
const testPreparedModel = PreparedModel(
  vadModelPath: '/models/silero_vad.onnx',
  asrModelDir: '/models/sense-voice',
  asrModel: AsrModelDef(
    id: 'sense-voice',
    version: '1',
    files: [
      ModelFile(name: 'model.int8.onnx', size: 1, sha256: '', urls: []),
      ModelFile(name: 'tokens.txt', size: 1, sha256: '', urls: []),
    ],
    name: 'SenseVoice',
    type: 'sense_voice',
    license: '',
    languages: [],
    autoDecodeParam: 'auto',
  ),
);

/// 测试用引擎：由测试代码通过 [emit] 手动推送事件。
class FakeAsrEngine implements AsrEngine {
  final _controller = StreamController<AsrEvent>.broadcast(sync: true);

  bool started = false;
  Object? startError;

  /// 最近一次 start / updateLanguage 传入的识别语言；null 表示自动。
  String? lastLanguage;
  int languageUpdates = 0;
  AudioInput? lastInput;
  Object? inputError;

  void emit(AsrEvent event) => _controller.add(event);

  @override
  Stream<AsrEvent> get events => _controller.stream;

  @override
  Future<void> start(PreparedModel model, String? language) async {
    if (startError != null) throw startError!;
    started = true;
    lastLanguage = language;
  }

  @override
  Future<void> stop() async => started = false;

  @override
  void updateLanguage(String? language) {
    lastLanguage = language;
    languageUpdates++;
  }

  @override
  Future<void> setAudioInput(AudioInput input) async {
    if (inputError != null) throw inputError!;
    lastInput = input;
  }

  @override
  void updateForceSplitSeconds(int seconds) {}

  @override
  void dispose() => _controller.close();
}
