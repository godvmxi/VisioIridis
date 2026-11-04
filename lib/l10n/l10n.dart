import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../asr/asr_engine.dart';
import '../state/region_detector.dart';
import '../state/settings.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

const _simplifiedChinese = Locale('zh');
const _traditionalChinese = Locale.fromSubtags(
  languageCode: 'zh',
  scriptCode: 'Hant',
);
const _english = Locale('en');

/// 除中文外直接按语言代码对应的界面语言。
const _otherLocales = {
  'en': _english,
  'ja': Locale('ja'),
  'ko': Locale('ko'),
  'fr': Locale('fr'),
  'de': Locale('de'),
};

/// 把界面语言设置解析为 App 支持的界面语言之一（PRD 4.6）。
/// 跟随系统时：中文按繁简区分（Hant 或港澳台地区为繁体），未翻译的语言用英语。
Locale resolveAppLocale(AppLanguage language, Locale system) {
  switch (language) {
    case AppLanguage.zhHans:
      return _simplifiedChinese;
    case AppLanguage.zhHant:
      return _traditionalChinese;
    case AppLanguage.en:
    case AppLanguage.ja:
    case AppLanguage.ko:
    case AppLanguage.fr:
    case AppLanguage.de:
      return _otherLocales[language.name]!;
    case AppLanguage.system:
      if (system.languageCode != 'zh') {
        return _otherLocales[system.languageCode] ?? _english;
      }
      const traditionalRegions = {'HK', 'TW', 'MO'};
      final traditional =
          system.scriptCode == 'Hant' ||
          traditionalRegions.contains(system.countryCode);
      return traditional ? _traditionalChinese : _simplifiedChinese;
  }
}

/// 当前界面语言。跟随系统时取 App 启动（或设置变化）时的系统语言。
final appLocaleProvider = Provider<Locale>((ref) {
  final language = ref.watch(settingsProvider.select((s) => s.appLanguage));
  return resolveAppLocale(language, PlatformDispatcher.instance.locale);
});

/// 不依赖 BuildContext 的界面文字，供状态层生成提示。
final appLocalizationsProvider = Provider<AppLocalizations>(
  (ref) => lookupAppLocalizations(ref.watch(appLocaleProvider)),
);

/// 需要按枚举或配置 id 取文字的辅助方法。
extension AppStrings on AppLocalizations {
  /// 语言名称；配置中出现本 App 未翻译的语言时使用配置里的名称 [fallback]。
  String languageName(String id, [String? fallback]) => switch (id) {
    'zh' => langZh,
    'yue' => langYue,
    'en' => langEn,
    'fr' => langFr,
    'de' => langDe,
    'henan' => langHenan,
    'chuan' => langSichuan,
    'dongbei' => langDongbei,
    'shandong' => langShandong,
    'wu' => langWu,
    'minnan' => langMinnan,
    'ja' => langJa,
    'ko' => langKo,
    _ => fallback ?? id,
  };

  String fontScaleName(FontScale scale) => switch (scale) {
    FontScale.standard => fontStandard,
    FontScale.large => fontLarge,
    FontScale.huge => fontHuge,
    FontScale.extraHuge => fontExtraHuge,
    FontScale.giant => fontGiant,
  };

  String colorModeName(ColorMode mode) => switch (mode) {
    ColorMode.yellowOnBlack => colorYellowOnBlack,
    ColorMode.whiteOnBlack => colorWhiteOnBlack,
    ColorMode.blackOnWhite => colorBlackOnWhite,
    ColorMode.custom => colorCustom,
  };

  /// 各语言选项用其自身文字显示，便于看不懂当前界面语言的用户找到。
  String appLanguageName(AppLanguage language) => switch (language) {
    AppLanguage.system => followSystem,
    AppLanguage.zhHans => '简体中文',
    AppLanguage.zhHant => '繁體中文',
    AppLanguage.en => 'English',
    AppLanguage.ja => '日本語',
    AppLanguage.ko => '한국어',
    AppLanguage.fr => 'Français',
    AppLanguage.de => 'Deutsch',
  };

  String asrIssue(AsrIssue issue, [String detail = '']) => switch (issue) {
    AsrIssue.micPermissionDenied => micPermissionDenied,
    AsrIssue.recordingInterrupted => recordingInterrupted(detail),
    AsrIssue.speakerDenied => speakerDenied,
    AsrIssue.speakerEnded => speakerEnded,
    AsrIssue.switchBackFailed => switchBackFailed(detail),
    AsrIssue.modelLoadFailed => modelLoadFailed(detail),
    AsrIssue.recognitionFailed => recognitionFailed(detail),
  };

  /// 需要上屏的音频事件名称（PRD 4.3），其余事件返回 null。
  String? eventName(String event) => switch (event.toLowerCase()) {
    'laughter' => eventLaughter,
    'applause' => eventApplause,
    'cry' => eventCry,
    _ => null,
  };

  String regionName(RegionResult region) => switch (region) {
    RegionResult.mainland => regionMainland,
    RegionResult.overseas => regionOverseas,
    RegionResult.unknown => regionUnknown,
  };
}
