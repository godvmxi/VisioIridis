import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 字号档位（PRD 4.6）：最新卡片字号与历史区字号。
/// 枚举名会被持久化，调整档位时保留已有名称。
enum FontScale {
  standard('标准', focus: 28, history: 18),
  large('大', focus: 36, history: 22),
  huge('特大', focus: 44, history: 26),
  extraHuge('超大', focus: 52, history: 30),
  giant('巨大', focus: 60, history: 34);

  const FontScale(this.label, {required this.focus, required this.history});

  final String label;
  final double focus;
  final double history;
}

/// 配色模式（PRD 4.6）。
enum ColorMode {
  yellowOnBlack('黄字黑底'),
  whiteOnBlack('白字黑底'),
  blackOnWhite('黑字白底');

  const ColorMode(this.label);

  final String label;
}

class AppSettings {
  const AppSettings({
    this.fontScale = FontScale.large,
    this.colorMode = ColorMode.yellowOnBlack,
    this.modelPreferences = const {},
  });

  final FontScale fontScale;
  final ColorMode colorMode;

  /// 语言 id → 指定的模型 id；没有条目表示“自动”（按权重选择）。
  final Map<String, String> modelPreferences;

  AppSettings copyWith({
    FontScale? fontScale,
    ColorMode? colorMode,
    Map<String, String>? modelPreferences,
  }) {
    return AppSettings(
      fontScale: fontScale ?? this.fontScale,
      colorMode: colorMode ?? this.colorMode,
      modelPreferences: modelPreferences ?? this.modelPreferences,
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
    );
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
