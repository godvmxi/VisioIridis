import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'widgets/action_button.dart';
import 'widgets/focus_card.dart';
import 'widgets/history_list.dart';
import 'widgets/language_bar.dart';

/// 主页面：顶部控制栏 / 历史区 / 最新卡片 / 底部主按键。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
