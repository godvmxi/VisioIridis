import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seevoice/state/settings.dart';
import 'package:seevoice/ui/app_colors.dart';

void main() {
  test('contrastRatio follows WCAG', () {
    expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(contrastRatio(Colors.white, Colors.white), closeTo(1, 0.01));
  });

  test('custom palette derives from background and text', () {
    final dark = AppPalette.custom(
      background: const Color(0xFF0D1B2A),
      text: const Color(0xFF00E5FF),
    );
    expect(dark.brightness, Brightness.dark);
    expect(dark.historyText, const Color(0xFF00E5FF));
    expect(dark.timestamp.a, closeTo(0.6, 0.01));

    final light = AppPalette.custom(
      background: Colors.white,
      text: const Color(0xFF0D47A1),
    );
    expect(light.brightness, Brightness.light);
  });

  test('forSettings uses custom colors only in custom mode', () {
    const settings = AppSettings(
      colorMode: ColorMode.custom,
      customBackground: Color(0xFFFFF8E1),
      customText: Color(0xFFB71C1C),
    );
    expect(AppPalette.forSettings(settings).focusText, const Color(0xFFB71C1C));
    expect(
      AppPalette.forSettings(
        settings.copyWith(colorMode: ColorMode.yellowOnBlack),
      ).focusText,
      AppPalette.yellowOnBlack.focusText,
    );
  });
}
