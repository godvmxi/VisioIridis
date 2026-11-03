import 'dart:convert';

import 'package:flutter/material.dart' hide KeepAlive;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/l10n.dart';
import 'platform/keep_alive.dart';
import 'platform/system_audio.dart';
import 'state/onboarding.dart';
import 'state/settings.dart';
import 'ui/app_colors.dart';
import 'ui/floating_caption_host.dart';
import 'ui/home_page.dart';
import 'ui/onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Seed HF token from bundled hf.json on first run (prefs take priority on subsequent runs).
  if (prefs.getString('credentials.hfToken') == null) {
    try {
      final raw = await rootBundle.loadString('assets/config/hf.json');
      final token =
          (jsonDecode(raw) as Map<String, dynamic>)['access_token'] as String?;
      if (token != null && token.isNotEmpty) {
        await prefs.setString('credentials.hfToken', token);
      }
    } catch (_) {}
  }
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SeeVoiceApp(),
    ),
  );
}

class SeeVoiceApp extends ConsumerWidget {
  const SeeVoiceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.forSettings(ref.watch(settingsProvider));
    final l10n = ref.watch(appLocalizationsProvider);
    // 后台服务的通知文字没有 BuildContext，在这里随界面语言更新。
    KeepAlive.texts = (
      channel: l10n.notificationChannel,
      channelDescription: l10n.notificationChannelDescription,
      title: l10n.notificationTitle,
      text: l10n.notificationText,
    );
    SystemAudioCapture.texts = (
      channel: l10n.systemAudioNotificationChannel,
      title: l10n.systemAudioNotificationTitle,
      text: l10n.notificationText,
    );
    return MaterialApp(
      // 最近任务列表中显示的名称。
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: ref.watch(appLocaleProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 让语言胶囊、开关、对话框等系统控件的文字与选中色也跟随配色模式。
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: AppColors.listening,
              brightness: palette.brightness,
            ).copyWith(
              primary: palette.focusText,
              onPrimary: palette.background,
              surface: palette.background,
              onSurface: palette.focusText,
              onSurfaceVariant: palette.historyText,
              secondaryContainer: palette.cardBorder,
              onSecondaryContainer: palette.focusText,
              surfaceContainerHigh: palette.cardSurface,
              surfaceContainerHighest: palette.cardSurface,
              outline: palette.cardBorder,
            ),
        scaffoldBackgroundColor: palette.background,
        extensions: [palette],
      ),
      home: ref.watch(onboardingDoneProvider)
              ? const FloatingCaptionHost(child: HomePage())
              : const OnboardingPage(),
    );
  }
}
