import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visioiridis/state/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> containerWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('defaults to large font and yellow on black', () async {
    final container = await containerWith({});
    final settings = container.read(settingsProvider);
    expect(settings.fontScale, FontScale.large);
    expect(settings.colorMode, ColorMode.yellowOnBlack);
    expect(settings.asrLanguage, 'zh');
    expect(settings.asrModel, isNull);
    expect(settings.decodeLanguage, isNull);
    expect(settings.boldText, isFalse);
  });

  test('changes are persisted and reloaded', () async {
    final container = await containerWith({});
    final controller = container.read(settingsProvider.notifier);
    controller.setFontScale(FontScale.giant);
    controller.setColorMode(ColorMode.blackOnWhite);
    controller.setAsrModel('yue', 'sense-voice-small-int8');
    controller.setBoldText(true);

    final prefs = container.read(sharedPreferencesProvider);
    final reloaded = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(reloaded.dispose);
    final settings = reloaded.read(settingsProvider);
    expect(settings.fontScale, FontScale.giant);
    expect(settings.colorMode, ColorMode.blackOnWhite);
    expect(settings.asrLanguage, 'yue');
    expect(settings.asrModel, 'sense-voice-small-int8');
    // 选定模型后，顶部栏的识别语言随之改为该方言。
    expect(settings.decodeLanguage, 'yue');
    expect(settings.boldText, isTrue);
    expect(settings.textWeight, FontWeight.bold);
  });

  test('choosing auto recognition is persisted', () async {
    final container = await containerWith({});
    final controller = container.read(settingsProvider.notifier);
    controller.setAsrModel('yue', 'sense-voice-small-int8');
    controller.setDecodeLanguage(null);
    controller.setFontScale(FontScale.huge);
    final settings = container.read(settingsProvider);
    expect(settings.decodeLanguage, isNull);
    expect(settings.asrModel, 'sense-voice-small-int8');

    final reloaded = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          container.read(sharedPreferencesProvider),
        ),
      ],
    );
    addTearDown(reloaded.dispose);
    expect(reloaded.read(settingsProvider).decodeLanguage, isNull);
    expect(reloaded.read(settingsProvider).asrLanguage, 'yue');
  });

  test('ignores corrupted stored values', () async {
    final container = await containerWith({'settings.fontScale': 'gigantic'});
    final settings = container.read(settingsProvider);
    expect(settings.fontScale, FontScale.large);
  });
}
