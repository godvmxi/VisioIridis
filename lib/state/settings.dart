import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 字号档位（PRD 4.6）：每档一个字号，最新卡片、历史记录与浮动窗口统一使用。
/// 枚举名会被持久化，调整档位时保留已有名称。
enum FontScale {
  standard(24),
  large(30),
  huge(36),
  extraHuge(44),
  giant(52);

  const FontScale(this.size);

  final double size;
}

/// 配色模式（PRD 4.6）。
enum ColorMode { yellowOnBlack, whiteOnBlack, blackOnWhite, custom }

/// 界面语言（PRD 4.6）。[system] 跟随系统语言。
enum AppLanguage { system, zhHans, zhHant, en, ja, ko, fr, de }

class AppSettings {
  const AppSettings({
    this.fontScale = FontScale.large,
    this.colorMode = ColorMode.yellowOnBlack,
    this.asrLanguage = 'zh',
    this.asrModel,
    this.decodeLanguage,
    this.floatingCaption = false,
    this.boldText = false,
    this.customBackground = const Color(0xFF0D1B2A),
    this.customText = const Color(0xFF00E5FF),
    this.appLanguage = AppLanguage.system,
    this.forceSplitSeconds = 2,
  });

  final FontScale fontScale;
  final ColorMode colorMode;

  /// 设置页“语种 → 方言 → 模型”中选择的方言（语言 id，如 yue）。
  final String asrLanguage;

  /// 设置页选择的模型 id；为 null 时取支持 [asrLanguage] 且打分最高的模型。
  final String? asrModel;

  /// 顶部栏为当前模型选择的识别语言；为 null 表示自动识别模型支持的全部语言。
  final String? decodeLanguage;

  /// App 切到后台时显示浮动字幕窗口（PRD 4.7）。
  final bool floatingCaption;

  /// 历史记录、时间戳、浮动字幕等所有字幕文字使用粗体；最新卡片始终为粗体。
  final bool boldText;

  /// 自定义配色（[ColorMode.custom]）的背景色与文字颜色。
  final Color customBackground;
  final Color customText;

  final AppLanguage appLanguage;

  /// 语音开始后超过此秒数仍无定稿结果时强制切断；0 表示关闭。
  final int forceSplitSeconds;

  /// 历史等非最新卡片文字的字重。
  FontWeight get textWeight => boldText ? FontWeight.bold : FontWeight.normal;

  AppSettings copyWith({
    FontScale? fontScale,
    ColorMode? colorMode,
    bool? floatingCaption,
    bool? boldText,
    Color? customBackground,
    Color? customText,
    AppLanguage? appLanguage,
    int? forceSplitSeconds,
  }) {
    return AppSettings(
      fontScale: fontScale ?? this.fontScale,
      colorMode: colorMode ?? this.colorMode,
      asrLanguage: asrLanguage,
      asrModel: asrModel,
      decodeLanguage: decodeLanguage,
      floatingCaption: floatingCaption ?? this.floatingCaption,
      boldText: boldText ?? this.boldText,
      customBackground: customBackground ?? this.customBackground,
      customText: customText ?? this.customText,
      appLanguage: appLanguage ?? this.appLanguage,
      forceSplitSeconds: forceSplitSeconds ?? this.forceSplitSeconds,
    );
  }
}

