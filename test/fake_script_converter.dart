import 'package:visioiridis/state/script_converter.dart';

/// 用少量字的对照表模拟 OpenCC，不依赖原生插件。
class FakeScriptConverter implements ScriptConverter {
  static const _toTraditional = {'开': '開', '会': '會', '说': '說', '话': '話'};

  @override
  Future<String> convert(String text, ChineseScript target) async {
    final map = target == ChineseScript.traditional
        ? _toTraditional
        : {for (final e in _toTraditional.entries) e.value: e.key};
    return text.split('').map((c) => map[c] ?? c).join();
  }
}
