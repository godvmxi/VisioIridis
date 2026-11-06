import 'package:flutter/material.dart';

import '../../asr/asr_engine.dart';
import '../../l10n/l10n.dart';
import '../../state/settings.dart';
import '../app_colors.dart';
import 'history_list.dart';

/// 按当前字号与配色预览历史区和最新卡片的效果，采用与主界面一致的气泡样式。
/// 设置页与启动向导的外观步骤共用。
class CaptionPreview extends StatelessWidget {
  const CaptionPreview({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.forSettings(settings);
    final l10n = AppLocalizations.of(context);
    final size = settings.fontScale.size;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.background,
        border: Border.all(color: palette.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChatBubble(
            text: l10n.previewHistory,
            source: AudioInput.systemAudio,
            palette: palette,
            fontSize: size,
            weight: settings.textWeight,
          ),
          ChatBubble(
            text: l10n.previewFocus,
            source: AudioInput.microphone,
            palette: palette,
            fontSize: size,
            weight: settings.textWeight,
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.cardSurface,
              border: Border.all(color: palette.cardBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              l10n.previewFocus,
              style: TextStyle(
                fontSize: size,
                height: 1.35,
                fontWeight: FontWeight.bold,
                color: palette.focusText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