/// 在 main() 中用已初始化的实例覆盖。
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider 未初始化'),
);

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  static const _fontKey = 'settings.fontScale';
  static const _colorKey = 'settings.colorMode';
  static const _asrLanguageKey = 'settings.asrLanguage';
  static const _asrModelKey = 'settings.asrModel';
  static const _decodeLanguageKey = 'settings.decodeLanguage';
  static const _floatingKey = 'settings.floatingCaption';
  static const _boldKey = 'settings.boldText';
  static const _customBackgroundKey = 'settings.customBackground';
  static const _customTextKey = 'settings.customText';
  static const _appLanguageKey = 'settings.appLanguage';
  static const _forceSplitKey = 'settings.forceSplitSeconds';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      fontScale:
          _byName(FontScale.values, prefs.getString(_fontKey)) ??
          FontScale.large,
      colorMode:
          _byName(ColorMode.values, prefs.getString(_colorKey)) ??
          ColorMode.yellowOnBlack,
      asrLanguage: prefs.getString(_asrLanguageKey) ?? 'zh',
      asrModel: prefs.getString(_asrModelKey),
      // 首次使用时自动识别；存为空串表示用户选择了自动。
      decodeLanguage: switch (prefs.getString(_decodeLanguageKey)) {
        null || '' => null,
        final value => value,
      },
      floatingCaption: prefs.getBool(_floatingKey) ?? false,
      boldText: prefs.getBool(_boldKey) ?? false,
      customBackground:
          _color(prefs.getInt(_customBackgroundKey)) ??
          const AppSettings().customBackground,
      customText:
          _color(prefs.getInt(_customTextKey)) ??
          const AppSettings().customText,
      appLanguage:
          _byName(AppLanguage.values, prefs.getString(_appLanguageKey)) ??
          AppLanguage.system,
      forceSplitSeconds: prefs.getInt(_forceSplitKey) ?? 2,
    );
  }

  void setAppLanguage(AppLanguage value) {
    state = state.copyWith(appLanguage: value);
    _prefs.setString(_appLanguageKey, value.name);
  }

  void setCustomBackground(Color value) {
    state = state.copyWith(customBackground: value);
    _prefs.setInt(_customBackgroundKey, value.toARGB32());
  }

  void setCustomText(Color value) {
    state = state.copyWith(customText: value);
    _prefs.setInt(_customTextKey, value.toARGB32());
  }

  static Color? _color(int? argb) => argb == null ? null : Color(argb);

  void setBoldText(bool value) {
    state = state.copyWith(boldText: value);
    _prefs.setBool(_boldKey, value);
  }

  void setFloatingCaption(bool value) {
    state = state.copyWith(floatingCaption: value);
    _prefs.setBool(_floatingKey, value);
  }

  void setFontScale(FontScale value) {
    state = state.copyWith(fontScale: value);
    _prefs.setString(_fontKey, value.name);
  }

  void setColorMode(ColorMode value) {
    state = state.copyWith(colorMode: value);
    _prefs.setString(_colorKey, value.name);
  }

  void setForceSplitSeconds(int value) {
    state = state.copyWith(forceSplitSeconds: value);
    _prefs.setInt(_forceSplitKey, value);
  }

  /// 设置页依次选定方言 [language] 与模型 [modelId]；
  /// 顶部栏的识别语言随之改为该方言。
  void setAsrModel(String language, String modelId) {
    _replace(
      asrLanguage: language,
      asrModel: modelId,
      decodeLanguage: language,
    );
    _prefs.setString(_asrLanguageKey, language);
    _prefs.setString(_asrModelKey, modelId);
    _prefs.setString(_decodeLanguageKey, language);
  }

  /// 顶部栏选择识别语言；null 表示自动。
  void setDecodeLanguage(String? language) {
    _replace(decodeLanguage: language);
    _prefs.setString(_decodeLanguageKey, language ?? '');
  }

  /// copyWith 无法把可空字段改回 null，模型相关字段在这里整体替换。
  void _replace({
    String? asrLanguage,
    String? asrModel,
    String? decodeLanguage,
  }) {
    final s = state;
    state = AppSettings(
      fontScale: s.fontScale,
      colorMode: s.colorMode,
      asrLanguage: asrLanguage ?? s.asrLanguage,
      asrModel: asrModel ?? s.asrModel,
      decodeLanguage: decodeLanguage,
      floatingCaption: s.floatingCaption,
      boldText: s.boldText,
      customBackground: s.customBackground,
      customText: s.customText,
      appLanguage: s.appLanguage,
      forceSplitSeconds: s.forceSplitSeconds,
    );
  }

  static T? _byName<T extends Enum>(List<T> values, String? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}
