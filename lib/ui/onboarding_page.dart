import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/l10n.dart';
import '../state/onboarding.dart';
import '../state/region_detector.dart';
import 'app_colors.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;
  static const _totalPages = 6;

  void _next() {
    if (_page >= _totalPages - 1) return;
    setState(() => _page++);
    _controller.animateToPage(
      _page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _complete() => ref.read(onboardingDoneProvider.notifier).complete();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: _StepDots(current: _page, total: _totalPages),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomeStep(onNext: _next),
                  _DialogPermissionStep(
                    icon: Icons.mic,
                    getTitle: (l) => l.onboardingMicTitle,
                    getBody: (l) => l.onboardingMicBody,
                    getButtonLabel: (l) => l.onboardingMicButton,
                    onRequest: () async {
                      final status = await Permission.microphone.request();
                      return status.isGranted;
                    },
                    checkStatus: () async =>
                        (await Permission.microphone.status).isGranted,
                    onNext: _next,
                  ),
                  _DialogPermissionStep(
                    icon: Icons.notifications_active,
                    getTitle: (l) => l.onboardingNotifTitle,
                    getBody: (l) => l.onboardingNotifBody,
                    getButtonLabel: (l) => l.onboardingNotifButton,
                    onRequest: () async {
                      final status = await Permission.notification.request();
                      return status.isGranted;
                    },
                    checkStatus: () async =>
                        (await Permission.notification.status).isGranted,
                    onNext: _next,
                  ),
                  _SettingsPermissionStep(
                    icon: Icons.picture_in_picture,
                    getTitle: (l) => l.onboardingOverlayTitle,
                    getBody: (l) => l.onboardingOverlayBody,
                    getButtonLabel: (l) => l.onboardingOverlayButton,
                    openSettings:
                        FlutterForegroundTask.openSystemAlertWindowSettings,
                    checkStatus: () => FlutterForegroundTask.canDrawOverlays,
                    onNext: _next,
                  ),
                  _SettingsPermissionStep(
                    icon: Icons.battery_saver,
                    getTitle: (l) => l.onboardingBatteryTitle,
                    getBody: (l) => l.onboardingBatteryBody,
                    getButtonLabel: (l) => l.onboardingBatteryButton,
                    openSettings: FlutterForegroundTask
                        .openIgnoreBatteryOptimizationSettings,
                    checkStatus: () =>
                        FlutterForegroundTask.isIgnoringBatteryOptimizations,
                    onNext: _next,
                  ),
                  _RegionStep(onDone: _complete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Visual helpers ─────────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == current ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current
                  ? palette.focusText
                  : palette.historyText.withAlpha(100),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _StepLayout extends StatelessWidget {
  const _StepLayout({
    required this.icon,
    required this.title,
    required this.body,
    required this.buttons,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 68, color: palette.focusText),
                const SizedBox(height: 28),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: palette.focusText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.65,
                    color: palette.historyText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          ...buttons,
        ],
      ),
    );
  }
}

// ── Step 0: Welcome ─────────────────────────────────────────────────────────

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _StepLayout(
      icon: Icons.closed_caption,
      title: l10n.onboardingWelcomeTitle,
      body: l10n.onboardingWelcomeBody,
      buttons: [
        FilledButton(onPressed: onNext, child: Text(l10n.onboardingNext)),
      ],
    );
  }
}

// ── Steps 1-2: Dialog-based permissions (mic, notifications) ─────────────────

class _DialogPermissionStep extends StatefulWidget {
  const _DialogPermissionStep({
    required this.icon,
    required this.getTitle,
    required this.getBody,
    required this.getButtonLabel,
    required this.onRequest,
    required this.checkStatus,
    required this.onNext,
  });

  final IconData icon;
  final String Function(AppLocalizations) getTitle;
  final String Function(AppLocalizations) getBody;
  final String Function(AppLocalizations) getButtonLabel;
  final Future<bool> Function() onRequest;
  final Future<bool> Function() checkStatus;
  final VoidCallback onNext;

  @override
  State<_DialogPermissionStep> createState() => _DialogPermissionStepState();
}

