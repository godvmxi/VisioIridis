import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/asr_controller.dart';
import '../app_colors.dart';

/// 底部开始/停止主按键（PRD 4.4）。
class ActionButton extends ConsumerWidget {
  const ActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isListening =
        ref.watch(asrControllerProvider.select((s) => s.isListening));

    return SizedBox(
      height: 60,
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: isListening ? AppColors.stop : AppColors.listening,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          HapticFeedback.heavyImpact();
          ref.read(asrControllerProvider.notifier).toggleListening();
        },
        icon: Icon(
          isListening ? Icons.stop_rounded : Icons.mic_rounded,
          size: 28,
        ),
        label: Text(isListening ? '停止识别' : '开始识别'),
      ),
    );
  }
}
