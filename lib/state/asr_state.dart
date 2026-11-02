import '../asr/asr_engine.dart';
import '../asr/asr_language.dart';
import '../models/subtitle_item.dart';

/// 引擎与界面状态（PRD 6.2）。
class AsrEngineState {
  const AsrEngineState({
    this.isListening = false,
    this.enabledLanguages = const {
      AsrLanguage.mandarin,
      AsrLanguage.cantonese,
      AsrLanguage.english,
    },
    this.currentPendingText = '',
    this.pendingSegment = 0,
    this.history = const [],
    this.isLoading = false,
    this.errorMessage,
    this.errorId = 0,
    this.audioInput = AudioInput.microphone,
  });

  final bool isListening;

  /// 正在加载模型、启动录音。
  final bool isLoading;

  /// 最近一次错误；[errorId] 每次出错加 1，界面据此弹出提示。
  final String? errorMessage;
  final int errorId;

  /// 当前识别的声音来源（PRD 4.8）。
  final AudioInput audioInput;
  final Set<AsrLanguage> enabledLanguages;

  /// 最新卡片上的临时结果。
  final String currentPendingText;

  /// 每沉淀一句加 1，最新卡片据此触发“上移淡出”动画。
  final int pendingSegment;

  /// 按时间正序，最新在末尾（PRD 4.2）。
  final List<SubtitleItem> history;

  String get languageParam => AsrLanguage.languageParamFor(enabledLanguages);

  AsrEngineState copyWith({
    bool? isListening,
    Set<AsrLanguage>? enabledLanguages,
    String? currentPendingText,
    int? pendingSegment,
    List<SubtitleItem>? history,
    bool? isLoading,
    AudioInput? audioInput,
  }) {
    return AsrEngineState(
      isListening: isListening ?? this.isListening,
      enabledLanguages: enabledLanguages ?? this.enabledLanguages,
      currentPendingText: currentPendingText ?? this.currentPendingText,
      pendingSegment: pendingSegment ?? this.pendingSegment,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      errorId: errorId,
      audioInput: audioInput ?? this.audioInput,
    );
  }

  /// 提示一条消息，不改变识别状态。
  AsrEngineState withNotice(String message) => AsrEngineState(
        isListening: isListening,
        enabledLanguages: enabledLanguages,
        currentPendingText: currentPendingText,
        pendingSegment: pendingSegment,
        history: history,
        isLoading: isLoading,
        errorMessage: message,
        errorId: errorId + 1,
        audioInput: audioInput,
      );

  AsrEngineState withError(String message) => AsrEngineState(
        enabledLanguages: enabledLanguages,
        pendingSegment: pendingSegment + 1,
        history: history,
        errorMessage: message,
        errorId: errorId + 1,
      );
}