class _DialogPermissionStepState extends State<_DialogPermissionStep> {
  bool? _granted;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final granted = await widget.checkStatus();
    if (mounted) setState(() => _granted = granted);
  }

  Future<void> _request() async {
    setState(() => _loading = true);
    final granted = await widget.onRequest();
    if (mounted) {
      setState(() {
        _granted = granted;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final granted = _granted ?? false;

    return _StepLayout(
      icon: widget.icon,
      title: widget.getTitle(l10n),
      body: widget.getBody(l10n),
      buttons: [
        if (granted) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.onboardingGranted,
              style: TextStyle(fontSize: 14, color: palette.historyText),
              textAlign: TextAlign.center,
            ),
          ),
          FilledButton(
            onPressed: widget.onNext,
            child: Text(l10n.onboardingNext),
          ),
        ] else ...[
          FilledButton(
            onPressed: _loading ? null : _request,
            child: _loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.background,
                    ),
                  )
                : Text(widget.getButtonLabel(l10n)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onNext,
            child: Text(l10n.onboardingSkip),
          ),
        ],
      ],
    );
  }
}

// ── Steps 3-4: Settings-based permissions (overlay, battery) ─────────────────

class _SettingsPermissionStep extends StatefulWidget {
  const _SettingsPermissionStep({
    required this.icon,
    required this.getTitle,
    required this.getBody,
    required this.getButtonLabel,
    required this.openSettings,
    required this.checkStatus,
    required this.onNext,
  });

  final IconData icon;
  final String Function(AppLocalizations) getTitle;
  final String Function(AppLocalizations) getBody;
  final String Function(AppLocalizations) getButtonLabel;
  final Future<void> Function() openSettings;
  final Future<bool> Function() checkStatus;
  final VoidCallback onNext;

  @override
  State<_SettingsPermissionStep> createState() =>
      _SettingsPermissionStepState();
}

class _SettingsPermissionStepState extends State<_SettingsPermissionStep>
    with WidgetsBindingObserver {
  bool? _granted;
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkStatus();
  }

  Future<void> _checkStatus() async {
    final granted = await widget.checkStatus();
    if (mounted) setState(() => _granted = granted);
  }

  Future<void> _openSettings() async {
    setState(() => _opened = true);
    await widget.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final granted = _granted ?? false;

    return _StepLayout(
      icon: widget.icon,
      title: widget.getTitle(l10n),
      body: widget.getBody(l10n),
      buttons: [
        if (granted) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.onboardingGranted,
              style: TextStyle(fontSize: 14, color: palette.historyText),
              textAlign: TextAlign.center,
            ),
          ),
          FilledButton(
            onPressed: widget.onNext,
            child: Text(l10n.onboardingNext),
          ),
        ] else ...[
          FilledButton(
            onPressed: _openSettings,
            child: Text(widget.getButtonLabel(l10n)),
          ),
          if (_opened)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.onboardingOpenedSettings,
                style: TextStyle(fontSize: 13, color: palette.historyText),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onNext,
            child: Text(l10n.onboardingSkip),
          ),
        ],
      ],
    );
  }
}

// ── Step 5: Region detection ──────────────────────────────────────────────────

class _RegionStep extends ConsumerStatefulWidget {
  const _RegionStep({required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<_RegionStep> createState() => _RegionStepState();
}

class _RegionStepState extends ConsumerState<_RegionStep> {
  bool _probeComplete = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _probeComplete = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);

    final regionAsync = ref.watch(regionProvider);
    final region = regionAsync.asData?.value ?? RegionResult.unknown;
    final isDetecting = region == RegionResult.unknown && !_probeComplete;

    // Cancel timer when region is known
    ref.listen(regionProvider, (_, next) {
      final r = next.asData?.value;
      if (r != null && r != RegionResult.unknown) {
        _timer?.cancel();
        if (mounted) setState(() => _probeComplete = true);
      }
    });

    final hintText = switch (region) {
      RegionResult.mainland => l10n.onboardingRegionMainlandHint,
      RegionResult.overseas => l10n.onboardingRegionOverseasHint,
      RegionResult.unknown =>
        _probeComplete ? l10n.onboardingRegionUnknownHint : null,
    };

    return _StepLayout(
      icon: Icons.public,
      title: l10n.onboardingRegionTitle,
      body: l10n.onboardingRegionBody,
      buttons: [
        if (isDetecting)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.historyText,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.onboardingRegionDetecting,
                  style: TextStyle(fontSize: 14, color: palette.historyText),
                ),
              ],
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              l10n.onboardingRegionResult(l10n.regionName(region)),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: palette.focusText,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (hintText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                hintText,
                style: TextStyle(fontSize: 13, color: palette.historyText),
                textAlign: TextAlign.center,
              ),
            ),
        ],
        FilledButton(
          onPressed: isDetecting ? null : widget.onDone,
          child: Text(l10n.onboardingDone),
        ),
        if (isDetecting)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: widget.onDone,
              child: Text(l10n.onboardingSkip),
            ),
          ),
      ],
    );
  }
}
