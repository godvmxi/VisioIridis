import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/asr_controller.dart';
import '../app_colors.dart';

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
    final currentKey = ValueKey(segment);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120, maxHeight: 150),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        border: Border.all(color: AppColors.cardBorder),
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
                child: _CardText(text: text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardText extends StatelessWidget {
  const _CardText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const Text(
        '等待语音输入...',
        style: TextStyle(fontSize: 24, color: AppColors.idle, height: 1.35),
      );
    }
    // reverse: 文字超出卡片高度时始终显示最后几行。
    return SingleChildScrollView(
      reverse: true,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 30,
          height: 1.35,
          fontWeight: FontWeight.bold,
          // 临时结果 70% 不透明度，与定稿区分（PRD 4.3）。
          color: AppColors.focusText.withValues(alpha: 0.7),
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
          color: widget.active ? AppColors.listening : AppColors.idle,
        ),
      ),
    );
  }
}
