import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visioiridis/asr/asr_engine.dart';
import 'package:visioiridis/l10n/l10n.dart';
import 'package:visioiridis/state/asr_controller.dart';
import 'package:visioiridis/state/asr_state.dart';
import 'package:visioiridis/state/current_model.dart';
import 'package:visioiridis/state/script_converter.dart';

import 'fake_asr_engine.dart';
import 'fake_script_converter.dart';

late FakeAsrEngine engine;
late ProviderContainer container;

AsrController controller() => container.read(asrControllerProvider.notifier);
AsrEngineState get state => container.read(asrControllerProvider);
final zh = lookupAppLocalizations(const Locale('zh'));

/// 代替设置页与顶部栏选择的识别语言。
class TestLanguage extends Notifier<String?> {
  @override
  String? build() => null;

  // 本文件顶层的 state getter 会遮住继承来的 setter。
  void set(String? value) => this.state = value;
}

final testLanguageProvider = NotifierProvider<TestLanguage, String?>(
  TestLanguage.new,
);

void main() {
  setUp(() {
    engine = FakeAsrEngine();
    container = ProviderContainer(
      overrides: [
        asrEngineProvider.overrideWithValue(engine),
        appLocalizationsProvider.overrideWithValue(zh),
        chineseScriptProvider.overrideWithValue(null),
        decodeLanguageProvider.overrideWith(
          (ref) => ref.watch(testLanguageProvider),
        ),
      ],
    );
    container.listen(asrControllerProvider, (_, _) {});
  });

  tearDown(() {
    container.dispose();
    engine.dispose();
  });

  test('starts with the chosen recognition language', () async {
    container.read(testLanguageProvider.notifier).set('yue');
    await controller().startListening(testPreparedModel);
    expect(engine.lastLanguage, 'yue');
  });

  test('auto recognition passes no language', () async {
    await controller().startListening(testPreparedModel);
    expect(engine.lastLanguage, isNull);
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
    // Riverpod 在微任务中通知监听者。
    container.read(testLanguageProvider.notifier).set('en');
    await Future<void>.delayed(Duration.zero);
    expect(engine.lastLanguage, 'en');
    container.read(testLanguageProvider.notifier).set(null);
    await Future<void>.delayed(Duration.zero);
    expect(engine.lastLanguage, isNull);
    expect(engine.languageUpdates, 2);
  });

  test('language change while idle waits for the next start', () async {
    container.read(testLanguageProvider.notifier).set('en');
    await Future<void>.delayed(Duration.zero);
    expect(engine.languageUpdates, 0);
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

  test('punctuation-only results are not shown', () {
    engine.emit(const AsrPartial('。'));
    expect(state.currentPendingText, '');
    engine.emit(const AsrFinal(' . '));
    engine.emit(const AsrFinal('<|zh|>。'));
    expect(state.history, isEmpty);
    // 带事件标签时仍显示标签。
    engine.emit(const AsrFinal('。', event: '<|Laughter|>'));
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

  group('Chinese script conversion', () {
    ProviderContainer withScript(ChineseScript script) {
      final c = ProviderContainer(
        overrides: [
          asrEngineProvider.overrideWithValue(engine),
          appLocalizationsProvider.overrideWithValue(zh),
          chineseScriptProvider.overrideWithValue(script),
          scriptConverterProvider.overrideWithValue(FakeScriptConverter()),
        ],
      );
      c.listen(asrControllerProvider, (_, _) {});
      addTearDown(c.dispose);
      return c;
    }

    test('traditional interface converts partial and final text', () async {
      final c = withScript(ChineseScript.traditional);
      engine.emit(const AsrPartial('开会'));
      await pumpEventQueue();
      expect(c.read(asrControllerProvider).currentPendingText, '開會');

      engine.emit(const AsrFinal('我说话', lang: '<|zh|>'));
      await pumpEventQueue();
      final item = c.read(asrControllerProvider).history.single;
      expect(item.text, '我說話');
      expect(item.lang, 'zh');
    });

    test('simplified interface converts traditional output', () async {
      final c = withScript(ChineseScript.simplified);
      engine.emit(const AsrFinal('開會'));
      await pumpEventQueue();
      expect(c.read(asrControllerProvider).history.single.text, '开会');
    });

    test('events keep their order while converting', () async {
      final c = withScript(ChineseScript.traditional);
      engine.emit(const AsrFinal('一'));
      engine.emit(const AsrFinal('二'));
      engine.emit(const AsrPartial('三'));
      await pumpEventQueue();
      final s = c.read(asrControllerProvider);
      expect(s.history.map((i) => i.text), ['一', '二']);
      expect(s.currentPendingText, '三');
    });
  });
}
