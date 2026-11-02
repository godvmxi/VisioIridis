import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../asr/asr_language.dart';
import '../model_store/model_config.dart';
import '../model_store/model_selector.dart';
import '../platform/background_platform.dart';
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.boldText,
            onChanged: controller.setBoldText,
            title: Text(
              '粗体',
              style: TextStyle(fontSize: 17, color: palette.focusText),
            ),
            subtitle: Text(
              '历史记录、浮动字幕等所有字幕文字使用粗体',
              style: TextStyle(color: palette.historyText),
            ),
          ),
          const SizedBox(height: 4),
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
                    title: Text(
                      mode.label,
                      style: TextStyle(color: palette.focusText),
                    ),
                    secondary: _Swatch(
                      palette: AppPalette.forSettings(
                        settings.copyWith(colorMode: mode),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (settings.colorMode == ColorMode.custom)
            _CustomColors(settings: settings, controller: controller),
          const SizedBox(height: 24),
          const _SectionTitle('浮动窗'),
          const _FloatingCaptionSection(),
          const SizedBox(height: 24),
          const _SectionTitle('识别模型'),
          Text(
            '为每种语言指定使用的模型，打分为 10 分制；“自动”选择打分最高的模型。'
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
            AsyncError(:final error) => Text(
              '模型配置加载失败：$error',
              style: TextStyle(color: palette.historyText),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ],
      ),
    );
  }
}

/// 自定义配色：分别选择背景色与文字颜色（PRD 4.6）。
class _CustomColors extends StatelessWidget {
  const _CustomColors({required this.settings, required this.controller});

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
    final ratio = contrastRatio(settings.customBackground, settings.customText);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('背景色', style: TextStyle(fontSize: 16, color: palette.focusText)),
          const SizedBox(height: 8),
          _ColorGrid(
            colors: _backgrounds,
            selected: settings.customBackground,
            onSelected: controller.setCustomBackground,
            label: '背景',
          ),
          const SizedBox(height: 16),
          Text(
            '文字颜色',
            style: TextStyle(fontSize: 16, color: palette.focusText),
          ),
          const SizedBox(height: 8),
          _ColorGrid(
            colors: _texts,
            selected: settings.customText,
            onSelected: controller.setCustomText,
            label: '文字',
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
                      '对比度较低（${ratio.toStringAsFixed(1)}:1），字幕可能不易看清，'
                      '建议不低于 4.5:1',
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
  final String label;

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
            label: '$label颜色 ${i + 1}',
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

/// 浮动窗开关（PRD 4.7）：开启时检查悬浮窗权限。
class _FloatingCaptionSection extends ConsumerWidget {
  const _FloatingCaptionSection();

  Future<void> _onChanged(BuildContext context, WidgetRef ref, bool on) async {
    final controller = ref.read(settingsProvider.notifier);
    if (!on) {
      controller.setFloatingCaption(false);
      return;
    }
    final platform = ref.read(backgroundPlatformProvider);
    if (!await platform.canShowOverlay()) {
      if (!context.mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('需要悬浮窗权限'),
          content: const Text(
            '浮动字幕需要“显示在其他应用上层”权限。\n'
            '接下来请在系统设置中找到本应用并允许，然后返回。',
            style: TextStyle(fontSize: 17, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('去开启'),
            ),
          ],
        ),
      );
      if (go != true) return;
      await platform.openOverlaySettings();
      if (!await platform.canShowOverlay()) {
        if (context.mounted) _toast(context, '未获得悬浮窗权限，浮动窗未开启');
        return;
      }
    }
    controller.setFloatingCaption(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      settingsProvider.select((s) => s.floatingCaption),
    );
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: enabled,
      onChanged: (on) => _onChanged(context, ref, on),
      title: Text(
        '显示浮动窗',
        style: TextStyle(fontSize: 17, color: AppPalette.of(context).focusText),
      ),
    );
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
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
    final palette = AppPalette.forSettings(settings);
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
              style: TextStyle(
                fontSize: settings.fontScale.size,
                height: 1.5,
                fontWeight: settings.textWeight,
              ),
              children: [
                TextSpan(
                  text: '[10:30] ',
                  style: TextStyle(color: palette.timestamp),
                ),
                TextSpan(
                  text: '你好，请问今天几点开会？',
                  style: TextStyle(color: palette.historyText),
                ),
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
                fontSize: settings.fontScale.size,
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
            title: Text(
              language.name,
              style: TextStyle(fontSize: 17, color: palette.focusText),
            ),
            subtitle: Text(
              _currentLabel(language.id),
              style: TextStyle(color: palette.historyText),
            ),
            trailing: Icon(Icons.chevron_right, color: palette.historyText),
            onTap: () => _choose(context, language),
          ),
      ],
    );
  }

  List<AsrModelDef> _modelsFor(String language) => [
    for (final m in config.asrModels)
      if (m.languages.any((s) => s.lang == language)) m,
  ]..sort((a, b) => _scoreOf(b, language).compareTo(_scoreOf(a, language)));

  static int _scoreOf(AsrModelDef model, String language) =>
      model.languages.firstWhere((s) => s.lang == language).score;

  /// 配置更新后已不存在或不再支持该语言的模型视为“自动”。
  String? _validPreference(String language) {
    final id = preferences[language];
    return _modelsFor(language).any((m) => m.id == id) ? id : null;
  }

  String _currentLabel(String language) {
    final id = _validPreference(language);
    if (id == null) {
      final auto = selectModel(config, {language});
      return auto == null
          ? '自动（无可用模型）'
          : '自动：${auto.name}  ${_scoreOf(auto, language)} 分';
    }
    final model = config.asrModels.firstWhere((m) => m.id == id);
    return '${model.name}  ${_scoreOf(model, language)} 分';
  }

  /// 弹窗列出支持该语言的候选模型、该语言的打分，以及每个模型支持的全部语言打分。
  Future<void> _choose(BuildContext context, LanguageDef language) async {
    final names = {for (final l in config.languages) l.id: l};
    final candidates = _modelsFor(language.id);
    const autoValue = '';
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('为“${language.name}”选择模型'),
        children: [
          RadioGroup<String>(
            groupValue: _validPreference(language.id) ?? autoValue,
            onChanged: (v) => Navigator.pop(context, v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const RadioListTile<String>(
                  value: autoValue,
                  title: Text('自动'),
                  subtitle: Text('选打分最高的模型'),
                ),
                for (final model in candidates)
                  RadioListTile<String>(
                    value: model.id,
                    isThreeLine: true,
                    title: Text(
                      '${model.name}    ${language.name} '
                      '${_scoreOf(model, language.id)} 分',
                    ),
                    subtitle: Text(
                      [
                        for (final s
                            in [...model.languages]..sort(
                              (a, b) => (names[a.lang]?.order ?? 999).compareTo(
                                names[b.lang]?.order ?? 999,
                              ),
                            ))
                          '${names[s.lang]?.name ?? s.lang} ${s.score}',
                      ].join(' · '),
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked == null) return;
    onChanged(language.id, picked == autoValue ? null : picked);
  }
}
