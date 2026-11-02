import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:seevoice/l10n/l10n.dart';
import 'package:seevoice/state/settings.dart';

/// 界面语言解析（PRD 4.6）。
void main() {
  const hans = Locale('zh');
  const hant = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
  const en = Locale('en');

  test('explicit choices ignore the system language', () {
    const system = Locale('fr', 'FR');
    expect(resolveAppLocale(AppLanguage.zhHans, system), hans);
    expect(resolveAppLocale(AppLanguage.zhHant, system), hant);
    expect(resolveAppLocale(AppLanguage.en, system), en);
  });

  test('following the system picks simplified or traditional Chinese', () {
    Locale follow(Locale system) =>
        resolveAppLocale(AppLanguage.system, system);
    expect(follow(const Locale('zh', 'CN')), hans);
    expect(follow(const Locale('zh')), hans);
    expect(follow(const Locale('zh', 'TW')), hant);
    expect(follow(const Locale('zh', 'HK')), hant);
    expect(
      follow(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')),
      hant,
    );
    expect(follow(const Locale('en', 'US')), en);
    expect(follow(const Locale('ja', 'JP')), en);
  });

  test('every language has the app title in its own script', () {
    expect(lookupAppLocalizations(hans).appTitle, '伊利斯之视');
    expect(lookupAppLocalizations(hant).appTitle, '伊利斯之視');
    expect(lookupAppLocalizations(en).appTitle, 'Visio Iridis');
  });
}
