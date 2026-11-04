import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../state/asr_controller.dart';
import '../state/config_update_provider.dart';
import '../state/region_detector.dart';
import 'app_colors.dart';
import 'widgets/action_button.dart';
import 'widgets/focus_card.dart';
import 'widgets/history_list.dart';
import 'widgets/language_bar.dart';

/// 主页面：顶部控制栏 / 历史区 / 最新卡片 / 底部主按键。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _updateDialogShown = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(asrControllerProvider.select((s) => s.errorId), (_, _) {
      final message = ref.read(asrControllerProvider).errorMessage;
      if (message == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });

    ref.listen<AsyncValue<ConfigUpdateInfo?>>(configUpdateProvider, (_, next) {
      next.whenData((update) {
        if (update == null || _updateDialogShown) return;
        _updateDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showUpdateDialog(update);
        });
      });
    });

    return Scaffold(
      backgroundColor: AppPalette.of(context).background,
      body: const SafeArea(
        child: Column(
          children: [
            LanguageBar(),
            Expanded(child: HistoryList()),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FocusCard(),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ActionButton(),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateDialog(ConfigUpdateInfo update) {
    final l10n = AppLocalizations.of(context);
    final regionName = l10n.regionName(update.region);

    showDialog<_UpdateChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.configUpdateTitle),
        content: Text(
          l10n.configUpdateBody(
            regionName,
            update.currentVersion,
            update.newVersion,
          ),
          style: const TextStyle(fontSize: 15, height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _UpdateChoice.later),
            child: Text(l10n.configUpdateLater),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _UpdateChoice.apply),
            child: Text(l10n.configUpdateNow),
          ),
        ],
      ),
    ).then((choice) {
      if (!mounted) return;
      final notifier = ref.read(configUpdateProvider.notifier);
      if (choice == _UpdateChoice.apply) {
        notifier.acceptAndReload();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).configUpdated)),
          );
      } else {
        notifier.markShown();
      }
    });
  }
}

enum _UpdateChoice { later, apply }
