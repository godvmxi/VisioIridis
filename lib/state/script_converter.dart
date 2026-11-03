import 'package:flutter/foundation.dart';
import 'package:flutter_open_chinese_convert/flutter_open_chinese_convert.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';

/// 识别结果上屏时使用的汉字字形。
enum ChineseScript { simplified, traditional }

/// 繁简转换。不同模型输出的字形不一，统一转换为界面语言对应的字形。
abstract interface class ScriptConverter {
  Future<String> convert(String text, ChineseScript target);
}

/// 基于 OpenCC 的转换。只做字形转换（s2t / t2s），不替换地区用词，
/// 避免字幕与说话人的原话不一致。转换失败时原样返回。
class OpenCcConverter implements ScriptConverter {
  const OpenCcConverter();

  @override
  Future<String> convert(String text, ChineseScript target) async {
    if (text.isEmpty) return text;
    try {
      return await ChineseConverter.convert(
        text,
        target == ChineseScript.simplified ? T2S() : S2T(),
      );
    } catch (e) {
      debugPrint('OpenCC 转换失败: $e');
      return text;
    }
  }
}

final scriptConverterProvider = Provider<ScriptConverter>(
  (ref) => const OpenCcConverter(),
);

/// 界面为简体或繁体中文时上屏使用的字形；其他界面语言不转换，为 null。
final chineseScriptProvider = Provider<ChineseScript?>((ref) {
  final locale = ref.watch(appLocaleProvider);
  if (locale.languageCode != 'zh') return null;
  return locale.scriptCode == 'Hant'
      ? ChineseScript.traditional
      : ChineseScript.simplified;
});
