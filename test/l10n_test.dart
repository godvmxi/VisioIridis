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
    expect(resolveAppLocale(AppLanguage.ja, system), const Locale('ja'));
    expect(resolveAppLocale(AppLanguage.ko, system), const Locale('ko'));
    expect(resolveAppLocale(AppLanguage.de, system), const Locale('de'));
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
    expect(follow(const Locale('ja', 'JP')), const Locale('ja'));
    expect(follow(const Locale('ko', 'KR')), const Locale('ko'));
    expect(follow(const Locale('fr', 'CA')), const Locale('fr'));
    expect(follow(const Locale('de', 'AT')), const Locale('de'));
    // 未翻译的系统语言用英语。
    expect(follow(const Locale('es', 'ES')), en);
  });

  test('every language has the app title in its own script', () {
    expect(lookupAppLocalizations(hans).appTitle, '伊利斯之视');
    expect(lookupAppLocalizations(hant).appTitle, '伊利斯之視');
    expect(lookupAppLocalizations(en).appTitle, 'Visio Iridis');
  });

  test('every display language has a translation', () {
    for (final language in AppLanguage.values) {
      final locale = resolveAppLocale(language, const Locale('en'));
      expect(
        AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains(locale.languageCode),
      );
    }
    expect(lookupAppLocalizations(const Locale('ja')).settings, '設定');
    expect(lookupAppLocalizations(const Locale('ko')).settings, '설정');
    expect(lookupAppLocalizations(const Locale('fr')).settings, 'Paramètres');
    expect(
      lookupAppLocalizations(const Locale('de')).settings,
      'Einstellungen',
    );
  });
}
