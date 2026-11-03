import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings.dart';

final onboardingDoneProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);

class OnboardingNotifier extends Notifier<bool> {
  static const _key = 'onboarding.done';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(_key) ?? false;

  void complete() {
    ref.read(sharedPreferencesProvider).setBool(_key, true);
    state = true;
  }
}
