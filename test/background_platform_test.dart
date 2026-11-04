import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seevoice/platform/background_platform.dart';

void main() {
  // AndroidBackgroundPlatform 的构造函数会注册 MethodChannel 处理器，
  // 需要先初始化 binding 才能拿到 binary messenger。
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UnsupportedBackgroundPlatform', () {
    const platform = UnsupportedBackgroundPlatform();

    test('两种平台能力都报告为不支持', () {
      expect(platform.supportsOverlay, isFalse);
      expect(platform.supportsSystemAudio, isFalse);
    });

    test('canShowOverlay 为 false，FloatingCaptionHost 据此提前返回', () async {
      expect(await platform.canShowOverlay(), isFalse);
    });

    test('浮动窗相关方法都是空操作，不抛 MissingPluginException', () async {
      // 界面已经隐藏了入口，这里只保证即使被调用也不会炸。
      await platform.openOverlaySettings();
      await platform.showOverlay(
        const FloatingCaptionStyle(
          background: Color(0xFF000000),
          focusColor: Color(0xFFFFE600),
          historyColor: Color(0xFFFFFFFF),
          focusSize: 28,
          historySize: 28,
        ),
      );
      await platform.updateOverlay(
        current: 'x',
        partial: true,
        history: const ['y'],
        systemAudio: false,
      );
      await platform.hideOverlay();
      await platform.showToast('x');
      await platform.exitApp();
    });

    test('两个事件流都是空流，监听者不会收到任何事件', () async {
      expect(await platform.audioInputRequests.isEmpty, isTrue);
      expect(await platform.exitRequests.isEmpty, isTrue);
    });
  });

  group('backgroundPlatformProvider 按平台分发', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('Android 上用 AndroidBackgroundPlatform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(backgroundPlatformProvider),
        isA<AndroidBackgroundPlatform>(),
      );
    });

    test('iOS 上用 UnsupportedBackgroundPlatform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(backgroundPlatformProvider),
        isA<UnsupportedBackgroundPlatform>(),
      );
    });
  });
}
