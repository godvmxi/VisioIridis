import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../asr/asr_engine.dart';
import '../l10n/l10n.dart';
import '../model_store/model_config.dart';
import '../model_store/model_selector.dart';
import '../platform/background_platform.dart';
import '../state/model_providers.dart';
import '../state/settings.dart';
import 'app_colors.dart';
import 'widgets/history_list.dart';

/// 设置页：界面语言、字体大小、配色模式、识别模型（PRD 4.6）。
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
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        // ignore: deprecated_member_use
        cacheExtent: 5000,
        children: [
          _Section(
            title: l10n.interfaceLanguage,
            icon: Icons.translate_rounded,
            children: [
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
            ],
          ),
          _Section(
            title: l10n.fontSize,
            icon: Icons.format_size_rounded,
            children: [
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
            ],
          ),
          _Section(
            title: l10n.colorMode,
            icon: Icons.palette_outlined,
            children: [
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
            ],
          ),
          _Section(
            title: l10n.forceSplit,
            icon: Icons.content_cut_rounded,
            children: [
              Text(
                l10n.forceSplitHint,
                style: TextStyle(color: palette.historyText, height: 1.5),
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 0, label: Text(l10n.forceSplitOff)),
                  const ButtonSegment(value: 1, label: Text('1s')),
                  const ButtonSegment(value: 2, label: Text('2s')),
                  const ButtonSegment(value: 3, label: Text('3s')),
                  const ButtonSegment(value: 5, label: Text('5s')),
                ],
                selected: {settings.forceSplitSeconds},
                onSelectionChanged: (s) =>
                    controller.setForceSplitSeconds(s.single),
                showSelectedIcon: false,
              ),
            ],
          ),
          // 平台不支持画在其他 App 之上时整块隐藏：留一个点下去必然失败的
          // 开关，对用户是误导（PRD 4.7）。
          if (platform.supportsOverlay)
            _Section(
              title: l10n.floatingWindow,
              icon: Icons.picture_in_picture_alt_outlined,
              children: const [_FloatingCaptionSection()],
            ),
          _Section(
            title: l10n.recognitionModel,
            icon: Icons.graphic_eq_rounded,
            children: [
              Text(
                l10n.recognitionModelHint,
                style: TextStyle(color: palette.historyText, height: 1.5),
              ),
              const SizedBox(height: 8),
              switch (config) {
                AsyncData(:final value) => _ModelChooser(
                  config: value,
                  language: settings.asrLanguage,
                  model: resolveModel(
                    value,
                    settings.asrLanguage,
                    settings.asrModel,
                  ),
                  onChanged: controller.setAsrModel,
                ),
                AsyncError(:final error) => Text(
                  l10n.modelConfigLoadFailed('$error'),
                  style: TextStyle(color: palette.historyText),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ],
          ),
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

/// M3 分组卡片：带图标的标题 + 该分组的设置项。
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(icon, size: 22, color: palette.focusText),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: palette.focusText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...children,
            ],
          ),
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

/// 选择识别模型（PRD 4.6）：依次单选语种、方言、模型。只有一种方言的语种不显示方言。
/// 点选模型后才保存；只改语种或方言而未点选模型时，当前模型保持不变。
class _ModelChooser extends StatefulWidget {
  const _ModelChooser({
    required this.config,
    required this.language,
    required this.model,
    required this.onChanged,
  });

  final ModelConfig config;

  /// 已保存的方言（语言 id）与据此选出的模型。
  final String language;
  final AsrModelDef? model;
  final void Function(String language, String modelId) onChanged;

  @override
  State<_ModelChooser> createState() => _ModelChooserState();
}

class _ModelChooserState extends State<_ModelChooser> {
  /// 正在浏览的语种与方言；为 null 时显示已保存的选择。
  String? _group;
  String? _language;

  ModelConfig get _config => widget.config;

  String _groupOf(String language) =>
      _config.languageById(language)?.group ?? language;

  static int _scoreOf(AsrModelDef model, String language) =>
      model.languages.firstWhere((s) => s.lang == language).score;

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

  /// 已保存的选择，如“中文 › 粤语 › SenseVoice Small”；只有一种方言的语种省略方言。
  String _savedPath(AppLocalizations l10n, AsrModelDef model) {
    final saved = _config.languageById(widget.language);
    final groupId = _groupOf(widget.language);
    final group = _config.groups.where((g) => g.id == groupId).firstOrNull;
    return [
      if (saved != null) ...[
        l10n.languageGroupName(groupId, group?.name),
        if (_config.languagesIn(groupId).length > 1)
          l10n.languageName(saved.id, saved.name),
      ],
      model.name,
    ].join(' › ');
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    String nameOf(LanguageDef l) => l10n.languageName(l.id, l.name);

    final groups = _config.groups;
    if (groups.isEmpty) return const SizedBox.shrink();
    final group = groups.firstWhere(
      (g) => g.id == (_group ?? _groupOf(widget.language)),
      orElse: () => groups.first,
    );
    final dialects = _config.languagesIn(group.id);
    final language = dialects.firstWhere(
      (l) => l.id == (_language ?? widget.language),
      orElse: () => dialects.first,
    );
    final models = modelsFor(_config, language.id);
    // 只有正在浏览的就是已保存的方言时，才标出当前模型。
    final selected = language.id == widget.language ? widget.model?.id : null;
    final current = widget.model;

    final titleStyle = TextStyle(fontSize: 17, color: palette.focusText);
    final subtitleStyle = TextStyle(color: palette.historyText, height: 1.4);

    Widget dropdown({
      required String label,
      required String value,
      required List<DropdownMenuItem<String>> items,
      required ValueChanged<String?> onChanged,
    }) => Row(
      children: [
        SizedBox(width: 72, child: Text(label, style: titleStyle)),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: palette.cardSurface,
            style: TextStyle(fontSize: 17, color: palette.focusText),
            iconEnabledColor: palette.focusText,
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (current != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.currentSelection(_savedPath(l10n, current)),
              style: TextStyle(fontSize: 15, color: palette.focusText),
            ),
          ),
        dropdown(
          label: l10n.languageGroup,
          value: group.id,
          items: [
            for (final g in groups)
              DropdownMenuItem(
                value: g.id,
                child: Text(l10n.languageGroupName(g.id, g.name)),
              ),
          ],
          onChanged: (id) {
            if (id == null) return;
            setState(() {
              _group = id;
              // 回到已保存的语种时显示已保存的方言，否则显示该语种的第一种方言。
              _language = id == _groupOf(widget.language)
                  ? widget.language
                  : _config.languagesIn(id).first.id;
            });
          },
        ),
        if (dialects.length > 1)
          dropdown(
            label: l10n.dialect,
            value: language.id,
            items: [
              for (final l in dialects)
                DropdownMenuItem(value: l.id, child: Text(nameOf(l))),
            ],
            onChanged: (id) => setState(() {
              _group = group.id;
              _language = id;
            }),
          ),
        const SizedBox(height: 12),
        Text(
          l10n.chooseModelFor(nameOf(language)),
          style: TextStyle(fontSize: 15, color: palette.historyText),
        ),
        if (models.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.noModelAvailable, style: subtitleStyle),
          )
        else
          RadioGroup<String>(
            groupValue: selected,
            onChanged: (id) {
              if (id != null) widget.onChanged(language.id, id);
            },
            child: Column(
              children: [
                for (final model in models)
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
