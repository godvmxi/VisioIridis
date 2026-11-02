import 'package:flutter/material.dart';

import '../state/settings.dart';

/// 与配色模式无关的固定颜色（PRD 4.4）。
class AppColors {
  AppColors._();

  static const listening = Color(0xFF10B981);
  static const stop = Color(0xFFDC2626);
}

/// 随配色模式变化的颜色，通过 ThemeExtension 提供给各组件（PRD 4.6）。
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.historyText,
    required this.timestamp,
    required this.cardSurface,
    required this.cardBorder,
    required this.focusText,
    required this.idle,
  });

  /// PRD 第 4 章的默认配色。
  static const yellowOnBlack = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF000000),
    historyText: Color(0xFFB0B0B0),
    timestamp: Color(0xFF666666),
    cardSurface: Color(0xFF1E1E1E),
    cardBorder: Color(0xFF333333),
    focusText: Color(0xFFFFE600),
    idle: Color(0xFF666666),
  );

  static const whiteOnBlack = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF000000),
    historyText: Color(0xFFB0B0B0),
    timestamp: Color(0xFF666666),
    cardSurface: Color(0xFF1E1E1E),
    cardBorder: Color(0xFF333333),
    focusText: Color(0xFFFFFFFF),
    idle: Color(0xFF666666),
  );

  static const blackOnWhite = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFFFFFFF),
    historyText: Color(0xFF424242),
    timestamp: Color(0xFF8A8A8A),
    cardSurface: Color(0xFFF2F2F2),
    cardBorder: Color(0xFFD0D0D0),
    focusText: Color(0xFF000000),
    idle: Color(0xFF9E9E9E),
  );

  static AppPalette forMode(ColorMode mode) => switch (mode) {
        ColorMode.yellowOnBlack => yellowOnBlack,
        ColorMode.whiteOnBlack => whiteOnBlack,
        ColorMode.blackOnWhite => blackOnWhite,
      };

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? yellowOnBlack;

  final Brightness brightness;
  final Color background;
  final Color historyText;
  final Color timestamp;
  final Color cardSurface;
  final Color cardBorder;
  final Color focusText;
  final Color idle;

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) =>
      other == null || t < 0.5 ? this : other;
}
