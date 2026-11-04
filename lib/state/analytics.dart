import 'package:flutter/widgets.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// PostHog 分析封装。
///
/// SDK 初始化由原生自动完成——配置写在
/// `android/app/src/main/AndroidManifest.xml` 的 `com.posthog.posthog.*`
/// meta-data 里（Token、上报地址、AUTO_INIT），此处无需也不应再手动 setup。
/// 本类仅提供事件上报与页面浏览采集的便捷入口。
class Analytics {
  Analytics._();

  /// 用于 MaterialApp 自动采集页面浏览（Screen 事件）。
  static final NavigatorObserver observer = PosthogObserver();

  /// 上报自定义事件。
  static Future<void> capture(
    String event, {
    Map<String, Object>? properties,
  }) => Posthog().capture(eventName: event, properties: properties);
}
