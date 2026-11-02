import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'state/settings.dart';
import 'ui/app_colors.dart';
import 'ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const SeeVoiceApp(),
  ));
}

class SeeVoiceApp extends ConsumerWidget {
  const SeeVoiceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(settingsProvider.select((s) => s.colorMode));
    final palette = AppPalette.forMode(mode);
    return MaterialApp(
      title: _appTitle(WidgetsBinding.instance.platformDispatcher.locale),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.listening,
          brightness: palette.brightness,
        ),
        scaffoldBackgroundColor: palette.background,
        extensions: [palette],
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
