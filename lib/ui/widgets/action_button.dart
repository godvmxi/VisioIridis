import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/asr_controller.dart';
import '../../state/model_providers.dart';
import '../app_colors.dart';
import '../model_preparer.dart';

/// 底部开始/停止主按键（PRD 4.4）。准备模型期间禁用（PRD 4.5.5）。
class ActionButton extends ConsumerWidget {
  const ActionButton({super.key});

  Future<void> _onPressed(BuildContext context, WidgetRef ref) async {
    HapticFeedback.heavyImpact();
    final asr = ref.read(asrControllerProvider.notifier);
    if (ref.read(asrControllerProvider).isListening) {
      await asr.stopListening();
      return;
    }
    final model = await ref.read(modelPreparerProvider).ensureReady(context);
    if (model != null) await asr.startListening(model);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isListening =
        ref.watch(asrControllerProvider.select((s) => s.isListening));
    final preparing = ref.watch(modelPrepProvider) != null ||
        ref.watch(asrControllerProvider.select((s) => s.isLoading));

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
        onPressed: preparing ? null : () => _onPressed(context, ref),
        icon: Icon(
          isListening ? Icons.stop_rounded : Icons.mic_rounded,
          size: 28,
        ),
        label: Text(isListening ? '停止识别' : '开始识别'),
      ),
    );
  }
}
