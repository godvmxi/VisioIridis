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

  // 每种模式下所有文字使用同一颜色（PRD 4.6）；时间戳、占位提示等次要文字
  // 用同色降低不透明度区分层级。

  /// 默认配色。
  static const yellowOnBlack = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF000000),
    historyText: Color(0xFFFFE600),
    timestamp: Color(0x99FFE600),
    cardSurface: Color(0xFF1E1E1E),
    cardBorder: Color(0xFF333333),
    focusText: Color(0xFFFFE600),
    idle: Color(0x80FFE600),
  );

  static const whiteOnBlack = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF000000),
    historyText: Color(0xFFFFFFFF),
    timestamp: Color(0x99FFFFFF),
    cardSurface: Color(0xFF1E1E1E),
    cardBorder: Color(0xFF333333),
    focusText: Color(0xFFFFFFFF),
    idle: Color(0x80FFFFFF),
  );

  static const blackOnWhite = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFFFFFFF),
    historyText: Color(0xFF000000),
    timestamp: Color(0x99000000),
    cardSurface: Color(0xFFF2F2F2),
    cardBorder: Color(0xFFD0D0D0),
    focusText: Color(0xFF000000),
    idle: Color(0x80000000),
  );

  /// 由背景色与文字颜色推导完整配色，用于自定义模式。
  factory AppPalette.custom({required Color background, required Color text}) {
    final dark = background.computeLuminance() < 0.5;
    return AppPalette(
      brightness: dark ? Brightness.dark : Brightness.light,
      background: background,
      historyText: text,
      timestamp: text.withValues(alpha: 0.6),
      cardSurface: Color.lerp(background, text, 0.08)!,
      cardBorder: Color.lerp(background, text, 0.22)!,
      focusText: text,
      idle: text.withValues(alpha: 0.5),
    );
  }

  static AppPalette forSettings(AppSettings settings) =>
      switch (settings.colorMode) {
        ColorMode.yellowOnBlack => yellowOnBlack,
        ColorMode.whiteOnBlack => whiteOnBlack,
        ColorMode.blackOnWhite => blackOnWhite,
        ColorMode.custom => AppPalette.custom(
          background: settings.customBackground,
          text: settings.customText,
        ),
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

  /// 喇叭来源（左侧）的聊天气泡底色。
  Color get bubbleIncoming => cardSurface;

  /// 麦克风来源（右侧）的聊天气泡底色：比左侧略偏文字色，便于区分两侧。
  Color get bubbleOutgoing => Color.lerp(background, focusText, 0.16)!;

  /// 气泡旁圆形图标（类似聊天头像）的底色。
  Color get avatar => cardBorder;

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

/// WCAG 对比度（1–21）。正文建议不低于 4.5。
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}
