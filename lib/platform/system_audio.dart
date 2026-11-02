import 'package:flutter/services.dart';

/// 捕获系统播放的声音（PRD 4.8），由 SystemAudioCaptureService 实现。
/// 输出 16kHz / 16bit / 单声道 PCM，与麦克风录音格式一致。
class SystemAudioCapture {
  SystemAudioCapture._();

  static const _channel = MethodChannel('visio_iridis/system_audio');
  static const _pcm = EventChannel('visio_iridis/system_audio/pcm');

  /// 录制期间前台服务通知的文字，由 App 按界面语言设置。
  static ({String channel, String title, String text}) texts = (
    channel: '系统声音字幕',
    title: '正在识别系统播放的声音',
    text: '点击返回 App',
  );

  /// Android 10 及以上支持。
  static Future<bool> isSupported() async =>
      await _channel.invokeMethod<bool>('isSupported') ?? false;

  /// 弹出系统录制确认框并开始捕获。用户拒绝或系统不支持时返回 false。
  static Future<bool> start() async =>
      await _channel.invokeMethod<bool>('start', {
        'channel': texts.channel,
        'title': texts.title,
        'text': texts.text,
      }) ??
      false;

  static Future<void> stop() => _channel.invokeMethod<void>('stop');

  /// 捕获到的 PCM 数据；捕获被结束（如用户在通知栏停止）时流结束。
  static Stream<Uint8List> get pcm =>
      _pcm.receiveBroadcastStream().map((e) => e as Uint8List);
}
