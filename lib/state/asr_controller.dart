import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../asr/asr_engine.dart';
import '../asr/asr_language.dart';
import '../asr/prepared_model.dart';
import '../asr/sherpa_asr_engine.dart';
import '../asr/tag_formatter.dart';
import '../models/subtitle_item.dart';
import 'asr_state.dart';

/// 当前使用的识别引擎。
final asrEngineProvider = Provider<AsrEngine>((ref) {
  final engine = SherpaAsrEngine();
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

  /// 加载 [model] 并开始拾音。失败时记录错误，不抛出。
  Future<void> startListening(PreparedModel model) async {
    if (state.isListening || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      await _engine.start(model, state.enabledLanguages);
      if (!ref.mounted) return;
      state = state.copyWith(isListening: true, isLoading: false);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.withError('$e');
    }
  }

  Future<void> stopListening() async {
    if (!state.isListening) return;
    await _engine.stop();
    if (!ref.mounted) return;
    state = state.copyWith(isListening: false, currentPendingText: '');
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
      case AsrError(:final message):
        state = state.withError(message);
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
