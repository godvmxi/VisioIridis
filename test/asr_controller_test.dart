import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seevoice/asr/asr_engine.dart';
import 'package:seevoice/asr/asr_language.dart';
import 'package:seevoice/state/asr_controller.dart';
import 'package:seevoice/state/asr_state.dart';

import 'fake_asr_engine.dart';

late FakeAsrEngine engine;
late ProviderContainer container;

AsrController controller() => container.read(asrControllerProvider.notifier);
AsrEngineState get state => container.read(asrControllerProvider);

void main() {
  setUp(() {
    engine = FakeAsrEngine();
    container = ProviderContainer(
      overrides: [asrEngineProvider.overrideWithValue(engine)],
    );
    container.listen(asrControllerProvider, (_, _) {});
  });

  tearDown(() {
    container.dispose();
    engine.dispose();
  });

  test('starts with all languages and auto', () {
    expect(state.enabledLanguages, AsrLanguage.values.toSet());
    expect(state.languageParam, 'auto');
  });

  test('refuses to disable the last language', () {
    expect(controller().toggleLanguage(AsrLanguage.mandarin), isTrue);
    expect(controller().toggleLanguage(AsrLanguage.cantonese), isTrue);
    expect(state.languageParam, 'en');
    expect(controller().toggleLanguage(AsrLanguage.english), isFalse);
    expect(state.enabledLanguages, {AsrLanguage.english});
  });

  test('toggleListening starts and stops the engine', () async {
    await controller().toggleListening();
    expect(state.isListening, isTrue);
    expect(engine.started, isTrue);

    await controller().toggleListening();
    expect(state.isListening, isFalse);
    expect(engine.started, isFalse);
  });

  test('language change while listening is forwarded to the engine', () async {
    await controller().toggleListening();
    controller().toggleLanguage(AsrLanguage.cantonese);
    expect(engine.lastLanguages, {AsrLanguage.mandarin, AsrLanguage.english});
  });

  test('partial updates the card, final appends to history', () {
    engine.emit(const AsrPartial('你好'));
    expect(state.currentPendingText, '你好');
    expect(state.history, isEmpty);

    engine.emit(const AsrFinal('<|zh|>你好世界', lang: '<|zh|>'));
    expect(state.currentPendingText, '');
    expect(state.pendingSegment, 1);
    expect(state.history.single.text, '你好世界');
    expect(state.history.single.lang, 'zh');
  });

  test('event-only final shows the event label; silent BGM is dropped', () {
    engine.emit(const AsrFinal('', event: '<|Laughter|>'));
    engine.emit(const AsrFinal('', event: '<|BGM|>'));
    expect(state.history.single.displayText, '😄 [笑声]');
  });

  test('clearHistory empties history and pending text', () {
    engine.emit(const AsrFinal('一'));
    engine.emit(const AsrPartial('二'));
    controller().clearHistory();
    expect(state.history, isEmpty);
    expect(state.currentPendingText, '');
  });
}
