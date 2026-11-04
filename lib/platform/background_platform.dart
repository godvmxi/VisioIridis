import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../asr/asr_engine.dart';

/// 浮动字幕窗口的样式（PRD 4.7）。
class FloatingCaptionStyle {
  const FloatingCaptionStyle({
    required this.background,
    required this.focusColor,
    required this.historyColor,
    required this.focusSize,
    required this.historySize,
    this.historyBold = false,
    this.heightFraction = 1 / 3,
    this.labels = const FloatingCaptionLabels(),
  });

  final Color background;
  final Color focusColor;
  final Color historyColor;
  final double focusSize;
  final double historySize;
  final bool historyBold;
  final double heightFraction;
  final FloatingCaptionLabels labels;
}

/// 浮动字幕窗口上的按钮文字，随界面语言变化。
class FloatingCaptionLabels {
  const FloatingCaptionLabels({
    this.microphone = '麦克风',
    this.speaker = '喇叭',
    this.back = '返回',
    this.exit = '退出',
    this.confirmExit = '确定退出？',
    this.cancel = '取消',
  });

  final String microphone;
  final String speaker;
  final String back;
  final String exit;
  final String confirmExit;
  final String cancel;
}

/// 浮动字幕窗口相关的平台能力。
abstract class BackgroundPlatform {
  /// 本平台能否把字幕画在其他 App 之上（PRD 4.7）。
  ///
  /// 和 [canShowOverlay] 问的不是一回事：这里问「平台有没有这种能力」，
  /// [canShowOverlay] 问「用户有没有授权」。iOS 不允许任何 App 画在别的 App
  /// 之上，没有对等能力也没有可申请的权限，所以界面据此整块隐藏浮动窗设置项，
  /// 而不是留一个点下去必然失败的开关。
  ///
  /// 同步返回：界面要用它决定是否渲染控件，build 里没法 await。
  bool get supportsOverlay;

  /// 本平台能否捕获系统播放的声音（PRD 4.8）。
  ///
  /// iOS 没有捕获其他 App 音频的 API，界面据此隐藏「声音来源」切换。
  bool get supportsSystemAudio;

  Future<bool> canShowOverlay();

  /// 打开系统“显示在其他应用上层”设置页，用户返回 App 后完成。
  Future<void> openOverlaySettings();

  Future<void> showOverlay(FloatingCaptionStyle style);

  /// [history] 为最近的历史记录，旧的在前；[systemAudio] 为是否正在识别系统声音。
  Future<void> updateOverlay({
    required String current,
    required bool partial,
    required List<String> history,
    required bool systemAudio,
  });

  /// 用户在浮动窗口上选择的声音来源（PRD 4.8）。
  Stream<AudioInput> get audioInputRequests;

  /// App 在后台时用系统 Toast 显示提示。
  Future<void> showToast(String message);

  /// 用户点击浮动窗口上的“退出”。
  Stream<void> get exitRequests;

  /// 关闭 App（结束 Activity 并从最近任务中移除）。
  Future<void> exitApp();

  Future<void> hideOverlay();
}

/// 浮动窗口与系统内录都依赖平台独有能力，在没有这些能力的平台（iOS）上
/// 用这个实现：能力查询一律返回 false，其余方法是空操作，不触碰任何
/// MethodChannel（否则会抛 MissingPluginException）。
///
/// 纯 Dart，不需要原生代码：
/// - 浮动窗相关的方法不会被调用，因为界面在 [supportsOverlay] 为 false 时
///   不渲染入口，`FloatingCaptionHost` 也会在 [canShowOverlay] 处提前返回；
/// - [showToast] 只在浮动窗口可见时才会被调用，所以这里不必找 iOS 的替代品；
/// - [exitApp] 保持空操作：iOS 上 App 主动自杀会被审核拒绝。
class UnsupportedBackgroundPlatform implements BackgroundPlatform {
  const UnsupportedBackgroundPlatform();

  @override
  bool get supportsOverlay => false;

  @override
  bool get supportsSystemAudio => false;

  @override
  Future<bool> canShowOverlay() async => false;

  @override
  Future<void> openOverlaySettings() async {}

  @override
  Future<void> showOverlay(FloatingCaptionStyle style) async {}

  @override
  Future<void> updateOverlay({
    required String current,
    required bool partial,
    required List<String> history,
    required bool systemAudio,
  }) async {}

  @override
  Future<void> hideOverlay() async {}

  @override
  Stream<AudioInput> get audioInputRequests => const Stream.empty();

  @override
  Stream<void> get exitRequests => const Stream.empty();

  @override
  Future<void> showToast(String message) async {}

  @override
  Future<void> exitApp() async {}
}

final backgroundPlatformProvider = Provider<BackgroundPlatform>(
  (ref) => defaultTargetPlatform == TargetPlatform.android
      ? AndroidBackgroundPlatform()
      : const UnsupportedBackgroundPlatform(),
);

class AndroidBackgroundPlatform implements BackgroundPlatform {
  AndroidBackgroundPlatform() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'selectAudioInput':
          _inputs.add(AudioInput.values.byName(call.arguments as String));
        case 'requestExit':
          _exits.add(null);
      }
    });
  }

  static const _channel = MethodChannel('visio_iridis/overlay');
  final _inputs = StreamController<AudioInput>.broadcast();
  final _exits = StreamController<void>.broadcast();

  @override
  bool get supportsOverlay => true;

  @override
  bool get supportsSystemAudio => true;

  @override
  Stream<void> get exitRequests => _exits.stream;

  @override
  Future<void> exitApp() => _channel.invokeMethod<void>('exitApp');

  @override
  Stream<AudioInput> get audioInputRequests => _inputs.stream;

  @override
  Future<void> showToast(String message) =>
      _channel.invokeMethod<void>('toast', {'message': message});

  @override
  Future<bool> canShowOverlay() => FlutterForegroundTask.canDrawOverlays;

  @override
  Future<void> openOverlaySettings() async {
    await FlutterForegroundTask.openSystemAlertWindowSettings();
    await _waitForResume();
  }

  @override
  Future<void> showOverlay(FloatingCaptionStyle style) =>
      _channel.invokeMethod<void>('show', {
        'heightFraction': style.heightFraction,
        'background': style.background.toARGB32(),
        'focusColor': style.focusColor.toARGB32(),
        'historyColor': style.historyColor.toARGB32(),
        'focusSize': style.focusSize,
        'historySize': style.historySize,
        'historyBold': style.historyBold,
        'microphone': style.labels.microphone,
        'speaker': style.labels.speaker,
        'back': style.labels.back,
        'exit': style.labels.exit,
        'confirmExit': style.labels.confirmExit,
        'cancel': style.labels.cancel,
      });

  @override
  Future<void> updateOverlay({
    required String current,
    required bool partial,
    required List<String> history,
    required bool systemAudio,
  }) => _channel.invokeMethod<void>('update', {
    'current': current,
    'partial': partial,
    'history': history,
    'systemAudio': systemAudio,
  });

  @override
  Future<void> hideOverlay() => _channel.invokeMethod<void>('hide');

  /// 等待用户从系统设置页返回 App；最多等 5 分钟。
  static Future<void> _waitForResume() {
    final done = Completer<void>();
    late final AppLifecycleListener listener;
    listener = AppLifecycleListener(
      onResume: () {
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future
        .timeout(const Duration(minutes: 5), onTimeout: () {})
        .whenComplete(listener.dispose);
  }
}
