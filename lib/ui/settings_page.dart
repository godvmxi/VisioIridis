import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../asr/asr_language.dart';
import '../l10n/l10n.dart';
import '../model_store/model_config.dart';
import '../model_store/model_selector.dart';
import '../platform/background_platform.dart';
import '../state/model_providers.dart';
import '../state/settings.dart';
import 'app_colors.dart';

/// 设置页：界面语言、字体大小、配色模式、按语言选择识别模型（PRD 4.6）。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final platform = ref.watch(backgroundPlatformProvider);
    final config = ref.watch(modelConfigProvider);
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: palette.background,
        foregroundColor: palette.focusText,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _SectionTitle(l10n.interfaceLanguage),
          DropdownButton<AppLanguage>(
            value: settings.appLanguage,
            isExpanded: true,
            dropdownColor: palette.cardSurface,
            style: TextStyle(fontSize: 17, color: palette.focusText),
            iconEnabledColor: palette.focusText,
            items: [
              for (final language in AppLanguage.values)
                DropdownMenuItem(
                  value: language,
                  child: Text(l10n.appLanguageName(language)),
                ),
            ],
            onChanged: (language) {
              if (language != null) controller.setAppLanguage(language);
            },
          ),
          const SizedBox(height: 24),
          _SectionTitle(l10n.fontSize),
          SegmentedButton<FontScale>(
            segments: [
              for (final scale in FontScale.values)
                ButtonSegment(
                  value: scale,
                  label: Text(l10n.fontScaleName(scale)),
                ),
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
              l10n.bold,
              style: TextStyle(fontSize: 17, color: palette.focusText),
            ),
            subtitle: Text(
              l10n.boldHint,
              style: TextStyle(color: palette.historyText),
            ),
          ),
          const SizedBox(height: 4),
          _Preview(settings: settings),
          const SizedBox(height: 24),
          _SectionTitle(l10n.colorMode),
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
                      l10n.colorModeName(mode),
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
          // 平台不支持画在其他 App 之上时整块隐藏：留一个点下去必然失败的
          // 开关，对用户是误导（PRD 4.7）。
          if (platform.supportsOverlay) ...[
            const SizedBox(height: 24),
            _SectionTitle(l10n.floatingWindow),
            const _FloatingCaptionSection(),
          ],
          const SizedBox(height: 24),
          _SectionTitle(l10n.recognitionModel),
          Text(
            l10n.recognitionModelHint,
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
              l10n.modelConfigLoadFailed('$error'),
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
    final l10n = AppLocalizations.of(context);
    if (!await platform.canShowOverlay()) {
      if (!context.mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.overlayPermissionTitle),
          content: Text(
            l10n.overlayPermissionBody,
            style: const TextStyle(fontSize: 17, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.goEnable),
            ),
          ],
        ),
      );
      if (go != true) return;
      await platform.openOverlaySettings();
      if (!await platform.canShowOverlay()) {
        if (context.mounted) _toast(context, l10n.overlayPermissionDenied);
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
        AppLocalizations.of(context).showFloatingWindow,
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
    final l10n = AppLocalizations.of(context);
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
                  text: l10n.previewHistory,
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
              l10n.previewFocus,
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
        AppLocalizations.of(context).swatchSample,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: palette.focusText,
        ),
      ),
    );
  }
}

/// 按语言选择识别模型（PRD 4.6）：先在下拉框中选语言，下方列出支持该语言的候选模型及其
/// 支持的全部语言打分，点击模型即选中。
class _ModelPreferences extends StatefulWidget {
  const _ModelPreferences({
    required this.config,
    required this.preferences,
    required this.onChanged,
  });

  final ModelConfig config;
  final Map<String, String> preferences;
  final void Function(String language, String? modelId) onChanged;

  @override
  State<_ModelPreferences> createState() => _ModelPreferencesState();
}

class _ModelPreferencesState extends State<_ModelPreferences> {
  static const _autoValue = '';

  String? _language;

  ModelConfig get _config => widget.config;

  /// 只列出顶部栏可以勾选的语言。
  List<LanguageDef> get _languages {
    final selectable = AsrLanguage.values.map((l) => l.code).toSet();
    return [..._config.languages]
      ..retainWhere((l) => selectable.contains(l.id))
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<AsrModelDef> _modelsFor(String language) => [
    for (final m in _config.asrModels)
      if (m.languages.any((s) => s.lang == language)) m,
  ]..sort((a, b) => _scoreOf(b, language).compareTo(_scoreOf(a, language)));

  static int _scoreOf(AsrModelDef model, String language) =>
      model.languages.firstWhere((s) => s.lang == language).score;

  /// 配置更新后已不存在或不再支持该语言的模型视为“自动”。
  String? _validPreference(String language) {
    final id = widget.preferences[language];
    return _modelsFor(language).any((m) => m.id == id) ? id : null;
  }

  /// 模型支持的全部语言及打分，按语言顺序排列。
  String _scoresOf(AppLocalizations l10n, AsrModelDef model) {
    final names = {for (final l in _config.languages) l.id: l};
    final sorted = [...model.languages]
      ..sort(
        (a, b) => (names[a.lang]?.order ?? 999).compareTo(
          names[b.lang]?.order ?? 999,
        ),
      );
    return [
      for (final s in sorted)
        '${l10n.languageName(s.lang, names[s.lang]?.name)} ${s.score}',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    String nameOf(LanguageDef l) => l10n.languageName(l.id, l.name);
    final languages = _languages;
    if (languages.isEmpty) return const SizedBox.shrink();
    final language = languages.firstWhere(
      (l) => l.id == _language,
      orElse: () => languages.first,
    );
    final auto = selectModel(_config, {language.id});
    final titleStyle = TextStyle(fontSize: 17, color: palette.focusText);
    final subtitleStyle = TextStyle(color: palette.historyText, height: 1.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.language, style: titleStyle),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: language.id,
              dropdownColor: palette.cardSurface,
              style: TextStyle(fontSize: 17, color: palette.focusText),
              iconEnabledColor: palette.focusText,
              items: [
                for (final l in languages)
                  DropdownMenuItem(value: l.id, child: Text(nameOf(l))),
              ],
              onChanged: (id) => setState(() => _language = id),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.chooseModelFor(nameOf(language)),
          style: TextStyle(fontSize: 15, color: palette.historyText),
        ),
        RadioGroup<String>(
          groupValue: _validPreference(language.id) ?? _autoValue,
          onChanged: (v) {
            if (v == null) return;
            widget.onChanged(language.id, v == _autoValue ? null : v);
          },
          child: Column(
            children: [
              RadioListTile<String>(
                value: _autoValue,
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.auto, style: titleStyle),
                subtitle: Text(
                  auto == null
                      ? l10n.noModelAvailable
                      : l10n.autoPicks(auto.name, _scoreOf(auto, language.id)),
                  style: subtitleStyle,
                ),
              ),
              for (final model in _modelsFor(language.id))
                RadioListTile<String>(
                  value: model.id,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.modelScoreTitle(
                      model.name,
                      nameOf(language),
                      _scoreOf(model, language.id),
                    ),
                    style: titleStyle,
                  ),
                  subtitle: Text(
                    l10n.supports(_scoresOf(l10n, model)),
                    style: subtitleStyle,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
