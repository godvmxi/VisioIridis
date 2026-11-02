import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../asr/asr_language.dart';
import '../../state/asr_controller.dart';
import '../app_colors.dart';

/// 顶部控制栏：三个语言胶囊 + 清屏按钮（PRD 4.1）。
class LanguageBar extends ConsumerStatefulWidget {
  const LanguageBar({super.key});

  @override
  ConsumerState<LanguageBar> createState() => _LanguageBarState();
}

class _LanguageBarState extends ConsumerState<LanguageBar>
    with SingleTickerProviderStateMixin {
  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _onToggle(AsrLanguage language) {
    final accepted =
        ref.read(asrControllerProvider.notifier).toggleLanguage(language);
    if (accepted) return;
    _shake.forward(from: 0);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('至少保留一种识别语言')));
  }

  Future<void> _confirmClear() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.cardSurface,
      builder: (context) => const _ClearConfirmSheet(),
    );
    if (confirmed == true) {
      ref.read(asrControllerProvider.notifier).clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled =
        ref.watch(asrControllerProvider.select((s) => s.enabledLanguages));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _shake,
              builder: (context, child) {
                final t = _shake.value;
                final dx = math.sin(t * math.pi * 6) * 8 * (1 - t);
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final language in AsrLanguage.values)
                    FilterChip(
                      label: Text(language.label),
                      selected: enabled.contains(language),
                      onSelected: (_) => _onToggle(language),
                      shape: const StadiumBorder(),
                      labelStyle: const TextStyle(fontSize: 16),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: '清屏',
            iconSize: 28,
            color: AppColors.historyText,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _confirmClear,
          ),
        ],
      ),
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
            const Text(
              '确认清空所有历史字幕记录？',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: Colors.white),
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
