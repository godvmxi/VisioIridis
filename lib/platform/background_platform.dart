import 'dart:async';

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
  });

  final Color background;
  final Color focusColor;
  final Color historyColor;
  final double focusSize;
  final double historySize;
  final bool historyBold;
  final double heightFraction;
}

/// 浮动字幕窗口相关的平台能力。
abstract class BackgroundPlatform {
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

final backgroundPlatformProvider =
    Provider<BackgroundPlatform>((ref) => AndroidBackgroundPlatform());

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
      });

  @override
  Future<void> updateOverlay({
    required String current,
    required bool partial,
    required List<String> history,
    required bool systemAudio,
  }) =>
      _channel.invokeMethod<void>('update', {
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
    listener = AppLifecycleListener(onResume: () {
      if (!done.isCompleted) done.complete();
    });
    return done.future
        .timeout(const Duration(minutes: 5), onTimeout: () {})
        .whenComplete(listener.dispose);
  }
}
