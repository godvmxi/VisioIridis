import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../asr/asr_engine.dart';
import '../asr/asr_language.dart';
import '../asr/mock_asr_engine.dart';
import '../asr/tag_formatter.dart';
import '../models/subtitle_item.dart';
import 'asr_state.dart';

/// 当前使用的识别引擎。接入 sherpa-onnx 后替换为真实实现。
final asrEngineProvider = Provider<AsrEngine>((ref) {
  final engine = MockAsrEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

final asrControllerProvider =
    NotifierProvider<AsrController, AsrEngineState>(AsrController.new);

class AsrController extends Notifier<AsrEngineState> {
  late AsrEngine _engine;
  int _nextId = 0;

  @override
  AsrEngineState build() {
    _engine = ref.watch(asrEngineProvider);
    final sub = _engine.events.listen(_onEvent);
    ref.onDispose(sub.cancel);
    return const AsrEngineState();
  }

  Future<void> toggleListening() async {
    if (state.isListening) {
      await _engine.stop();
      if (!ref.mounted) return;
      state = state.copyWith(isListening: false, currentPendingText: '');
    } else {
      await _engine.start(state.enabledLanguages);
      if (!ref.mounted) return;
      state = state.copyWith(isListening: true);
    }
  }

  /// 切换某语言的勾选。若会导致三者全部取消则拒绝并返回 false（PRD 4.1 防空保护）。
  bool toggleLanguage(AsrLanguage language) {
    final enabled = {...state.enabledLanguages};
    if (enabled.contains(language)) {
      if (enabled.length == 1) return false;
      enabled.remove(language);
    } else {
      enabled.add(language);
    }
    state = state.copyWith(enabledLanguages: enabled);
    if (state.isListening) _engine.updateLanguages(enabled);
    return true;
  }

  void clearHistory() {
    state = state.copyWith(
      history: const [],
      currentPendingText: '',
      pendingSegment: state.pendingSegment + 1,
    );
  }

  void _onEvent(AsrEvent event) {
    switch (event) {
      case AsrPartial(:final text):
        state = state.copyWith(currentPendingText: TagFormatter.cleanText(text));
      case AsrFinal():
        _commit(event);
    }
  }

  void _commit(AsrFinal result) {
    final item = SubtitleItem(
      id: '${_nextId++}',
      timestamp: DateTime.now(),
      text: TagFormatter.cleanText(result.text),
      lang: TagFormatter.normalize(result.lang),
      emotionTag: TagFormatter.normalize(result.emotion),
      eventTag: TagFormatter.normalize(result.event),
    );
    // 既无文字又无需上屏的事件（如纯 BGM），直接丢弃。
    final keep = item.displayText.isNotEmpty;
    state = state.copyWith(
      history: keep ? [...state.history, item] : null,
      currentPendingText: '',
      pendingSegment: state.pendingSegment + 1,
    );
  }
}
