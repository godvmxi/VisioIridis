// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Visio Iridis';

  @override
  String get settings => 'Settings';

  @override
  String get interfaceLanguage => 'Display language';

  @override
  String get followSystem => 'System default';

  @override
  String get fontSize => 'Font size';

  @override
  String get fontStandard => 'Normal';

  @override
  String get fontLarge => 'Large';

  @override
  String get fontHuge => 'X-Large';

  @override
  String get fontExtraHuge => 'XX-Large';

  @override
  String get fontGiant => 'Huge';

  @override
  String get bold => 'Bold';

  @override
  String get boldHint =>
      'Use bold for all caption text, including history and the floating window';

  @override
  String get colorMode => 'Color scheme';

  @override
  String get colorYellowOnBlack => 'Yellow on black';

  @override
  String get colorWhiteOnBlack => 'White on black';

  @override
  String get colorBlackOnWhite => 'Black on white';

  @override
  String get colorCustom => 'Custom';

  @override
  String get backgroundColor => 'Background';

  @override
  String get textColor => 'Text color';

  @override
  String backgroundSwatch(int index) {
    return 'Background color $index';
  }

  @override
  String textSwatch(int index) {
    return 'Text color $index';
  }

  @override
  String lowContrast(String ratio) {
    return 'Low contrast ($ratio:1). Captions may be hard to read; 4.5:1 or higher is recommended.';
  }

  @override
  String get floatingWindow => 'Floating window';

  @override
  String get showFloatingWindow => 'Show floating window';

  @override
  String get overlayPermissionTitle => 'Permission needed';

  @override
  String get overlayPermissionBody =>
      'Floating captions need the \"Display over other apps\" permission.\nFind this app in system settings, allow it, then come back.';

  @override
  String get overlayPermissionDenied =>
      'Permission not granted. The floating window is off.';

  @override
  String get goEnable => 'Open settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get recognitionModel => 'Recognition model';

  @override
  String get recognitionModelHint =>
      'Choose a model for each language. Scores are out of 10; \"Auto\" picks the highest-scoring model. Changes apply when you tap \"Start\", and you\'ll be asked to download a new model if needed.';

  @override
  String modelConfigLoadFailed(String error) {
    return 'Failed to load model config: $error';
  }

  @override
  String get previewHistory => 'Hi, what time is the meeting today?';

  @override
  String get previewFocus => 'See you at 3 p.m.';

  @override
  String get swatchSample => 'Aa';

  @override
  String get language => 'Language';

  @override
  String chooseModelFor(String language) {
    return 'Model for $language';
  }

  @override
  String get auto => 'Auto';

  @override
  String get noModelAvailable => 'No model available';

  @override
  String autoPicks(String model, int score) {
    return 'Highest-scoring model: $model  $score/10';
  }

  @override
  String modelScoreTitle(String model, String language, int score) {
    return '$model    $language $score/10';
  }

  @override
  String supports(String scores) {
    return 'Supports: $scores';
  }

  @override
  String get startRecognition => 'Start';

  @override
  String get stopRecognition => 'Stop';

  @override
  String get loadingModel => 'Loading recognition model...';

  @override
  String get waitingSpeech => 'Waiting for speech...';

  @override
  String get preparingModel => 'Preparing model...';

  @override
  String get restoringModel => 'Restoring saved model...';

  @override
  String downloadingModel(String model) {
    return 'Downloading $model';
  }

  @override
  String get verifyingModel => 'Verifying model files...';

  @override
  String get savingModel => 'Saving model...';

  @override
  String get backToLatest => 'Latest';

  @override
  String get soundSource => 'Sound source';

  @override
  String get microphone => 'Mic';

  @override
  String get speaker => 'Speaker';

  @override
  String get recognitionLanguage => 'Recognition language';

  @override
  String get clearScreen => 'Clear';

  @override
  String currentModel(String model) {
    return 'Current model: $model';
  }

  @override
  String get keepOneLanguage => 'Keep at least one language';

  @override
  String get alsoAutoDetect => 'Also detected automatically';

  @override
  String get alsoAutoDetectHint =>
      'These languages are recognized when more than one language is selected (auto-detect).';

  @override
  String get listSeparator => ', ';

  @override
  String get clearConfirm => 'Clear all caption history?';

  @override
  String get clearConfirmButton => 'Clear';

  @override
  String get noModelForLanguages => 'No model supports the selected languages';

  @override
  String modelSwitched(String model) {
    return 'Recognition model switched to \"$model\"';
  }

  @override
  String modelPrepFailed(String error) {
    return 'Failed to prepare model: $error';
  }

  @override
  String get modelChangedTitle => 'Model changed';

  @override
  String modelChangedFrom(String from, String to) {
    return 'The recognition model changed from \"$from\" to \"$to\".';
  }

  @override
  String get downloadModelTitle => 'Download model';

  @override
  String downloadNeededWithVad(String model, String size) {
    return '\"$model\" and the voice detection model need to be downloaded ($size).';
  }

  @override
  String downloadNeeded(String model, String size) {
    return '\"$model\" needs to be downloaded ($size).';
  }

  @override
  String get wifiSuggestion => 'Wi-Fi is recommended.';

  @override
  String useModelFirst(String model) {
    return 'Use \"$model\" for now';
  }

  @override
  String get download => 'Download';

  @override
  String get speakerNotice =>
      'Due to system limits, Speaker mode only captures sound played by apps such as media players. Phone calls and voice/video calls can\'t be captured.';

  @override
  String get micPermissionDenied => 'Microphone permission is required';

  @override
  String recordingInterrupted(String error) {
    return 'Recording stopped: $error';
  }

  @override
  String get speakerDenied =>
      'Speaker capture wasn\'t allowed. Switched back to the mic.';

  @override
  String get speakerEnded => 'Speaker capture ended. Switched back to the mic.';

  @override
  String switchBackFailed(String error) {
    return 'Couldn\'t switch back to the mic: $error';
  }

  @override
  String modelLoadFailed(String error) {
    return 'Failed to load model: $error';
  }

  @override
  String recognitionFailed(String error) {
    return 'Recognition error: $error';
  }

  @override
  String get eventLaughter => 'laughter';

  @override
  String get eventApplause => 'applause';

  @override
  String get eventCry => 'crying';

  @override
  String get langZh => 'Mandarin';

  @override
  String get langYue => 'Cantonese';

  @override
  String get langEn => 'English';

  @override
  String get langHenan => 'Henan dialect';

  @override
  String get langJa => 'Japanese';

  @override
  String get langKo => 'Korean';

  @override
  String get overlayBack => 'Open';

  @override
  String get overlayExit => 'Exit';

  @override
  String get overlayConfirmExit => 'Exit the app?';

  @override
  String get notificationChannel => 'Live captions';

  @override
  String get notificationChannelDescription => 'Shown while captioning';

  @override
  String get notificationTitle => 'Live captions on';

  @override
  String get notificationText => 'Tap to open the app';

  @override
  String get systemAudioNotificationChannel => 'System audio captions';

  @override
  String get systemAudioNotificationTitle =>
      'Captioning audio played on this device';
}
