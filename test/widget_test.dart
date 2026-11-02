import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seevoice/asr/asr_engine.dart';
import 'package:seevoice/asr/prepared_model.dart';
import 'package:seevoice/main.dart';
import 'package:seevoice/model_store/model_config.dart';
import 'package:seevoice/state/asr_controller.dart';
import 'package:seevoice/state/model_providers.dart';
import 'package:seevoice/state/settings.dart';
import 'package:seevoice/ui/app_colors.dart';
import 'package:seevoice/ui/model_preparer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_asr_engine.dart';

/// 跳过模型下载，直接视为模型已就绪。
class ReadyModelPreparer implements ModelPreparer {
  @override
  Future<PreparedModel?> ensureReady(BuildContext context) async =>
      testPreparedModel;
}

void main() {
  late FakeAsrEngine engine;

  setUp(() => engine = FakeAsrEngine());
  tearDown(() => engine.dispose());

  Future<void> pumpApp(WidgetTester tester,
      {Map<String, Object> prefsValues = const {}}) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          asrEngineProvider.overrideWithValue(engine),
          modelPreparerProvider.overrideWithValue(ReadyModelPreparer()),
          sharedPreferencesProvider.overrideWithValue(prefs),
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
    expect(find.text('普通话'), findsOneWidget);
    expect(find.text('粤语'), findsOneWidget);
    expect(find.text('英语'), findsOneWidget);
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
    await tester.tap(find.widgetWithText(FilterChip, '普通话'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, '粤语'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, '英语'));
    await tester.pump();
    expect(find.text('至少保留一种识别语言'), findsOneWidget);
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
    expect(find.text('自动（SenseVoice Small）'), findsNWidgets(3));

    await tester.tap(find.text('巨大'));
    await tester.tap(find.text('黑字白底'));
    await tester.pumpAndSettle();

    final preview = tester.widget<Text>(find.text('下午三点见'));
    expect(preview.style?.fontSize, FontScale.giant.focus);
    expect(preview.style?.color, AppPalette.blackOnWhite.focusText);

    await tester.pageBack();
    await tester.pumpAndSettle();
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppPalette.blackOnWhite.background);
  });
}
