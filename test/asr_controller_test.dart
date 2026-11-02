import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seevoice/asr/asr_engine.dart';
import 'package:seevoice/asr/asr_language.dart';
import 'package:seevoice/l10n/l10n.dart';
import 'package:seevoice/state/asr_controller.dart';
import 'package:seevoice/state/asr_state.dart';

import 'fake_asr_engine.dart';

late FakeAsrEngine engine;
late ProviderContainer container;

AsrController controller() => container.read(asrControllerProvider.notifier);
AsrEngineState get state => container.read(asrControllerProvider);
final zh = lookupAppLocalizations(const Locale('zh'));

void main() {
  setUp(() {
    engine = FakeAsrEngine();
    container = ProviderContainer(
      overrides: [
        asrEngineProvider.overrideWithValue(engine),
        appLocalizationsProvider.overrideWithValue(zh),
      ],
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

  test('startListening and stopListening drive the engine', () async {
    final starting = controller().startListening(testPreparedModel);
    expect(state.isLoading, isTrue);
    await starting;
    expect(state.isListening, isTrue);
    expect(state.isLoading, isFalse);
    expect(engine.started, isTrue);

    await controller().stopListening();
    expect(state.isListening, isFalse);
    expect(engine.started, isFalse);
  });

  test('start failure is reported as an error', () async {
    engine.startError = const AsrStartException(AsrIssue.micPermissionDenied);
    await controller().startListening(testPreparedModel);
    expect(state.isListening, isFalse);
    expect(state.isLoading, isFalse);
    expect(state.errorId, 1);
    expect(state.errorMessage, contains('麦克风'));
  });

  test('runtime engine error stops listening and keeps history', () async {
    await controller().startListening(testPreparedModel);
    engine.emit(const AsrFinal('第一句'));
    engine.emit(const AsrPartial('第二'));
    engine.emit(const AsrError(AsrIssue.recordingInterrupted, 'busy'));
    expect(state.isListening, isFalse);
    expect(state.currentPendingText, '');
    expect(state.history.single.text, '第一句');
    expect(state.errorMessage, '录音中断：busy');
  });

  test('language change while listening is forwarded to the engine', () async {
    await controller().startListening(testPreparedModel);
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
    expect(state.history.single.displayText(zh.eventName), '😄 [笑声]');
  });

  test('clearHistory empties history and pending text', () {
    engine.emit(const AsrFinal('一'));
    engine.emit(const AsrPartial('二'));
    controller().clearHistory();
    expect(state.history, isEmpty);
    expect(state.currentPendingText, '');
  });

  group('audio input (PRD 4.8)', () {
    const mic = AudioInput.microphone;
    const speaker = AudioInput.systemAudio;

    test('switches to speaker and back while listening', () async {
      await controller().startListening(testPreparedModel);
      await controller().setAudioInput(speaker);
      expect(engine.lastInput, speaker);
      expect(state.audioInput, speaker);
      expect(state.errorMessage, zh.speakerNotice);
      expect(state.isListening, isTrue);

      await controller().setAudioInput(mic);
      expect(engine.lastInput, mic);
      expect(state.audioInput, mic);
    });

    test('choice made before listening applies on start', () async {
      await controller().setAudioInput(speaker);
      expect(engine.lastInput, isNull);
      expect(state.audioInput, speaker);
      expect(state.errorMessage, zh.speakerNotice);

      await controller().startListening(testPreparedModel);
      expect(engine.lastInput, speaker);
      expect(state.isListening, isTrue);
    });

    test('failure keeps listening on the microphone with a notice', () async {
      await controller().startListening(testPreparedModel);
      engine.inputError = const AsrStartException(AsrIssue.speakerDenied);
      await controller().setAudioInput(speaker);
      expect(state.isListening, isTrue);
      expect(state.audioInput, mic);
      expect(state.errorMessage, contains('授权'));
    });

    test('engine fallback event switches back to the microphone', () async {
      await controller().startListening(testPreparedModel);
      await controller().setAudioInput(speaker);
      engine.emit(const AsrInputChanged(mic, AsrIssue.speakerEnded));
      expect(state.audioInput, mic);
      expect(state.isListening, isTrue);
      expect(state.errorMessage, zh.speakerEnded);
    });

    test('stopping keeps the chosen source', () async {
      await controller().startListening(testPreparedModel);
      await controller().setAudioInput(speaker);
      await controller().stopListening();
      expect(state.audioInput, speaker);
    });
  });
}
