import 'dart:async';

import 'package:seevoice/asr/asr_engine.dart';
import 'package:seevoice/platform/background_platform.dart';

/// 记录浮动窗口调用的测试平台。
class FakeBackgroundPlatform implements BackgroundPlatform {
  bool overlayAllowed = true;
  bool openedOverlaySettings = false;

  /// 默认模拟 Android：两种平台能力都具备。置为 false 可模拟 iOS。
  bool overlaySupported = true;
  bool systemAudioSupported = true;

  FloatingCaptionStyle? shownStyle;
  bool visible = false;
  final updates =
      <
        ({String current, bool partial, List<String> history, bool systemAudio})
      >[];
  final _inputs = StreamController<AudioInput>.broadcast(sync: true);
  final toasts = <String>[];
  final _exits = StreamController<void>.broadcast(sync: true);
  bool exited = false;

  /// 模拟用户点击浮动窗口上的“退出”。
  void tapExit() => _exits.add(null);

  @override
  Stream<void> get exitRequests => _exits.stream;

  @override
  Future<void> exitApp() async => exited = true;

  /// 模拟用户在浮动窗口上选择声音来源。
  void selectInput(AudioInput input) => _inputs.add(input);

  @override
  Stream<AudioInput> get audioInputRequests => _inputs.stream;

  @override
  Future<void> showToast(String message) async => toasts.add(message);

  @override
  bool get supportsOverlay => overlaySupported;

  @override
  bool get supportsSystemAudio => systemAudioSupported;

  @override
  Future<bool> canShowOverlay() async => overlayAllowed;

  @override
  Future<void> openOverlaySettings() async => openedOverlaySettings = true;

  @override
  Future<void> showOverlay(FloatingCaptionStyle style) async {
    shownStyle = style;
    visible = true;
  }

  @override
  Future<void> updateOverlay({
    required String current,
    required bool partial,
    required List<String> history,
    required bool systemAudio,
  }) async => updates.add((
    current: current,
    partial: partial,
    history: history,
    systemAudio: systemAudio,
  ));

  @override
  Future<void> hideOverlay() async => visible = false;
}
