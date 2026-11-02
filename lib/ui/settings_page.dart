import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../asr/asr_language.dart';
import '../model_store/model_config.dart';
import '../model_store/model_selector.dart';
import '../state/model_providers.dart';
import '../state/settings.dart';
import 'app_colors.dart';

/// 设置页：字体大小、配色模式、按语言选择识别模型（PRD 4.6）。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final config = ref.watch(modelConfigProvider);
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: palette.background,
        foregroundColor: palette.focusText,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const _SectionTitle('字体大小'),
          SegmentedButton<FontScale>(
            segments: [
              for (final scale in FontScale.values)
                ButtonSegment(value: scale, label: Text(scale.label)),
            ],
            selected: {settings.fontScale},
            onSelectionChanged: (s) => controller.setFontScale(s.single),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 12),
          _Preview(settings: settings),
          const SizedBox(height: 24),
          const _SectionTitle('配色模式'),
          RadioGroup<ColorMode>(
            groupValue: settings.colorMode,
            onChanged: (mode) {
              if (mode != null) controller.setColorMode(mode);
            },
            child: Column(
              children: [
                for (final mode in ColorMode.values)
                  RadioListTile<ColorMode>(
                    value: mode,
                    contentPadding: EdgeInsets.zero,
                    title: Text(mode.label,
                        style: TextStyle(color: palette.focusText)),
                    secondary: _Swatch(palette: AppPalette.forMode(mode)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('识别模型'),
          Text(
            '为每种语言指定使用的模型；“自动”按模型配置中的优先权重选择。'
            '修改后在下次点击“开始识别”时生效。',
            style: TextStyle(color: palette.historyText, height: 1.5),
          ),
          const SizedBox(height: 8),
          switch (config) {
            AsyncData(:final value) => _ModelPreferences(
                config: value,
                preferences: settings.modelPreferences,
                onChanged: controller.setModelPreference,
              ),
            AsyncError(:final error) => Text('模型配置加载失败：$error',
                style: TextStyle(color: palette.historyText)),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppPalette.of(context).focusText,
        ),
      ),
    );
  }
}

/// 按当前字号与配色预览历史区和最新卡片的效果。
class _Preview extends StatelessWidget {
  const _Preview({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.forMode(settings.colorMode);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.background,
        border: Border.all(color: palette.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: settings.fontScale.history, height: 1.5),
              children: [
                TextSpan(
                    text: '[10:30] ',
                    style: TextStyle(color: palette.timestamp)),
                TextSpan(
                    text: '你好，请问今天几点开会？',
                    style: TextStyle(color: palette.historyText)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.cardSurface,
              border: Border.all(color: palette.cardBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '下午三点见',
              style: TextStyle(
                fontSize: settings.fontScale.focus,
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

class _Swatch extends StatelessWidget {
  const _Swatch({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.background,
        border: Border.all(color: palette.cardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '字',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: palette.focusText,
        ),
      ),
    );
  }
}

class _ModelPreferences extends StatelessWidget {
  const _ModelPreferences({
    required this.config,
    required this.preferences,
    required this.onChanged,
  });

  final ModelConfig config;
  final Map<String, String> preferences;
  final void Function(String language, String? modelId) onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    // 只列出顶部栏可以勾选的语言。
    final selectable = AsrLanguage.values.map((l) => l.code).toSet();
    final languages = [...config.languages]
      ..retainWhere((l) => selectable.contains(l.id))
      ..sort((a, b) => a.order.compareTo(b.order));

    return Column(
      children: [
        for (final language in languages)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(language.name,
                style: TextStyle(fontSize: 17, color: palette.focusText)),
            trailing: DropdownButton<String?>(
              value: _validPreference(language.id),
              dropdownColor: palette.cardSurface,
              style: TextStyle(fontSize: 15, color: palette.focusText),
              onChanged: (id) => onChanged(language.id, id),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text('自动（${_autoModelName(language.id)}）'),
                ),
                for (final model in _modelsFor(language.id))
                  DropdownMenuItem(value: model.id, child: Text(model.name)),
              ],
            ),
          ),
      ],
    );
  }

  List<AsrModelDef> _modelsFor(String language) => [
        for (final m in config.asrModels)
          if (m.languages.any((s) => s.lang == language)) m,
      ];

  /// 配置更新后已不存在或不再支持该语言的模型视为“自动”。
  String? _validPreference(String language) {
    final id = preferences[language];
    return _modelsFor(language).any((m) => m.id == id) ? id : null;
  }

  String _autoModelName(String language) =>
      selectModel(config, {language})?.name ?? '无可用模型';
}
