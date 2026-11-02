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
  });

  final bool isListening;

  /// 正在加载模型、启动录音。
  final bool isLoading;

  /// 最近一次错误；[errorId] 每次出错加 1，界面据此弹出提示。
  final String? errorMessage;
  final int errorId;
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
    );
  }

  AsrEngineState withError(String message) => AsrEngineState(
        enabledLanguages: enabledLanguages,
        pendingSegment: pendingSegment + 1,
        history: history,
        errorMessage: message,
        errorId: errorId + 1,
      );
}
