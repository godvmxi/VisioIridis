import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/asr_controller.dart';
import 'app_colors.dart';
import 'widgets/action_button.dart';
import 'widgets/focus_card.dart';
import 'widgets/history_list.dart';
import 'widgets/language_bar.dart';

/// 主页面：顶部控制栏 / 历史区 / 最新卡片 / 底部主按键。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(asrControllerProvider.select((s) => s.errorId), (_, _) {
      final message = ref.read(asrControllerProvider).errorMessage;
      if (message == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
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
}
