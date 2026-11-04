import 'dart:async';

import 'asr_engine.dart';
import 'prepared_model.dart';

/// 模拟引擎：逐字吐出示例句子作为临时结果，句末发出定稿结果。
/// 仅用于在接入 sherpa-onnx 之前演示 UI。
class MockAsrEngine implements AsrEngine {
  MockAsrEngine({
    this.tokenInterval = const Duration(milliseconds: 150),
    this.sentenceGap = const Duration(milliseconds: 900),
  });

  final Duration tokenInterval;
  final Duration sentenceGap;

  static const _samples = [
    AsrFinal('你好，请问今天几点开会？', lang: '<|zh|>'),
    AsrFinal('我哋下昼三点喺会议室见啦。', lang: '<|yue|>'),
    AsrFinal('Sure, see you at three.', lang: '<|en|>'),
    AsrFinal('', lang: '<|zh|>', event: '<|Laughter|>'),
    AsrFinal('这个 project 的 deadline 是下周五。', lang: '<|zh|>'),
  ];

  final _controller = StreamController<AsrEvent>.broadcast();
  Timer? _timer;
  int _sentence = 0;
  int _token = 0;

  @override
  Stream<AsrEvent> get events => _controller.stream;

  @override
  Future<void> start(PreparedModel model, String? language) async {
    _timer?.cancel();
    _token = 0;
    _timer = Timer.periodic(tokenInterval, (_) => _tick());
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void updateLanguage(String? language) {}

  @override
  void updateForceSplitSeconds(int seconds) {}

  @override
  Future<void> setAudioInput(AudioInput input) async {}

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }

  void _tick() {
    final sample = _samples[_sentence % _samples.length];
    final tokens = _tokenize(sample.text);
    if (_token < tokens.length) {
      _token++;
      _controller.add(AsrPartial(tokens.take(_token).join()));
      return;
    }
    _controller.add(sample);
    _sentence++;
    _token = 0;
    // 句间停顿：暂停计时器，模拟说话人换气。
    _timer?.cancel();
    _timer = Timer(sentenceGap, () {
      if (_controller.isClosed) return;
      _timer = Timer.periodic(tokenInterval, (_) => _tick());
    });
  }

  /// 英文按词、中文按字切分，让临时结果的增长更接近真实效果。
  static List<String> _tokenize(String text) =>
      RegExp(r'[A-Za-z]+\s?|.').allMatches(text).map((m) => m[0]!).toList();
}
