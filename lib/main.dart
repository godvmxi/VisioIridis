import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/app_colors.dart';
import 'ui/home_page.dart';

void main() {
  runApp(const ProviderScope(child: SeeVoiceApp()));
}

class SeeVoiceApp extends StatelessWidget {
  const SeeVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _appTitle(WidgetsBinding.instance.platformDispatcher.locale),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.listening,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const HomePage(),
    );
  }
}

/// 最近任务列表中显示的名称，与 Android 启动器名称（res/values*/strings.xml）保持一致。
String _appTitle(Locale locale) {
  if (locale.languageCode != 'zh') return 'Visio Iridis';
  const traditionalRegions = {'HK', 'TW', 'MO'};
  final isTraditional = locale.scriptCode == 'Hant' ||
      traditionalRegions.contains(locale.countryCode);
  return isTraditional ? '伊利斯之視' : '伊利斯之视';
}
