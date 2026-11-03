import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Material 3 主题：组件形状、层级沿用 M3 规范，颜色全部取自当前配色模式，
/// 保证高对比度（PRD 4.6）。
ThemeData buildTheme(AppPalette palette) {
  // 让语言胶囊、开关、对话框等系统控件的文字与选中色也跟随配色模式。
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.listening,
        brightness: palette.brightness,
      ).copyWith(
        primary: palette.focusText,
        onPrimary: palette.background,
        surface: palette.background,
        onSurface: palette.focusText,
        onSurfaceVariant: palette.historyText,
        secondaryContainer: palette.cardBorder,
        onSecondaryContainer: palette.focusText,
        surfaceContainerLowest: palette.background,
        surfaceContainerLow: palette.cardSurface,
        surfaceContainer: palette.cardSurface,
        surfaceContainerHigh: palette.cardSurface,
        surfaceContainerHighest: palette.cardSurface,
        outline: palette.cardBorder,
        outlineVariant: palette.cardBorder,
        // 关闭 M3 的色调叠加，表面颜色保持配色模式给定的值。
        surfaceTint: Colors.transparent,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.background,
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.focusText,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: palette.focusText,
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.cardSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: palette.historyText,
      textColor: palette.focusText,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStatePropertyAll(BorderSide(color: palette.cardBorder)),
      ),
    ),
    filledButtonTheme: const FilledButtonThemeData(
      style: ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.cardSurface,
      side: BorderSide(color: palette.cardBorder),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.cardSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.cardSurface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: palette.idle,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerTheme: DividerThemeData(color: palette.cardBorder, space: 1),
    extensions: [palette],
  );
}
