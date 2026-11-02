import 'dart:async';

import 'package:seevoice/asr/asr_engine.dart';
import 'package:seevoice/asr/asr_language.dart';

/// 测试用引擎：由测试代码通过 [emit] 手动推送事件。
class FakeAsrEngine implements AsrEngine {
  final _controller = StreamController<AsrEvent>.broadcast(sync: true);

  bool started = false;
  Set<AsrLanguage>? lastLanguages;

  void emit(AsrEvent event) => _controller.add(event);

  @override
  Stream<AsrEvent> get events => _controller.stream;

  @override
  Future<void> start(Set<AsrLanguage> languages) async {
    started = true;
    lastLanguages = languages;
  }

  @override
  Future<void> stop() async => started = false;

  @override
  void updateLanguages(Set<AsrLanguage> languages) => lastLanguages = languages;

  @override
  void dispose() => _controller.close();
}
