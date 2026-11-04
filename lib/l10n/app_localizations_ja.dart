// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Visio Iridis';

  @override
  String get settings => '設定';

  @override
  String get interfaceLanguage => '表示言語';

  @override
  String get followSystem => 'システムに従う';

  @override
  String get fontSize => '文字サイズ';

  @override
  String get fontStandard => '標準';

  @override
  String get fontLarge => '大';

  @override
  String get fontHuge => '特大';

  @override
  String get fontExtraHuge => '超特大';

  @override
  String get fontGiant => '最大';

  @override
  String get bold => '太字';

  @override
  String get boldHint => '履歴とフローティングウィンドウを含め、すべての字幕を太字で表示します';

  @override
  String get colorMode => '配色';

  @override
  String get colorYellowOnBlack => '黒地に黄色';

  @override
  String get colorWhiteOnBlack => '黒地に白';

  @override
  String get colorBlackOnWhite => '白地に黒';

  @override
  String get colorCustom => 'カスタム';

  @override
  String get backgroundColor => '背景色';

  @override
  String get textColor => '文字色';

  @override
  String backgroundSwatch(int index) {
    return '背景色 $index';
  }

  @override
  String textSwatch(int index) {
    return '文字色 $index';
  }

  @override
  String lowContrast(String ratio) {
    return 'コントラストが低すぎます（$ratio:1）。字幕が読みにくい可能性があります。4.5:1 以上をおすすめします。';
  }

  @override
  String get forceSplit => '強制区切り';

  @override
  String get forceSplitHint =>
      '認識結果が出ないままこの時間が経つと、強制的に文を区切ります。周囲の雑音で無音を検出できないときに便利です。「オフ」にすると音声検出だけで区切ります。';

  @override
  String get forceSplitOff => 'オフ';

  @override
  String get floatingWindow => 'フローティングウィンドウ';

  @override
  String get showFloatingWindow => 'フローティングウィンドウを表示';

  @override
  String get overlayPermissionTitle => '権限が必要です';

  @override
  String get overlayPermissionBody =>
      'フローティング字幕には「他のアプリの上に重ねて表示」の権限が必要です。\nシステム設定でこのアプリを探して許可し、戻ってきてください。';

  @override
  String get overlayPermissionDenied => '権限がないため、フローティングウィンドウはオフになりました';

  @override
  String get goEnable => '設定を開く';

  @override
  String get cancel => 'キャンセル';

  @override
  String get done => '完了';

  @override
  String get recognitionModel => '認識モデル';

  @override
  String get recognitionModelHint =>
      '言語ごとに使用するモデルを選べます。スコアは 10 点満点で、「自動」は最もスコアの高いモデルを選びます。変更は「開始」をタップしたときに反映され、必要に応じて新しいモデルのダウンロードを案内します。';

  @override
  String modelConfigLoadFailed(String error) {
    return 'モデル設定を読み込めませんでした：$error';
  }

  @override
  String get previewHistory => 'こんにちは、今日の会議は何時ですか？';

  @override
  String get previewFocus => '午後 3 時に会いましょう';

  @override
  String get swatchSample => 'あA';

  @override
  String get language => '言語';

  @override
  String chooseModelFor(String language) {
    return '「$language」のモデル';
  }

  @override
  String get auto => '自動';

  @override
  String get noModelAvailable => '使えるモデルがありません';

  @override
  String autoPicks(String model, int score) {
    return '最高スコアのモデル：$model  $score 点';
  }

  @override
  String modelScoreTitle(String model, String language, int score) {
    return '$model    $language $score 点';
  }

  @override
  String supports(String scores) {
    return '対応：$scores';
  }

  @override
  String get startRecognition => '開始';

  @override
  String get stopRecognition => '停止';

  @override
  String get loadingModel => '認識モデルを読み込み中...';

  @override
  String get waitingSpeech => '音声を待っています...';

  @override
  String get preparingModel => 'モデルを準備中...';

  @override
  String get restoringModel => '保存済みのモデルを復元中...';

  @override
  String downloadingModel(String model) {
    return '$model をダウンロード中';
  }

  @override
  String get verifyingModel => 'モデルファイルを確認中...';

  @override
  String get savingModel => 'モデルを保存中...';

  @override
  String get backToLatest => '最新へ';

  @override
  String get soundSource => '音声の入力元';

  @override
  String get microphone => 'マイク';

  @override
  String get speaker => 'スピーカー';

  @override
  String get recognitionLanguage => '認識言語';

  @override
  String get clearScreen => '消去';

  @override
  String currentModel(String model) {
    return '現在のモデル：$model';
  }

  @override
  String get notSupportedByModel => '現在のモデルは非対応のため認識しません';

  @override
  String get keepOneLanguage => '少なくとも 1 つの言語を選んでください';

  @override
  String get alsoAutoDetect => '自動で認識できる言語';

  @override
  String get alsoAutoDetectHint => '複数の言語を選ぶと（自動判別）、これらの言語も認識されます。';

  @override
  String get listSeparator => '、';

  @override
  String get clearConfirm => '字幕の履歴をすべて消去しますか？';

  @override
  String get clearConfirmButton => '消去';

  @override
  String get noModelForLanguages => '選択した言語に対応するモデルがありません';

  @override
  String modelSwitched(String model) {
    return '認識モデルを「$model」に切り替えました';
  }

  @override
  String modelPrepFailed(String error) {
    return 'モデルの準備に失敗しました：$error';
  }

  @override
  String get modelChangedTitle => 'モデルが変わりました';

  @override
  String modelChangedFrom(String from, String to) {
    return '認識モデルが「$from」から「$to」に変わりました。';
  }

  @override
  String get downloadModelTitle => 'モデルのダウンロード';

  @override
  String downloadNeededWithVad(String model, String size) {
    return '「$model」と音声検出モデルのダウンロードが必要です（$size）。';
  }

  @override
  String downloadNeeded(String model, String size) {
    return '「$model」のダウンロードが必要です（$size）。';
  }

  @override
  String get wifiSuggestion => 'Wi-Fi での利用をおすすめします。';

  @override
  String useModelFirst(String model) {
    return 'ひとまず「$model」を使う';
  }

  @override
  String get download => 'ダウンロード';

  @override
  String get speakerNotice =>
      'システムの制限により、スピーカーモードでは動画アプリなどが再生する音声のみ認識できます。電話や音声・ビデオ通話は認識できません。';

  @override
  String get micPermissionDenied => 'マイクの権限が必要です';

  @override
  String recordingInterrupted(String error) {
    return '録音が中断されました：$error';
  }

  @override
  String get speakerDenied => 'スピーカーの音声取得が許可されなかったため、マイクに戻しました';

  @override
  String get speakerEnded => 'スピーカーの音声取得が終了したため、マイクに戻しました';

  @override
  String switchBackFailed(String error) {
    return 'マイクに戻せませんでした：$error';
  }

  @override
  String modelLoadFailed(String error) {
    return 'モデルを読み込めませんでした：$error';
  }

  @override
  String recognitionFailed(String error) {
    return '認識エラー：$error';
  }

  @override
  String get eventLaughter => '笑い声';

  @override
  String get eventApplause => '拍手';

  @override
  String get eventCry => '泣き声';

  @override
  String get langZh => '中国語（標準）';

  @override
  String get langYue => '広東語';

  @override
  String get langEn => '英語';

  @override
  String get langHenan => '河南語';

  @override
  String get langFr => 'フランス語';

  @override
  String get langDe => 'ドイツ語';

  @override
  String get langSichuan => '四川語';

  @override
  String get langDongbei => '東北方言';

  @override
  String get langShandong => '山東方言';

  @override
  String get langWu => '呉語（上海語）';

  @override
  String get langMinnan => '閩南語';

  @override
  String get langJa => '日本語';

  @override
  String get langKo => '韓国語';

  @override
  String get overlayBack => '戻る';

  @override
  String get overlayExit => '終了';

  @override
  String get overlayConfirmExit => 'アプリを終了しますか？';

  @override
  String get notificationChannel => 'リアルタイム字幕';

  @override
  String get notificationChannelDescription => '字幕の認識中に表示されます';

  @override
  String get notificationTitle => 'リアルタイム字幕を認識中';

  @override
  String get notificationText => 'タップしてアプリに戻る';

  @override
  String get systemAudioNotificationChannel => 'システム音声の字幕';

  @override
  String get systemAudioNotificationTitle => 'この端末で再生中の音声を認識しています';

  @override
  String get regionMainland => '中国本土';

  @override
  String get regionOverseas => '中国本土以外';

  @override
  String get regionUnknown => '不明';

  @override
  String get configUpdateTitle => 'モデル設定の更新があります';

  @override
  String configUpdateBody(String region, int currentVersion, int newVersion) {
    return '地域：$region\n設定：v$currentVersion → v$newVersion\n\n新しい設定をバックグラウンドで保存しました。認識モデルの更新が含まれている可能性があります。今すぐ適用してモデルのダウンロードを確認しますか？';
  }

  @override
  String get configUpdateLater => '後で';

  @override
  String get configUpdateNow => '今すぐ適用';

  @override
  String get configUpdated => '設定を更新しました。「開始」をタップすると新しいモデルを確認してダウンロードします';

  @override
  String get onboardingWelcomeTitle => 'Visio Iridis へようこそ';

  @override
  String get onboardingWelcomeBody =>
      'Visio Iridis は聴覚に障害のある方のためのオフライン リアルタイム字幕ツールです。すべての処理は端末内で行われます。\n\nまず必要な権限を設定しましょう。';

  @override
  String get onboardingMicTitle => 'マイク';

  @override
  String get onboardingMicBody =>
      '音声認識にはマイクへのアクセスが必要です。スピーカーモード（システム音声の取得）にも必要です。';

  @override
  String get onboardingMicButton => 'マイクを許可';

  @override
  String get onboardingNotifTitle => '通知';

  @override
  String get onboardingNotifBody =>
      '字幕の認識中は常駐通知でアプリの動作を維持します。Android 13 以降では手動で許可する必要があります。';

  @override
  String get onboardingNotifButton => '通知を許可';

  @override
  String get onboardingOverlayTitle => 'フローティングウィンドウ';

  @override
  String get onboardingOverlayBody =>
      '他のアプリを使いながら、フローティングウィンドウで字幕を確認できます。システム設定で有効にする必要があります。';

  @override
  String get onboardingOverlayButton => '重ねて表示の設定を開く';

  @override
  String get onboardingBatteryTitle => 'バックグラウンド動作';

  @override
  String get onboardingBatteryBody =>
      'システムによって認識が中断されないよう、システム設定でこのアプリを電池の最適化の対象外にしてください。';

  @override
  String get onboardingBatteryButton => '電池の制限を解除';

  @override
  String get onboardingRegionTitle => '地域の検出';

  @override
  String get onboardingRegionBody =>
      'ネットワーク環境を確認し、モデル設定の更新とダウンロードに最適な配信元を選びます。';

  @override
  String get onboardingRegionDetecting => '検出中…';

  @override
  String onboardingRegionResult(String region) {
    return '検出結果：$region';
  }

  @override
  String get onboardingRegionMainlandHint => 'モデル設定とダウンロードには Gitee を使用します';

  @override
  String get onboardingRegionOverseasHint => 'モデル設定とダウンロードには GitHub を使用します';

  @override
  String get onboardingRegionUnknownHint => '地域を判別できませんでした。バックグラウンドで検出を続けます';

  @override
  String get onboardingDone => 'はじめる';

  @override
  String get onboardingSkip => 'スキップ';

  @override
  String get onboardingGranted => '許可済み';

  @override
  String get onboardingOpenedSettings => '設定を開きました。終わったら戻ってきてください';

  @override
  String get onboardingNext => '次へ';
}
