import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../asr/asr_engine.dart';
import '../../l10n/l10n.dart';
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
    final fontSize = ref.watch(
      settingsProvider.select((s) => s.fontScale.size),
    );
    final weight = ref.watch(settingsProvider.select((s) => s.textWeight));

    ref.listen(asrControllerProvider.select((s) => s.history.length), (
      previous,
      next,
    ) {
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
            itemBuilder: (context, index) => _HistoryEntry(
              item: history[index],
              fontSize: fontSize,
              weight: weight,
            ),
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
                  label: Text(AppLocalizations.of(context).backToLatest),
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
  const _HistoryEntry({
    required this.item,
    required this.fontSize,
    required this.weight,
  });

  final SubtitleItem item;
  final double fontSize;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return ChatBubble(
      text: item.displayText(AppLocalizations.of(context).eventName),
      source: item.audioInput,
      palette: AppPalette.of(context),
      fontSize: fontSize,
      weight: weight,
    );
  }
}

/// 微信式聊天气泡：喇叭来源靠左、麦克风来源靠右，头像位置显示来源图标。
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.source,
    required this.palette,
    required this.fontSize,
    required this.weight,
  });

  final String text;
  final AudioInput source;

  /// 显式传入，设置页预览可以使用尚未生效的配色。
  final AppPalette palette;
  final double fontSize;
  final FontWeight weight;

  static const _avatarSize = 40.0;
  static const _radius = Radius.circular(20);
  static const _tail = Radius.circular(4);

  @override
  Widget build(BuildContext context) {
    final incoming = source == AudioInput.systemAudio;
    final avatar = Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(color: palette.avatar, shape: BoxShape.circle),
      child: Icon(
        incoming ? Icons.volume_up_rounded : Icons.mic_rounded,
        size: 22,
        color: palette.historyText,
      ),
    );
    final bubble = Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: incoming ? palette.bubbleIncoming : palette.bubbleOutgoing,
          // 靠头像一侧的上角收小，形成指向头像的“尾巴”。
          borderRadius: BorderRadius.only(
            topLeft: incoming ? _tail : _radius,
            topRight: incoming ? _radius : _tail,
            bottomLeft: _radius,
            bottomRight: _radius,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.4,
            fontWeight: weight,
            color: palette.historyText,
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: incoming
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: incoming
            ? [
                avatar,
                const SizedBox(width: 10),
                bubble,
                const SizedBox(width: 50),
              ]
            : [
                const SizedBox(width: 50),
                bubble,
                const SizedBox(width: 10),
                avatar,
              ],
      ),
    );
  }
}
