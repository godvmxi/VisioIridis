import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 字号档位（PRD 4.6）：每档一个字号，最新卡片、历史记录与浮动窗口统一使用。
/// 枚举名会被持久化，调整档位时保留已有名称。
enum FontScale {
  standard('标准', 24),
  large('大', 30),
  huge('特大', 36),
  extraHuge('超大', 44),
  giant('巨大', 52);

  const FontScale(this.label, this.size);

  final String label;
  final double size;
}

/// 配色模式（PRD 4.6）。
enum ColorMode {
  yellowOnBlack('黄字黑底'),
  whiteOnBlack('白字黑底'),
  blackOnWhite('黑字白底'),
  custom('自定义');

  const ColorMode(this.label);

  final String label;
}

class AppSettings {
  const AppSettings({
    this.fontScale = FontScale.large,
    this.colorMode = ColorMode.yellowOnBlack,
    this.modelPreferences = const {},
    this.floatingCaption = false,
    this.boldText = false,
    this.customBackground = const Color(0xFF0D1B2A),
    this.customText = const Color(0xFF00E5FF),
  });

  final FontScale fontScale;
  final ColorMode colorMode;

  /// 语言 id → 指定的模型 id；没有条目表示“自动”（按权重选择）。
  final Map<String, String> modelPreferences;

  /// App 切到后台时显示浮动字幕窗口（PRD 4.7）。
  final bool floatingCaption;

  /// 历史记录、时间戳、浮动字幕等所有字幕文字使用粗体；最新卡片始终为粗体。
  final bool boldText;

  /// 自定义配色（[ColorMode.custom]）的背景色与文字颜色。
  final Color customBackground;
  final Color customText;

  /// 历史等非最新卡片文字的字重。
  FontWeight get textWeight => boldText ? FontWeight.bold : FontWeight.normal;

  AppSettings copyWith({
    FontScale? fontScale,
    ColorMode? colorMode,
    Map<String, String>? modelPreferences,
    bool? floatingCaption,
    bool? boldText,
    Color? customBackground,
    Color? customText,
  }) {
    return AppSettings(
      fontScale: fontScale ?? this.fontScale,
      colorMode: colorMode ?? this.colorMode,
      modelPreferences: modelPreferences ?? this.modelPreferences,
      floatingCaption: floatingCaption ?? this.floatingCaption,
      boldText: boldText ?? this.boldText,
      customBackground: customBackground ?? this.customBackground,
      customText: customText ?? this.customText,
    );
  }
}

/// 在 main() 中用已初始化的实例覆盖。
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider 未初始化'),
);

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  static const _fontKey = 'settings.fontScale';
  static const _colorKey = 'settings.colorMode';
  static const _modelsKey = 'settings.modelPreferences';
  static const _floatingKey = 'settings.floatingCaption';
  static const _boldKey = 'settings.boldText';
  static const _customBackgroundKey = 'settings.customBackground';
  static const _customTextKey = 'settings.customText';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      fontScale: _byName(FontScale.values, prefs.getString(_fontKey)) ??
          FontScale.large,
      colorMode: _byName(ColorMode.values, prefs.getString(_colorKey)) ??
          ColorMode.yellowOnBlack,
      modelPreferences: _decodeMap(prefs.getString(_modelsKey)),
      floatingCaption: prefs.getBool(_floatingKey) ?? false,
      boldText: prefs.getBool(_boldKey) ?? false,
      customBackground: _color(prefs.getInt(_customBackgroundKey)) ??
          const AppSettings().customBackground,
      customText: _color(prefs.getInt(_customTextKey)) ??
          const AppSettings().customText,
    );
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

  /// [modelId] 为 null 表示该语言恢复“自动”。
  void setModelPreference(String language, String? modelId) {
    final prefs = {...state.modelPreferences};
    if (modelId == null) {
      prefs.remove(language);
    } else {
      prefs[language] = modelId;
    }
    state = state.copyWith(modelPreferences: prefs);
    _prefs.setString(_modelsKey, jsonEncode(prefs));
  }

  static T? _byName<T extends Enum>(List<T> values, String? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  static Map<String, String> _decodeMap(String? raw) {
    if (raw == null) return const {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).cast<String, String>();
    } on FormatException {
      return const {};
    }
  }
}
