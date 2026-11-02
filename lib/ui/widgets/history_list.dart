import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/subtitle_item.dart';
import '../../state/asr_controller.dart';
import '../../state/settings.dart';
import '../app_colors.dart';

/// 历史记录区：自动跟随 + 手动浏览锁定 + 回到最新（PRD 4.2）。
class HistoryList extends ConsumerStatefulWidget {
  const HistoryList({super.key});

  @override
  ConsumerState<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends ConsumerState<HistoryList> {
  /// 距底部小于该值视为“已在底部”，恢复自动跟随。
  static const _bottomThreshold = 24.0;

  final _scroll = ScrollController();
  bool _autoFollow = true;
  int _unread = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _resumeFollow() {
    setState(() {
      _autoFollow = true;
      _unread = 0;
    });
    _scrollToBottom();
  }

  bool _onScroll(ScrollNotification notification) {
    // 用户向上拖拽（内容向列表起点方向移动）即解绑自动跟随。
    if (notification is UserScrollNotification &&
        notification.direction == ScrollDirection.forward &&
        _autoFollow) {
      setState(() => _autoFollow = false);
    }
    if (notification is ScrollEndNotification && !_autoFollow) {
      final metrics = notification.metrics;
      if (metrics.maxScrollExtent - metrics.pixels < _bottomThreshold) {
        setState(() {
          _autoFollow = true;
          _unread = 0;
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(asrControllerProvider.select((s) => s.history));
    final fontSize =
        ref.watch(settingsProvider.select((s) => s.fontScale.history));

    ref.listen(asrControllerProvider.select((s) => s.history.length),
        (previous, next) {
      if (next == 0) {
        setState(() {
          _autoFollow = true;
          _unread = 0;
        });
      } else if (next > (previous ?? 0)) {
        if (_autoFollow) {
          _scrollToBottom();
        } else {
          setState(() => _unread += next - (previous ?? 0));
        }
      }
    });

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: history.length,
            itemBuilder: (context, index) =>
                _HistoryEntry(item: history[index], fontSize: fontSize),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 12,
          child: IgnorePointer(
            ignoring: _autoFollow,
            child: AnimatedOpacity(
              opacity: _autoFollow ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: Badge(
                isLabelVisible: _unread > 0,
                label: Text('$_unread'),
                child: FilledButton.icon(
                  onPressed: _resumeFollow,
                  icon: const Icon(Icons.arrow_downward_rounded),
                  label: const Text('回到最新'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({required this.item, required this.fontSize});

  final SubtitleItem item;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text.rich(
        TextSpan(
          style: TextStyle(fontSize: fontSize, height: 1.5),
          children: [
            TextSpan(
              text: '${item.formattedTime} ',
              style: TextStyle(color: palette.timestamp),
            ),
            TextSpan(
              text: item.displayText,
              style: TextStyle(color: palette.historyText),
            ),
          ],
        ),
      ),
    );
  }
}
