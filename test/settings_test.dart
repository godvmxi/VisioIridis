import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seevoice/state/settings.dart';
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
    expect(settings.modelPreferences, isEmpty);
    expect(settings.boldText, isFalse);
  });

  test('changes are persisted and reloaded', () async {
    final container = await containerWith({});
    final controller = container.read(settingsProvider.notifier);
    controller.setFontScale(FontScale.giant);
    controller.setColorMode(ColorMode.blackOnWhite);
    controller.setModelPreference('zh', 'telespeech-ctc-int8');
    controller.setBoldText(true);

    final prefs = container.read(sharedPreferencesProvider);
    final reloaded = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(reloaded.dispose);
    final settings = reloaded.read(settingsProvider);
    expect(settings.fontScale, FontScale.giant);
    expect(settings.colorMode, ColorMode.blackOnWhite);
    expect(settings.modelPreferences, {'zh': 'telespeech-ctc-int8'});
    expect(settings.boldText, isTrue);
    expect(settings.textWeight, FontWeight.bold);
  });

  test('clearing a model preference returns to automatic', () async {
    final container = await containerWith({});
    final controller = container.read(settingsProvider.notifier);
    controller.setModelPreference('zh', 'telespeech-ctc-int8');
    controller.setModelPreference('zh', null);
    expect(container.read(settingsProvider).modelPreferences, isEmpty);
  });

  test('ignores corrupted stored values', () async {
    final container = await containerWith({
      'settings.fontScale': 'gigantic',
      'settings.modelPreferences': 'not json',
    });
    final settings = container.read(settingsProvider);
    expect(settings.fontScale, FontScale.large);
    expect(settings.modelPreferences, isEmpty);
  });
}
