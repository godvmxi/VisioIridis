import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../state/settings.dart';
import '../app_colors.dart';

/// 自定义配色（[ColorMode.custom]）：分别选择背景色与文字颜色（PRD 4.6）。
/// 设置页与启动向导的外观步骤共用。
class CustomColorPicker extends StatelessWidget {
  const CustomColorPicker({
    super.key,
    required this.settings,
    required this.controller,
  });

  final AppSettings settings;
  final SettingsController controller;

  static const _backgrounds = [
    Color(0xFF000000),
    Color(0xFF1A1A1A),
    Color(0xFF0D1B2A),
    Color(0xFF002B36),
    Color(0xFF10291A),
    Color(0xFF2E0F0F),
    Color(0xFF2A1A3D),
    Color(0xFFFFFFFF),
    Color(0xFFFFF8E1),
    Color(0xFFE3F2FD),
    Color(0xFFE8F5E9),
    Color(0xFFFFEB3B),
  ];

  static const _texts = [
    Color(0xFFFFE600),
    Color(0xFFFFFFFF),
    Color(0xFF00E5FF),
    Color(0xFF76FF03),
    Color(0xFFFF9100),
    Color(0xFFFF4081),
    Color(0xFFB388FF),
    Color(0xFF000000),
    Color(0xFF0D47A1),
    Color(0xFF1B5E20),
    Color(0xFFB71C1C),
    Color(0xFF4A148C),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final ratio = contrastRatio(settings.customBackground, settings.customText);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.backgroundColor,
            style: TextStyle(fontSize: 16, color: palette.focusText),
          ),
          const SizedBox(height: 8),
          _ColorGrid(
            colors: _backgrounds,
            selected: settings.customBackground,
            onSelected: controller.setCustomBackground,
            label: l10n.backgroundSwatch,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.textColor,
            style: TextStyle(fontSize: 16, color: palette.focusText),
          ),
          const SizedBox(height: 8),
          _ColorGrid(
            colors: _texts,
            selected: settings.customText,
            onSelected: controller.setCustomText,
            label: l10n.textSwatch,
          ),
          if (ratio < 4.5)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFF9100),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.lowContrast(ratio.toStringAsFixed(1)),
                      style: TextStyle(color: palette.historyText, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ColorGrid extends StatelessWidget {
  const _ColorGrid({
    required this.colors,
    required this.selected,
    required this.onSelected,
    required this.label,
  });

  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelected;

  /// 色块的无障碍名称，参数为从 1 开始的序号。
  final String Function(int index) label;

  @override
  Widget build(BuildContext context) {
    final border = AppPalette.of(context).cardBorder;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final (i, color) in colors.indexed)
          Semantics(
            button: true,
            selected: color == selected,
            label: label(i + 1),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onSelected(color),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color == selected ? AppColors.listening : border,
                    width: color == selected ? 3 : 1,
                  ),
                ),
                child: color == selected
                    ? Icon(
                        Icons.check,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
