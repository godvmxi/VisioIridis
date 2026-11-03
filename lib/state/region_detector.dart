import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings.dart';

enum RegionResult { unknown, mainland, overseas }

final regionProvider = AsyncNotifierProvider<RegionNotifier, RegionResult>(
  RegionNotifier.new,
);

class RegionNotifier extends AsyncNotifier<RegionResult> {
  static const _prefKey = 'region.result';
  static const _probeTimeout = Duration(seconds: 5);

  // 大陆受限站点：任一可通 → 境外/VPN 环境
  static const _blockedHosts = [
    ('google.com', 443),
    ('x.com', 443),
    ('huggingface.co', 443),
  ];

  // 大陆可用站点：至少一个可通 → 确认在大陆且有网络
  static const _chinaHosts = [
    ('baidu.com', 443),
    ('taobao.com', 443),
  ];

  @override
  Future<RegionResult> build() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final cached = _parse(prefs.getString(_prefKey));
    // 地区已明确时直接返回缓存，不重复探测；仅首次或未知时才探测
    if (cached == RegionResult.unknown) unawaited(_probeAndUpdate());
    return cached;
  }

  Future<void> _probeAndUpdate() async {
    try {
      final result = await _probe();
      if (!ref.mounted) return;
      state = AsyncData(result);
      await ref.read(sharedPreferencesProvider).setString(_prefKey, result.name);
    } catch (_) {}
  }

  static Future<RegionResult> _probe() async {
    // 所有探测并发发出，总等待时间 = 单个超时时间（5s）
    final allHosts = [..._blockedHosts, ..._chinaHosts];
    final results = await Future.wait(
      allHosts.map((h) => _canConnect(h.$1, h.$2)),
    );

    final nBlocked = _blockedHosts.length;
    if (results.take(nBlocked).any((r) => r)) return RegionResult.overseas;
    if (results.skip(nBlocked).any((r) => r)) return RegionResult.mainland;
    return RegionResult.unknown;
  }

  static Future<bool> _canConnect(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: _probeTimeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  static RegionResult _parse(String? name) => RegionResult.values.firstWhere(
    (r) => r.name == name,
    orElse: () => RegionResult.unknown,
  );
}
