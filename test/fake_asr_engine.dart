import 'dart:async';

import 'package:seevoice/asr/asr_engine.dart';
import 'package:seevoice/asr/asr_language.dart';
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
  Set<AsrLanguage>? lastLanguages;
  AudioInput? lastInput;
  Object? inputError;

  void emit(AsrEvent event) => _controller.add(event);

  @override
  Stream<AsrEvent> get events => _controller.stream;

  @override
  Future<void> start(PreparedModel model, Set<AsrLanguage> languages) async {
    if (startError != null) throw startError!;
    started = true;
    lastLanguages = languages;
  }

  @override
  Future<void> stop() async => started = false;

  @override
  void updateLanguages(Set<AsrLanguage> languages) => lastLanguages = languages;

  @override
  Future<void> setAudioInput(AudioInput input) async {
    if (inputError != null) throw inputError!;
    lastInput = input;
  }

  @override
  void dispose() => _controller.close();
}
