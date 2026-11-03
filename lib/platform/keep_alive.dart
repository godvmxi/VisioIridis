import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// 识别期间的麦克风前台服务（PRD 5.4）：App 切到后台后继续拾音，
/// 并降低被系统回收的概率。服务启动失败不影响前台识别。
///
/// 只在 Android 上启用。iOS 没有「前台服务」这个概念，后台拾音靠
/// Info.plist 的 `UIBackgroundModes: audio` 配合音频会话类别实现，插件在
/// iOS 上只能多发一条通知，对保活没有实质帮助，所以这里直接跳过。
class KeepAlive {
  KeepAlive._();

  static bool get _enabled => defaultTargetPlatform == TargetPlatform.android;

  static bool _initialized = false;

  /// 通知文字，由 App 按界面语言设置。
  static ({
    String channel,
    String channelDescription,
    String title,
    String text,
  })
  texts = (
    channel: '实时字幕',
    channelDescription: '识别进行中时显示',
    title: '实时字幕识别中',
    text: '点击返回 App',
  );

  static Future<void> start() async {
    if (!_enabled) return;
    try {
      if (!_initialized) {
        FlutterForegroundTask.init(
          androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'asr_service',
            channelName: texts.channel,
            channelDescription: texts.channelDescription,
            onlyAlertOnce: true,
          ),
          iosNotificationOptions: const IOSNotificationOptions(),
          foregroundTaskOptions: ForegroundTaskOptions(
            eventAction: ForegroundTaskEventAction.nothing(),
            allowWakeLock: true,
            allowAutoRestart: false,
            // 注意：插件的 stopWithTask 会在所有 Activity 进入 onPause（即 App 切到
            // 后台）时停止服务，导致系统静音后台麦克风。必须为 false；Activity
            // 销毁时由 MainActivity 负责停止服务。
            stopWithTask: false,
          ),
        );
        _initialized = true;
      }
      if (await FlutterForegroundTask.checkNotificationPermission() !=
          NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      if (await FlutterForegroundTask.isRunningService) return;
      await FlutterForegroundTask.startService(
        serviceTypes: [ForegroundServiceTypes.microphone],
        notificationTitle: texts.title,
        notificationText: texts.text,
      );
    } catch (_) {
      // 前台服务只用于后台保活，失败时继续前台识别。
    }
  }

  static Future<void> stop() async {
    if (!_enabled) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (_) {}
  }
}
