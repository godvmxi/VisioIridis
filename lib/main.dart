import 'package:flutter/material.dart' hide KeepAlive;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/l10n.dart';
import 'model_store/bundled_model_store.dart';
import 'platform/keep_alive.dart';
import 'platform/system_audio.dart';
import 'state/analytics.dart';
import 'state/model_providers.dart';
import 'state/onboarding.dart';
import 'state/settings.dart';
import 'ui/app_colors.dart';
import 'ui/app_theme.dart';
import 'ui/floating_caption_host.dart';
import 'ui/home_page.dart';
import 'ui/onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bundled = await BundledModels.load();
  // 旧版本可能存过 HuggingFace token，已不再使用。
  prefs.remove('credentials.hfToken');
  // PostHog 由原生 AUTO_INIT 自动初始化，这里无需手动 setup（见 AndroidManifest.xml）。
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        bundledModelsProvider.overrideWithValue(bundled),
      ],
      child: const VisioIridisApp(),
    ),
  );
}

class VisioIridisApp extends ConsumerWidget {
  const VisioIridisApp({super.key});

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
      navigatorObservers: [Analytics.observer],
      theme: buildTheme(palette),
      home: ref.watch(onboardingDoneProvider)
          ? const FloatingCaptionHost(child: HomePage())
          : const OnboardingPage(),
    );
  }
}
