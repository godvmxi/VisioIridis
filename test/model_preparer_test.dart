import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seevoice/asr/prepared_model.dart';
import 'package:seevoice/l10n/l10n.dart';
import 'package:seevoice/model_store/model_config.dart';
import 'package:seevoice/model_store/model_repository.dart';
import 'package:seevoice/state/asr_controller.dart';
import 'package:seevoice/state/model_providers.dart';
import 'package:seevoice/state/settings.dart';
import 'package:seevoice/ui/model_preparer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_asr_engine.dart';

/// 启动前检测模型变化（PRD 4.5.3、4.6）。
void main() {
  final config = ModelConfig.parse(
    File('assets/config/model_config.json').readAsStringSync(),
  );
  AsrModelDef model(String id) =>
      config.asrModels.firstWhere((m) => m.id == id);
  const senseVoice = 'sense-voice-small-int8';
  const teleSpeech = 'telespeech-ctc-int8';

  late Directory root;
  late ModelCache cache;
  late FakeAsrEngine engine;

  /// 按配置中的大小生成稀疏文件，使 cache 视其为就绪。
  void makeReady(ModelDef def) {
    for (final file in def.files) {
      final f = cache.fileFor(def, file)..createSync(recursive: true);
      f.openSync(mode: FileMode.write)
        ..truncateSync(file.size)
        ..closeSync();
    }
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync('preparer_test');
    cache = ModelCache(root);
    engine = FakeAsrEngine();
  });
  tearDown(() {
    engine.dispose();
    root.deleteSync(recursive: true);
  });

  /// 点击按钮调用 [ModelPreparer.ensureReady]，返回结果的容器。
  Future<List<PreparedModel?>> pumpHost(
    WidgetTester tester, {
    required Map<String, Object> prefsValues,
  }) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    final results = <PreparedModel?>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          asrEngineProvider.overrideWithValue(engine),
          sharedPreferencesProvider.overrideWithValue(prefs),
          modelConfigProvider.overrideWith((ref) => config),
          modelCacheProvider.overrideWith((ref) => cache),
          modelStoresProvider.overrideWith((ref) => []),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () async => results.add(
                  await ref.read(modelPreparerProvider).ensureReady(context),
                ),
                child: const Text('开始'),
              ),
            ),
          ),
        ),
      ),
    );
    return results;
  }

  /// 文件读写是真实异步操作，需要在 runAsync 中让出时间。
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
  }

  testWidgets('switching to a ready model shows a notice', (tester) async {
    makeReady(config.vad);
    makeReady(model(senseVoice));
    final results = await pumpHost(
      tester,
      prefsValues: {ModelPreparer.lastModelKey: teleSpeech},
    );

    await tester.tap(find.text('开始'));
    await settle(tester);

    expect(results.single?.asrModel.id, senseVoice);
    expect(find.text('识别模型已切换为「SenseVoice Small」'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ModelPreparer.lastModelKey), senseVoice);
  });

  testWidgets('unchanged ready model starts silently', (tester) async {
    makeReady(config.vad);
    makeReady(model(senseVoice));
    final results = await pumpHost(
      tester,
      prefsValues: {ModelPreparer.lastModelKey: senseVoice},
    );

    await tester.tap(find.text('开始'));
    await settle(tester);

    expect(results.single?.asrModel.id, senseVoice);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('changed model needing download offers the previous one', (
    tester,
  ) async {
    makeReady(config.vad);
    makeReady(model(senseVoice));
    final results = await pumpHost(
      tester,
      prefsValues: {
        ModelPreparer.lastModelKey: senseVoice,
        'settings.asrLanguage': 'zh',
        'settings.asrModel': teleSpeech,
      },
    );

    await tester.tap(find.text('开始'));
    await settle(tester);

    expect(find.text('识别模型已变更'), findsOneWidget);
    expect(
      find.textContaining('由「SenseVoice Small」变更为「TeleSpeech」'),
      findsOneWidget,
    );
    await tester.tap(find.text('先用「SenseVoice Small」'));
    await settle(tester);

    expect(results.single?.asrModel.id, senseVoice);
  });

  testWidgets('cancelling the download does not start', (tester) async {
    makeReady(config.vad);
    final results = await pumpHost(
      tester,
      prefsValues: {ModelPreparer.lastModelKey: teleSpeech},
    );

    await tester.tap(find.text('开始'));
    await settle(tester);

    // 上次的模型未就绪，不提供“先用”。
    expect(find.text('识别模型已变更'), findsOneWidget);
    expect(find.textContaining('先用'), findsNothing);
    await tester.tap(find.text('取消'));
    await settle(tester);

    expect(results.single, isNull);
  });
}
