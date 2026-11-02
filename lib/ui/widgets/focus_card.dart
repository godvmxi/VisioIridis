import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model_store/model_repository.dart';
import '../../state/asr_controller.dart';
import '../../state/model_providers.dart';
import '../../state/settings.dart';
import '../app_colors.dart';
import '../model_preparer.dart';

/// 固定的最新转换卡片（PRD 4.3）。
class FocusCard extends ConsumerWidget {
  const FocusCard({super.key});

  static const _outDuration = Duration(milliseconds: 250);
  static const _inDuration = Duration(milliseconds: 100);
  static const _inStart = 250 / 350;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isListening =
        ref.watch(asrControllerProvider.select((s) => s.isListening));
    final text =
        ref.watch(asrControllerProvider.select((s) => s.currentPendingText));
    final segment =
        ref.watch(asrControllerProvider.select((s) => s.pendingSegment));
    final prep = ref.watch(modelPrepProvider);
    final isLoading =
        ref.watch(asrControllerProvider.select((s) => s.isLoading));
    final fontScale = ref.watch(settingsProvider.select((s) => s.fontScale));
    final palette = AppPalette.of(context);
    final currentKey = ValueKey(segment);

    if (prep != null) return _CardFrame(child: _PrepView(state: prep));

    return Container(
      width: double.infinity,
      // 约容纳 3 行最新字幕，随字号缩放。
      constraints: BoxConstraints(
        minHeight: 120,
        maxHeight: fontScale.focus * 1.35 * 3 + 24,
      ),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        border: Border.all(color: palette.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 14,
            top: 14,
            child: _StatusDot(active: isListening),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 12, 16, 12),
            child: AnimatedSwitcher(
              // 旧句子先用 250ms 上移淡出，新内容在其后 100ms 内淡入，两者不重叠。
              duration: _outDuration + _inDuration,
              reverseDuration: _outDuration,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topLeft,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, animation) {
                if (child.key == currentKey) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: const Interval(_inStart, 1),
                    ),
                    child: child,
                  );
                }
                return SlideTransition(
                  position: Tween(
                    begin: const Offset(0, -1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: KeyedSubtree(
                key: currentKey,
                child: _CardText(
                  text: text,
                  placeholder: isLoading ? '正在加载识别模型...' : '等待语音输入...',
                  fontSize: fontScale.focus,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        border: Border.all(color: palette.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// 模型准备进度（PRD 4.5.5）。
class _PrepView extends ConsumerWidget {
  const _PrepView({required this.state});

  final PrepState state;

  static String _title(PrepState state) {
    final progress = state.progress;
    return switch (progress?.phase) {
      null => '正在准备模型...',
      PrepPhase.copying => '正在从保存目录恢复模型...',
      PrepPhase.downloading => '正在下载 ${state.modelName}',
      PrepPhase.verifying => '正在校验模型文件...',
      PrepPhase.saving => '正在保存到公共目录...',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = state.progress;
    final known = progress != null && progress.total > 0;
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _title(state),
          style: TextStyle(fontSize: 20, color: palette.focusText),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: known ? progress.done / progress.total : null,
          color: AppColors.listening,
          backgroundColor: palette.cardBorder,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                [
                  if (progress != null) progress.fileName,
                  if (known)
                    '${formatMegabytes(progress.done)} / ${formatMegabytes(progress.total)}',
                ].join('  '),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, color: palette.historyText),
              ),
            ),
            TextButton(
              onPressed: () => ref.read(modelPrepProvider.notifier).cancel(),
              child: const Text('取消', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ],
    );
  }
}

class _CardText extends StatelessWidget {
  const _CardText({
    required this.text,
    required this.placeholder,
    required this.fontSize,
  });

  final String text;
  final String placeholder;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    if (text.isEmpty) {
      return Text(
        placeholder,
        style: TextStyle(
            fontSize: fontSize * 0.75, color: palette.idle, height: 1.35),
      );
    }
    // reverse: 文字超出卡片高度时始终显示最后几行。
    return SingleChildScrollView(
      reverse: true,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.35,
          fontWeight: FontWeight.bold,
          // 临时结果 70% 不透明度，与定稿区分（PRD 4.3）。
          color: palette.focusText.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// 8dp 状态指示点：拾音中绿色呼吸，暂停时静态灰色。
class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.active});

  final bool active;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _sync();
  }

  void _sync() {
    if (widget.active) {
      _breath.repeat(reverse: true);
    } else {
      _breath
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.active
          ? Tween(begin: 0.35, end: 1.0).animate(_breath)
          : const AlwaysStoppedAnimation(1),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.active
              ? AppColors.listening
              : AppPalette.of(context).idle,
        ),
      ),
    );
  }
}
