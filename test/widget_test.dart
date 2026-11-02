import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seevoice/asr/asr_engine.dart';
import 'package:seevoice/main.dart';
import 'package:seevoice/state/asr_controller.dart';

import 'fake_asr_engine.dart';

void main() {
  late FakeAsrEngine engine;

  setUp(() => engine = FakeAsrEngine());
  tearDown(() => engine.dispose());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [asrEngineProvider.overrideWithValue(engine)],
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
}
