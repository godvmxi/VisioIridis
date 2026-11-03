import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../asr/asr_engine.dart';
import '../asr/asr_language.dart';
import '../asr/prepared_model.dart';
import '../asr/sherpa_asr_engine.dart';
import '../asr/tag_formatter.dart';
import '../l10n/l10n.dart';
import '../models/subtitle_item.dart';
import 'asr_state.dart';
import 'script_converter.dart';

/// 当前使用的识别引擎。
final asrEngineProvider = Provider<AsrEngine>((ref) {
  final engine = SherpaAsrEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

final asrControllerProvider = NotifierProvider<AsrController, AsrEngineState>(
  AsrController.new,
);

class AsrController extends Notifier<AsrEngineState> {
  late AsrEngine _engine;
  int _nextId = 0;

  /// 等待繁简转换的事件按到达顺序依次处理；[_converting] 为排队中的事件数。
  Future<void> _queue = Future.value();
  int _converting = 0;

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
      // 开始前已选择“喇叭”时，启动后立即切到系统播放的声音。
      if (state.audioInput == AudioInput.systemAudio) {
        await _applyAudioInput(AudioInput.systemAudio);
      }
    } catch (e) {
      if (!ref.mounted) return;
      state = state.withError(_describe(e));
    }
  }

  AppLocalizations get _l10n => ref.read(appLocalizationsProvider);

  String _describe(Object error) => error is AsrStartException
      ? _l10n.asrIssue(error.issue, error.detail)
      : '$error';

  Future<void> stopListening() async {
    if (!state.isListening) return;
    await _engine.stop();
    if (!ref.mounted) return;
    state = state.copyWith(isListening: false, currentPendingText: '');
  }

  bool _switchingInput = false;

  /// “声音来源”：麦克风或喇叭（系统播放的声音，PRD 4.8）。
  /// 未在识别时只记录选择，下次开始识别时生效；识别中立即切换。
  Future<void> setAudioInput(AudioInput input) async {
    if (state.audioInput == input || _switchingInput) return;
    if (!state.isListening) {
      state = state.copyWith(audioInput: input);
      if (input == AudioInput.systemAudio) {
        state = state.withNotice(_l10n.speakerNotice);
      }
      return;
    }
    await _applyAudioInput(input);
  }

  /// 切换失败时引擎已回到麦克风，识别继续，只给出提示。
  Future<void> _applyAudioInput(AudioInput input) async {
    _switchingInput = true;
    try {
      await _engine.setAudioInput(input);
      if (!ref.mounted) return;
      state = state.copyWith(audioInput: input, currentPendingText: '');
      if (input == AudioInput.systemAudio) {
        state = state.withNotice(_l10n.speakerNotice);
      }
    } catch (e) {
      if (!ref.mounted) return;
      state = state
          .copyWith(audioInput: AudioInput.microphone, currentPendingText: '')
          .withNotice(_describe(e));
    } finally {
      _switchingInput = false;
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
    final script = ref.read(chineseScriptProvider);
    // 无需转换且没有排队的事件时同步处理，避免多一帧延迟。
    if (script == null && _converting == 0) {
      _apply(event);
      return;
    }
    _converting++;
    _queue = _queue.then((_) async {
      try {
        final converted = await _convert(event, script);
        if (ref.mounted) _apply(converted);
      } finally {
        _converting--;
      }
    });
  }

  /// 把识别文字转换为界面语言对应的字形（简体 / 繁体）。
  Future<AsrEvent> _convert(AsrEvent event, ChineseScript? script) async {
    if (script == null) return event;
    final converter = ref.read(scriptConverterProvider);
    return switch (event) {
      AsrPartial(:final text) => AsrPartial(
        await converter.convert(text, script),
      ),
      AsrFinal(:final text, :final lang, :final emotion, event: final tag) =>
        AsrFinal(
          await converter.convert(text, script),
          lang: lang,
          emotion: emotion,
          event: tag,
        ),
      _ => event,
    };
  }

  void _apply(AsrEvent event) {
    switch (event) {
      case AsrPartial(:final text):
        state = state.copyWith(
          currentPendingText: TagFormatter.cleanText(text),
        );
      case AsrFinal():
        _commit(event);
      case AsrError(:final issue, :final detail):
        state = state.withError(_l10n.asrIssue(issue, detail));
      case AsrInputChanged(:final input, :final reason):
        state = state
            .copyWith(audioInput: input, currentPendingText: '')
            .withNotice(_l10n.asrIssue(reason));
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
      audioInput: state.audioInput,
    );
    // 既无文字又无需上屏的事件（如纯 BGM），直接丢弃。
    final keep = item.displayText(_l10n.eventName).isNotEmpty;
    state = state.copyWith(
      history: keep ? [...state.history, item] : null,
      currentPendingText: '',
      pendingSegment: state.pendingSegment + 1,
    );
  }
}
