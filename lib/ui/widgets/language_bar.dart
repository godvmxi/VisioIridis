import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../asr/asr_engine.dart';
import '../../l10n/l10n.dart';
import '../../model_store/model_config.dart';
import '../../state/asr_controller.dart';
import '../../state/current_model.dart';
import '../../state/model_providers.dart';
import '../../state/settings.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(decodeLanguageProvider);
    final names = _languageNames(ref);
    final audioInput = ref.watch(
      asrControllerProvider.select((s) => s.audioInput),
    );
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          // 依次为：声音来源、识别语言、（右侧固定）清空记录与设置。
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 声音来源：麦克风或喇叭（系统播放的声音，PRD 4.8）。
                  Semantics(
                    label: l10n.soundSource,
                    child: SegmentedButton<AudioInput>(
                      segments: [
                        ButtonSegment(
                          value: AudioInput.microphone,
                          label: Text(l10n.microphone),
                        ),
                        ButtonSegment(
                          value: AudioInput.systemAudio,
                          label: Text(l10n.speaker),
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
                  // 识别语言：点击弹窗为当前模型选择自动或单一语言。
                  Semantics(
                    label: l10n.recognitionLanguage,
                    child: ActionChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            language == null
                                ? l10n.auto
                                : l10n.languageName(
                                    language,
                                    names[language]?.name,
                                  ),
                          ),
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
            tooltip: l10n.clearScreen,
            iconSize: 28,
            color: palette.historyText,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmClear(context, ref),
          ),
          IconButton(
            tooltip: l10n.settings,
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

/// 配置中的语言定义，按 id 查找名称与顺序。
Map<String, LanguageDef> _languageNames(WidgetRef ref) => {
  for (final l in ref.watch(modelConfigProvider).value?.languages ?? const [])
    l.id: l,
};

/// 识别语言弹窗（PRD 4.1）：为设置页选定的模型选择自动识别，或只识别其中一种语言。
class _LanguageDialog extends ConsumerWidget {
  const _LanguageDialog();

  static const _autoValue = '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(currentModelProvider);
    final selected = ref.watch(decodeLanguageProvider);
    final l10n = AppLocalizations.of(context);
    final names = _languageNames(ref);
    String nameOf(String id) => l10n.languageName(id, names[id]?.name);
    final languages =
        <String>[
          for (final s in model?.languages ?? const <LanguageSupport>[]) s.lang,
        ]..sort(
          (a, b) => (names[a]?.order ?? 999).compareTo(names[b]?.order ?? 999),
        );
    const titleStyle = TextStyle(fontSize: 18);

    return AlertDialog(
      title: Text(l10n.recognitionLanguage),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (model != null)
              Text(
                l10n.currentModel(model.name),
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: selected ?? _autoValue,
              onChanged: (v) {
                if (v == null) return;
                ref
                    .read(settingsProvider.notifier)
                    .setDecodeLanguage(v == _autoValue ? null : v);
              },
              child: Column(
                children: [
                  if (languages.length > 1)
                    RadioListTile<String>(
                      value: _autoValue,
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.auto, style: titleStyle),
                      subtitle: Text(
                        l10n.autoDetectLanguages(
                          languages.map(nameOf).join(l10n.listSeparator),
                        ),
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  for (final language in languages)
                    RadioListTile<String>(
                      value: language,
                      contentPadding: EdgeInsets.zero,
                      title: Text(nameOf(language), style: titleStyle),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.done),
        ),
      ],
    );
  }
}

class _ClearConfirmSheet extends StatelessWidget {
  const _ClearConfirmSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.clearConfirm,
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
              child: Text(
                l10n.clearConfirmButton,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
