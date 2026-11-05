import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../asr/asr_engine.dart';
import '../l10n/l10n.dart';
import '../platform/background_platform.dart';
import '../state/asr_controller.dart';
import '../state/asr_state.dart';
import '../state/settings.dart';
import 'app_colors.dart';

/// App 切到后台且正在识别时显示浮动字幕窗口，回到前台时隐藏（PRD 4.7）。
class FloatingCaptionHost extends ConsumerStatefulWidget {
  const FloatingCaptionHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<FloatingCaptionHost> createState() =>
      _FloatingCaptionHostState();
}

class _FloatingCaptionHostState extends ConsumerState<FloatingCaptionHost> {
  /// 发送给浮动窗口的历史记录上限；窗口按自身高度显示其中能容纳的部分，
  /// 其余可上下滑动查看。
  static const _historyLimit = 100;

  late final AppLifecycleListener _lifecycle;
  StreamSubscription<AudioInput>? _inputRequests;
  StreamSubscription<void>? _exitRequests;
  StreamSubscription<AsrEngineState>? _stateChanges;
  bool _visible = false;

  /// 浮动窗可见期间已提示过的错误 id，避免重复弹 Toast。
  int _lastErrorId = 0;

  /// 在 initState 中取出，dispose 时不能再通过 ref 读取。
  late final BackgroundPlatform _platform;

  @override
  void initState() {
    super.initState();
    _platform = ref.read(backgroundPlatformProvider);
    _lifecycle = AppLifecycleListener(onHide: _onHide, onShow: _onShow);
    _inputRequests = _platform.audioInputRequests.listen(
      (input) => ref.read(asrControllerProvider.notifier).setAudioInput(input),
    );
    _exitRequests = _platform.exitRequests.listen((_) => _exit());
    // 直接订阅识别状态的广播流而非控件层 ref.listen：后台帧暂停时仍能即时更新，
    // 否则浮动窗会“慢一句”（最新一句要等下一句才显示）。
    _stateChanges = ref
        .read(asrControllerProvider.notifier)
        .changes
        .listen(_onStateChanged);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _inputRequests?.cancel();
    _exitRequests?.cancel();
    _stateChanges?.cancel();
    if (_visible) _platform.hideOverlay();
    super.dispose();
  }

  /// 识别状态变化（后台帧无关）：可见时推送到浮动窗，并在停止识别时收起。
  void _onStateChanged(AsrEngineState next) {
    if (!_visible) return;
    if (next.errorId != _lastErrorId) {
      _lastErrorId = next.errorId;
      final message = next.errorMessage;
      if (message != null) _platform.showToast(message);
    }
    if (!next.isListening) {
      _onShow();
    } else {
      _push(next);
    }
  }

  Future<void> _onHide() async {
    final settings = ref.read(settingsProvider);
    final asr = ref.read(asrControllerProvider);
    if (_visible || !settings.floatingCaption || !asr.isListening) return;
    if (!await _platform.canShowOverlay()) return;

    final palette = AppPalette.forSettings(settings);
    final l10n = ref.read(appLocalizationsProvider);
    await _platform.showOverlay(
      FloatingCaptionStyle(
        background: palette.background.withValues(alpha: 0.75),
        focusColor: palette.focusText,
        historyColor: palette.historyText,
        focusSize: settings.fontScale.size,
        historySize: settings.fontScale.size,
        historyBold: settings.boldText,
        labels: FloatingCaptionLabels(
          microphone: l10n.microphone,
          speaker: l10n.speaker,
          back: l10n.overlayBack,
          exit: l10n.overlayExit,
          confirmExit: l10n.overlayConfirmExit,
          cancel: l10n.cancel,
        ),
      ),
    );
    _visible = true;
    // 以当前错误 id 为基线，避免显示浮动窗时重播此前已提示过的错误。
    _lastErrorId = ref.read(asrControllerProvider).errorId;
    await _push(ref.read(asrControllerProvider));
  }

  /// 浮动窗口“退出”：停止识别、关闭浮动窗口，然后关闭 App。
  Future<void> _exit() async {
    await ref.read(asrControllerProvider.notifier).stopListening();
    if (_visible) {
      _visible = false;
      await _platform.hideOverlay();
    }
    await _platform.exitApp();
  }

  Future<void> _onShow() async {
    if (!_visible) return;
    _visible = false;
    await _platform.hideOverlay();
  }

  Future<void> _push(AsrEngineState state) => _platform.updateOverlay(
    current: state.currentPendingText,
    partial: state.currentPendingText.isNotEmpty,
    history: [
      for (final item in state.history.skip(
        state.history.length > _historyLimit
            ? state.history.length - _historyLimit
            : 0,
      ))
        item.displayText(ref.read(appLocalizationsProvider).eventName),
    ],
    systemAudio: state.audioInput == AudioInput.systemAudio,
  );

  @override
  Widget build(BuildContext context) {
    // 浮动窗的更新改由 _onStateChanged 驱动（见 initState）；此处仅承载子树。
    return widget.child;
  }
}
