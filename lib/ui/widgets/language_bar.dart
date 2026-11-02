import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../asr/asr_engine.dart';
import '../../asr/asr_language.dart';
import '../../state/asr_controller.dart';
import '../../state/current_model.dart';
import '../../state/model_providers.dart';
import '../app_colors.dart';
import '../settings_page.dart';

/// 顶部控制栏（PRD 4.1）：声音来源、主语言、清空记录、设置。
class LanguageBar extends ConsumerWidget {
  const LanguageBar({super.key});

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppPalette.of(context).cardSurface,
      builder: (context) => const _ClearConfirmSheet(),
    );
    if (confirmed == true) {
      ref.read(asrControllerProvider.notifier).clearHistory();
    }
  }

  /// 主语言按钮的文字：第一个勾选的主语言，勾选多种时附上其余数量。
  static String _summary(Set<AsrLanguage> enabled) {
    final ordered = [
      for (final l in AsrLanguage.values)
        if (enabled.contains(l)) l,
    ];
    final extra = ordered.length - 1;
    return extra > 0 ? '${ordered.first.label} +$extra' : ordered.first.label;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      asrControllerProvider.select((s) => s.enabledLanguages),
    );
    final audioInput = ref.watch(
      asrControllerProvider.select((s) => s.audioInput),
    );
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          // 依次为：声音来源、主语言、（右侧固定）清空记录与设置。
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 声音来源：麦克风或喇叭（系统播放的声音，PRD 4.8）。
                  Semantics(
                    label: '声音来源',
                    child: SegmentedButton<AudioInput>(
                      segments: const [
                        ButtonSegment(
                          value: AudioInput.microphone,
                          label: Text('麦克风'),
                        ),
                        ButtonSegment(
                          value: AudioInput.systemAudio,
                          label: Text('喇叭'),
                        ),
                      ],
                      selected: {audioInput},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => ref
                          .read(asrControllerProvider.notifier)
                          .setAudioInput(s.single),
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: WidgetStatePropertyAll(
                          TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 主语言：点击弹窗选择语言并查看当前模型支持的全部语言。
                  Semantics(
                    label: '识别语言',
                    child: ActionChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_summary(enabled)),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            color: palette.focusText,
                          ),
                        ],
                      ),
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const _LanguageDialog(),
                      ),
                      shape: const StadiumBorder(),
                      visualDensity: VisualDensity.compact,
                      labelPadding: const EdgeInsets.only(left: 4),
                      labelStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: '清屏',
            iconSize: 28,
            color: palette.historyText,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmClear(context, ref),
          ),
          IconButton(
            tooltip: '设置',
            iconSize: 28,
            color: palette.historyText,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
    );
  }
}

/// 识别语言弹窗（PRD 4.1）：勾选主语言，并列出当前模型支持的全部语言。
class _LanguageDialog extends ConsumerStatefulWidget {
  const _LanguageDialog();

  @override
  ConsumerState<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends ConsumerState<_LanguageDialog> {
  bool _rejected = false;

  void _toggle(AsrLanguage language) {
    final accepted = ref
        .read(asrControllerProvider.notifier)
        .toggleLanguage(language);
    setState(() => _rejected = !accepted);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(
      asrControllerProvider.select((s) => s.enabledLanguages),
    );
    final model = ref.watch(currentModelProvider);
    final languages = ref.watch(modelConfigProvider).value?.languages ?? [];
    final names = {for (final l in languages) l.id: l};
    final mainCodes = AsrLanguage.values.map((l) => l.code).toSet();
    final others =
        [
          for (final s in model?.languages ?? const [])
            if (!mainCodes.contains(s.lang)) s.lang,
        ]..sort(
          (a, b) => (names[a]?.order ?? 999).compareTo(names[b]?.order ?? 999),
        );

    return AlertDialog(
      title: const Text('识别语言'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (model != null)
              Text('当前模型：${model.name}', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            for (final language in AsrLanguage.values)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: enabled.contains(language),
                onChanged: (_) => _toggle(language),
                title: Text(
                  language.label,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            if (_rejected)
              const Text(
                '至少保留一种识别语言',
                style: TextStyle(color: Color(0xFFFF5252), fontSize: 14),
              ),
            if (others.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('还可自动识别', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                others.map((code) => names[code]?.name ?? code).join('、'),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 4),
              const Text(
                '勾选多种语言（自动识别）时可识别这些语言。',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('完成'),
        ),
      ],
    );
  }
}

class _ClearConfirmSheet extends StatelessWidget {
  const _ClearConfirmSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '确认清空所有历史字幕记录？',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: AppPalette.of(context).focusText,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.stop,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认清空', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
