import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seevoice/asr/asr_engine.dart';
import 'package:seevoice/asr/prepared_model.dart';
import 'package:seevoice/main.dart';
import 'package:seevoice/model_store/model_config.dart';
import 'package:seevoice/platform/background_platform.dart';
import 'package:seevoice/state/asr_controller.dart';
import 'package:seevoice/state/model_providers.dart';
import 'package:seevoice/state/settings.dart';
import 'package:seevoice/ui/app_colors.dart';
import 'package:seevoice/ui/model_preparer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_asr_engine.dart';
import 'fake_background_platform.dart';

/// 跳过模型下载，直接视为模型已就绪。
class ReadyModelPreparer implements ModelPreparer {
  @override
  Future<PreparedModel?> ensureReady(BuildContext context) async =>
      testPreparedModel;
}

void main() {
  late FakeAsrEngine engine;
  late FakeBackgroundPlatform platform;

  setUp(() {
    engine = FakeAsrEngine();
    platform = FakeBackgroundPlatform();
  });
  tearDown(() => engine.dispose());

  Future<void> pumpApp(WidgetTester tester,
      {Map<String, Object> prefsValues = const {}}) async {
    // 上一个用例可能停在后台状态，先恢复到前台。
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          asrEngineProvider.overrideWithValue(engine),
          modelPreparerProvider.overrideWithValue(ReadyModelPreparer()),
          sharedPreferencesProvider.overrideWithValue(prefs),
          backgroundPlatformProvider.overrideWithValue(platform),
          modelConfigProvider.overrideWith((ref) => ModelConfig.parse(
              File('assets/config/model_config.json').readAsStringSync())),
        ],
        child: const SeeVoiceApp(),
      ),
    );
  }

  testWidgets('idle state shows placeholder and start button', (tester) async {
    await pumpApp(tester);
    expect(find.text('等待语音输入...'), findsOneWidget);
    expect(find.text('开始识别'), findsOneWidget);
    expect(find.text('麦克风'), findsOneWidget);
    expect(find.text('喇叭'), findsOneWidget);
    expect(find.text('普通话 +2'), findsOneWidget);
  });

  testWidgets('largest font fits on a phone screen while listening',
      (tester) async {
    // POCO F6 的逻辑分辨率约 412 × 915 dp。
    tester.view.physicalSize = const Size(1236, 2745);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester, prefsValues: {'settings.fontScale': 'giant'});

    await tester.tap(find.text('开始识别'));
    await tester.pump();
    engine.emit(const AsrFinal('你好，请问今天几点开会？'));
    engine.emit(const AsrPartial('下午三点在三楼会议室见，记得带上电脑和资料'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('停止识别'), findsOneWidget);
  });

  testWidgets('start, partial, final flow', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('开始识别'));
    await tester.pump();
    expect(find.text('停止识别'), findsOneWidget);
    expect(engine.started, isTrue);

    engine.emit(const AsrPartial('今天几点'));
    await tester.pump();
    expect(find.text('今天几点'), findsOneWidget);

    engine.emit(const AsrFinal('今天几点开会？'));
    // 拾音中状态点持续呼吸，不能用 pumpAndSettle。
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('等待语音输入...'), findsOneWidget);
    expect(find.textContaining('今天几点开会？', findRichText: true),
        findsOneWidget);
  });

  testWidgets('cannot deselect the last language', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('普通话 +2'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, '普通话'));
    await tester.pump();
    await tester.tap(find.widgetWithText(CheckboxListTile, '粤语'));
    await tester.pump();
    await tester.tap(find.widgetWithText(CheckboxListTile, '英语'));
    await tester.pump();
    expect(find.text('至少保留一种识别语言'), findsOneWidget);
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(find.text('英语'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('clear asks for confirmation', (tester) async {
    await pumpApp(tester);
    engine.emit(const AsrFinal('第一句'));
    await tester.pumpAndSettle();
    expect(find.textContaining('第一句', findRichText: true), findsOneWidget);

    await tester.tap(find.byTooltip('清屏'));
    await tester.pumpAndSettle();
    expect(find.text('确认清空所有历史字幕记录？'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '确认清空'));
    await tester.pumpAndSettle();
    expect(find.textContaining('第一句', findRichText: true), findsNothing);
  });

  testWidgets('settings change font size and color mode', (tester) async {
    // 设置页较长，用高屏幕让所有分区一次构建出来。
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    expect(find.text('识别模型'), findsOneWidget);
    expect(find.textContaining('自动：SenseVoice Small'), findsNWidgets(3));

    await tester.tap(find.text('巨大'));
    await tester.tap(find.text('黑字白底'));
    await tester.pumpAndSettle();

    final preview = tester.widget<Text>(find.text('下午三点见'));
    expect(preview.style?.fontSize, FontScale.giant.size);
    expect(preview.style?.color, AppPalette.blackOnWhite.focusText);

    await tester.pageBack();
    await tester.pumpAndSettle();
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppPalette.blackOnWhite.background);
  });

  /// 文本树中内容为 [text] 的片段合并所有祖先样式后的最终样式。
  TextStyle? effectiveStyle(InlineSpan span, String text,
      [TextStyle? inherited]) {
    if (span is! TextSpan) return null;
    final style = inherited?.merge(span.style) ?? span.style;
    if (span.text == text) return style;
    for (final child in span.children ?? const <InlineSpan>[]) {
      final found = effectiveStyle(child, text, style);
      if (found != null) return found;
    }
    return null;
  }

  TextStyle? styleOf(WidgetTester tester, String text) {
    for (final rich in tester.widgetList<RichText>(
        find.textContaining(text, findRichText: true))) {
      final style = effectiveStyle(rich.text, text);
      if (style != null) return style;
    }
    return null;
  }

  testWidgets('yellow mode colors all caption text yellow', (tester) async {
    await pumpApp(tester);
    engine.emit(const AsrFinal('第一句'));
    await tester.pumpAndSettle();

    const yellow = Color(0xFFFFE600);
    expect(styleOf(tester, '第一句')?.color, yellow);
    final time = tester
        .widget<RichText>(find.textContaining('第一句', findRichText: true))
        .text
        .toPlainText()
        .substring(0, 8);
    expect(styleOf(tester, time)?.color?.toARGB32(), 0x99FFE600);
    expect(styleOf(tester, '普通话 +2')?.color, yellow);
  });

  testWidgets('bold setting makes history text bold', (tester) async {
    await pumpApp(tester, prefsValues: {'settings.boldText': true});
    engine.emit(const AsrFinal('第一句'));
    await tester.pumpAndSettle();
    expect(styleOf(tester, '第一句')?.fontWeight, FontWeight.bold);
  });

  testWidgets('custom colors apply to captions and warn on low contrast',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('自定义'));
    await tester.pumpAndSettle();
    expect(find.text('背景色'), findsOneWidget);

    // 白底 + 白字：对比度 1:1，应提示。
    await tester.tap(find.bySemanticsLabel('背景颜色 8'));
    await tester.tap(find.bySemanticsLabel('文字颜色 2'));
    await tester.pumpAndSettle();
    expect(find.textContaining('对比度较低'), findsOneWidget);

    // 白底 + 深蓝字：对比度足够。
    await tester.tap(find.bySemanticsLabel('文字颜色 9'));
    await tester.pumpAndSettle();
    expect(find.textContaining('对比度较低'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    engine.emit(const AsrFinal('第一句'));
    await tester.pumpAndSettle();
    expect(styleOf(tester, '第一句')?.color, const Color(0xFF0D47A1));
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, const Color(0xFFFFFFFF));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings.colorMode'), 'custom');
    expect(prefs.getInt('settings.customText'), 0xFF0D47A1);
  });

  testWidgets('live text and history share one font size', (tester) async {
    await pumpApp(tester, prefsValues: {'settings.fontScale': 'huge'});
    await tester.tap(find.text('开始识别'));
    await tester.pump();
    engine.emit(const AsrFinal('第一句'));
    engine.emit(const AsrPartial('正在说'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(styleOf(tester, '第一句')?.fontSize, FontScale.huge.size);
    expect(tester.widget<Text>(find.text('正在说')).style?.fontSize,
        FontScale.huge.size);
  });

  testWidgets('top-bar sound source selector', (tester) async {
    await pumpApp(tester);
    expect(find.text('麦克风'), findsOneWidget);

    await tester.tap(find.text('喇叭'));
    await tester.pump();
    expect(engine.lastInput, isNull);
    expect(find.textContaining('无法识别电话'), findsOneWidget);

    await tester.tap(find.text('开始识别'));
    await tester.pump();
    expect(engine.lastInput, AudioInput.systemAudio);

    await tester.tap(find.text('麦克风'));
    await tester.pump();
    expect(engine.lastInput, AudioInput.microphone);
  });

  testWidgets('top bar order and language dialog', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    // 声音来源在主语言之前；不显示图标。
    final mic = tester.getTopLeft(find.text('麦克风')).dx;
    final languages = tester.getTopLeft(find.text('普通话 +2')).dx;
    expect(mic < languages, isTrue);
    expect(
      find.descendant(
        of: find.byType(SegmentedButton<AudioInput>),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );

    await tester.tap(find.text('普通话 +2'));
    await tester.pumpAndSettle();
    expect(find.text('当前模型：SenseVoice Small'), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, '粤语'), findsOneWidget);
    expect(find.text('日语、韩语'), findsOneWidget);

    await tester.tap(find.widgetWithText(CheckboxListTile, '普通话'));
    await tester.pump();
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(find.text('粤语 +1'), findsOneWidget);
  });

  testWidgets('model chooser lists candidates with scores', (tester) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();

    expect(find.text('自动：SenseVoice Small  10 分'), findsNWidgets(2));
    await tester.tap(find.text('普通话').last);
    await tester.pumpAndSettle();

    expect(find.text('为“普通话”选择模型'), findsOneWidget);
    expect(find.text('SenseVoice Small    普通话 10 分'), findsOneWidget);
    expect(find.text('TeleSpeech    普通话 7 分'), findsOneWidget);
    expect(find.text('普通话 7 · 河南话 9'), findsOneWidget);

    await tester.tap(find.text('TeleSpeech    普通话 7 分'));
    await tester.pumpAndSettle();
    expect(find.text('TeleSpeech  7 分'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings.modelPreferences'),
        contains('telespeech-ctc-int8'));
  });

  group('floating caption (PRD 4.7)', () {
    void setLifecycle(WidgetTester tester, List<AppLifecycleState> states) {
      for (final state in states) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
    }

    Future<void> goBackground(WidgetTester tester) async {
      setLifecycle(tester,
          [AppLifecycleState.inactive, AppLifecycleState.hidden]);
      await tester.pump();
    }

    Future<void> goForeground(WidgetTester tester) async {
      setLifecycle(tester,
          [AppLifecycleState.inactive, AppLifecycleState.resumed]);
      await tester.pump();
    }

    testWidgets('shows in background while listening and follows results',
        (tester) async {
      await pumpApp(tester, prefsValues: {'settings.floatingCaption': true});
      await tester.tap(find.text('开始识别'));
      await tester.pump();
      engine.emit(const AsrFinal('第一句'));

      await goBackground(tester);
      expect(platform.visible, isTrue);
      expect(platform.shownStyle?.focusColor,
          AppPalette.yellowOnBlack.focusText);
      expect(platform.shownStyle?.focusSize, FontScale.large.size);
      expect(platform.shownStyle?.historySize, FontScale.large.size);
      expect(platform.updates.last.history, ['第一句']);

      engine.emit(const AsrPartial('第二'));
      await tester.pump();
      expect(platform.updates.last.current, '第二');
      expect(platform.updates.last.partial, isTrue);

      // 发送全部历史（旧的在前），由窗口按高度显示并支持滑动。
      engine.emit(const AsrFinal('第二句'));
      engine.emit(const AsrFinal('第三句'));
      await tester.pump();
      expect(platform.updates.last.history, ['第一句', '第二句', '第三句']);
      expect(platform.updates.last.current, '');

      await goForeground(tester);
      expect(platform.visible, isFalse);
    });

    testWidgets('overlay selects the sound source and toasts the notice',
        (tester) async {
      await pumpApp(tester, prefsValues: {'settings.floatingCaption': true});
      await tester.tap(find.text('开始识别'));
      await tester.pump();
      await goBackground(tester);
      expect(platform.updates.last.systemAudio, isFalse);

      platform.selectInput(AudioInput.systemAudio);
      await tester.pump();
      expect(engine.lastInput, AudioInput.systemAudio);
      expect(platform.updates.last.systemAudio, isTrue);
      expect(platform.toasts.last, contains('无法识别电话'));

      platform.selectInput(AudioInput.microphone);
      await tester.pump();
      expect(engine.lastInput, AudioInput.microphone);
      expect(platform.updates.last.systemAudio, isFalse);
    });

    testWidgets('overlay exit stops listening and closes the app',
        (tester) async {
      await pumpApp(tester, prefsValues: {'settings.floatingCaption': true});
      await tester.tap(find.text('开始识别'));
      await tester.pump();
      await goBackground(tester);
      expect(platform.visible, isTrue);

      platform.tapExit();
      await tester.pump();
      expect(engine.started, isFalse);
      expect(platform.visible, isFalse);
      expect(platform.exited, isTrue);
    });

    testWidgets('stays hidden when the setting is off', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('开始识别'));
      await tester.pump();
      await goBackground(tester);
      expect(platform.visible, isFalse);
    });

    testWidgets('stays hidden when not listening', (tester) async {
      await pumpApp(tester, prefsValues: {'settings.floatingCaption': true});
      await goBackground(tester);
      expect(platform.visible, isFalse);
    });

    testWidgets('stays hidden without overlay permission', (tester) async {
      platform.overlayAllowed = false;
      await pumpApp(tester, prefsValues: {'settings.floatingCaption': true});
      await tester.tap(find.text('开始识别'));
      await tester.pump();
      await goBackground(tester);
      expect(platform.visible, isFalse);
    });

    testWidgets('hides when listening stops in the background',
        (tester) async {
      await pumpApp(tester, prefsValues: {'settings.floatingCaption': true});
      await tester.tap(find.text('开始识别'));
      await tester.pump();
      await goBackground(tester);
      expect(platform.visible, isTrue);

      engine.emit(const AsrError('录音中断'));
      await tester.pump();
      expect(platform.visible, isFalse);
    });

    Future<void> openSettings(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await pumpApp(tester);
      await tester.tap(find.byTooltip('设置'));
      await tester.pumpAndSettle();
    }

    testWidgets('enabling turns on the floating window', (tester) async {
      await openSettings(tester);
      await tester.tap(find.text('显示浮动窗'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings.floatingCaption'), isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('stays off when overlay permission is not granted',
        (tester) async {
      platform.overlayAllowed = false;
      await openSettings(tester);
      await tester.tap(find.text('显示浮动窗'));
      await tester.pumpAndSettle();

      expect(find.text('需要悬浮窗权限'), findsOneWidget);
      await tester.tap(find.text('去开启'));
      await tester.pumpAndSettle();

      expect(platform.openedOverlaySettings, isTrue);
      expect(find.text('未获得悬浮窗权限，浮动窗未开启'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings.floatingCaption'), isNull);
    });
  });
}
