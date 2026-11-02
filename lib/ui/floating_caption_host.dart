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
  bool _visible = false;

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
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _inputRequests?.cancel();
    _exitRequests?.cancel();
    if (_visible) _platform.hideOverlay();
    super.dispose();
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
    // 后台时主界面的 SnackBar 不可见，提示改用 Toast。
    ref.listen(asrControllerProvider.select((s) => s.errorId), (_, _) {
      final message = ref.read(asrControllerProvider).errorMessage;
      if (_visible && message != null) _platform.showToast(message);
    });
    ref.listen(asrControllerProvider, (_, next) {
      if (!_visible) return;
      if (!next.isListening) {
        _onShow();
      } else {
        _push(next);
      }
    });
    return widget.child;
  }
}
