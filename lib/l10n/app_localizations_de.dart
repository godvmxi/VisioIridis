// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Visio Iridis';

  @override
  String get settings => 'Einstellungen';

  @override
  String get interfaceLanguage => 'Anzeigesprache';

  @override
  String get followSystem => 'Systemsprache';

  @override
  String get fontSize => 'Schriftgröße';

  @override
  String get fontStandard => 'Normal';

  @override
  String get fontLarge => 'Groß';

  @override
  String get fontHuge => 'Sehr groß';

  @override
  String get fontExtraHuge => 'Extra groß';

  @override
  String get fontGiant => 'Riesig';

  @override
  String get bold => 'Fett';

  @override
  String get boldHint =>
      'Alle Untertitel fett anzeigen, auch den Verlauf und das schwebende Fenster';

  @override
  String get colorMode => 'Farbschema';

  @override
  String get colorYellowOnBlack => 'Gelb auf Schwarz';

  @override
  String get colorWhiteOnBlack => 'Weiß auf Schwarz';

  @override
  String get colorBlackOnWhite => 'Schwarz auf Weiß';

  @override
  String get colorCustom => 'Benutzerdefiniert';

  @override
  String get backgroundColor => 'Hintergrund';

  @override
  String get textColor => 'Textfarbe';

  @override
  String backgroundSwatch(int index) {
    return 'Hintergrundfarbe $index';
  }

  @override
  String textSwatch(int index) {
    return 'Textfarbe $index';
  }

  @override
  String lowContrast(String ratio) {
    return 'Geringer Kontrast ($ratio:1). Die Untertitel sind möglicherweise schwer lesbar; 4,5:1 oder mehr wird empfohlen.';
  }

  @override
  String get floatingWindow => 'Schwebendes Fenster';

  @override
  String get showFloatingWindow => 'Schwebendes Fenster anzeigen';

  @override
  String get overlayPermissionTitle => 'Berechtigung erforderlich';

  @override
  String get overlayPermissionBody =>
      'Schwebende Untertitel benötigen die Berechtigung „Über anderen Apps einblenden“.\nSuche diese App in den Systemeinstellungen, erlaube sie und kehre dann zurück.';

  @override
  String get overlayPermissionDenied =>
      'Berechtigung nicht erteilt. Das schwebende Fenster ist aus.';

  @override
  String get goEnable => 'Einstellungen öffnen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get done => 'Fertig';

  @override
  String get recognitionModel => 'Erkennungsmodell';

  @override
  String get recognitionModelHint =>
      'Wähle für jede Sprache ein Modell. Die Bewertung reicht bis 10; „Automatisch“ wählt das am besten bewertete Modell. Änderungen gelten, wenn du auf „Starten“ tippst; bei Bedarf wirst du gefragt, ein neues Modell herunterzuladen.';

  @override
  String modelConfigLoadFailed(String error) {
    return 'Modellkonfiguration konnte nicht geladen werden: $error';
  }

  @override
  String get previewHistory => 'Hallo, wann ist das Meeting heute?';

  @override
  String get previewFocus => 'Bis um 15 Uhr.';

  @override
  String get swatchSample => 'Aa';

  @override
  String get language => 'Sprache';

  @override
  String chooseModelFor(String language) {
    return 'Modell für $language';
  }

  @override
  String get auto => 'Automatisch';

  @override
  String get noModelAvailable => 'Kein Modell verfügbar';

  @override
  String autoPicks(String model, int score) {
    return 'Am besten bewertet: $model  $score/10';
  }

  @override
  String modelScoreTitle(String model, String language, int score) {
    return '$model    $language $score/10';
  }

  @override
  String supports(String scores) {
    return 'Unterstützt: $scores';
  }

  @override
  String get startRecognition => 'Starten';

  @override
  String get stopRecognition => 'Stoppen';

  @override
  String get loadingModel => 'Erkennungsmodell wird geladen...';

  @override
  String get waitingSpeech => 'Warte auf Sprache...';

  @override
  String get preparingModel => 'Modell wird vorbereitet...';

  @override
  String get restoringModel => 'Gespeichertes Modell wird wiederhergestellt...';

  @override
  String downloadingModel(String model) {
    return '$model wird heruntergeladen';
  }

  @override
  String get verifyingModel => 'Modelldateien werden geprüft...';

  @override
  String get savingModel => 'Modell wird gespeichert...';

  @override
  String get backToLatest => 'Neueste';

  @override
  String get soundSource => 'Tonquelle';

  @override
  String get microphone => 'Mikro';

  @override
  String get speaker => 'Lautsprecher';

  @override
  String get recognitionLanguage => 'Erkennungssprache';

  @override
  String get clearScreen => 'Löschen';

  @override
  String currentModel(String model) {
    return 'Aktuelles Modell: $model';
  }

  @override
  String get notSupportedByModel => 'Vom aktuellen Modell nicht unterstützt';

  @override
  String get keepOneLanguage => 'Mindestens eine Sprache auswählen';

  @override
  String get alsoAutoDetect => 'Wird ebenfalls automatisch erkannt';

  @override
  String get alsoAutoDetectHint =>
      'Diese Sprachen werden erkannt, wenn mehr als eine Sprache ausgewählt ist (automatische Erkennung).';

  @override
  String get listSeparator => ', ';

  @override
  String get clearConfirm => 'Gesamten Untertitelverlauf löschen?';

  @override
  String get clearConfirmButton => 'Löschen';

  @override
  String get noModelForLanguages =>
      'Kein Modell unterstützt die ausgewählten Sprachen';

  @override
  String modelSwitched(String model) {
    return 'Erkennungsmodell gewechselt zu „$model“';
  }

  @override
  String modelPrepFailed(String error) {
    return 'Modell konnte nicht vorbereitet werden: $error';
  }

  @override
  String get modelChangedTitle => 'Modell geändert';

  @override
  String modelChangedFrom(String from, String to) {
    return 'Das Erkennungsmodell wurde von „$from“ zu „$to“ geändert.';
  }

  @override
  String get downloadModelTitle => 'Modell herunterladen';

  @override
  String downloadNeededWithVad(String model, String size) {
    return '„$model“ und das Spracherkennungsmodell müssen heruntergeladen werden ($size).';
  }

  @override
  String downloadNeeded(String model, String size) {
    return '„$model“ muss heruntergeladen werden ($size).';
  }

  @override
  String get wifiSuggestion => 'WLAN wird empfohlen.';

  @override
  String useModelFirst(String model) {
    return 'Vorerst „$model“ verwenden';
  }

  @override
  String get download => 'Herunterladen';

  @override
  String get speakerNotice =>
      'Aufgrund von Systembeschränkungen erfasst der Lautsprechermodus nur Ton, der von Apps wie Mediaplayern abgespielt wird. Telefonate sowie Sprach- und Videoanrufe können nicht erfasst werden.';

  @override
  String get micPermissionDenied => 'Mikrofonberechtigung erforderlich';

  @override
  String recordingInterrupted(String error) {
    return 'Aufnahme beendet: $error';
  }

  @override
  String get speakerDenied =>
      'Lautsprecheraufnahme nicht erlaubt. Zurück zum Mikrofon.';

  @override
  String get speakerEnded =>
      'Lautsprecheraufnahme beendet. Zurück zum Mikrofon.';

  @override
  String switchBackFailed(String error) {
    return 'Wechsel zum Mikrofon fehlgeschlagen: $error';
  }

  @override
  String modelLoadFailed(String error) {
    return 'Modell konnte nicht geladen werden: $error';
  }

  @override
  String recognitionFailed(String error) {
    return 'Erkennungsfehler: $error';
  }

  @override
  String get eventLaughter => 'Lachen';

  @override
  String get eventApplause => 'Applaus';

  @override
  String get eventCry => 'Weinen';

  @override
  String get langZh => 'Mandarin';

  @override
  String get langYue => 'Kantonesisch';

  @override
  String get langEn => 'Englisch';

  @override
  String get langHenan => 'Henan-Dialekt';

  @override
  String get langFr => 'Französisch';

  @override
  String get langDe => 'Deutsch';

  @override
  String get langSichuan => 'Sichuanesisch';

  @override
  String get langDongbei => 'Nordost-Mandarin';

  @override
  String get langShandong => 'Shandong-Dialekt';

  @override
  String get langShanghai => 'Shanghainesisch';

  @override
  String get langMinnan => 'Hokkien (Minnan)';

  @override
  String get langJa => 'Japanisch';

  @override
  String get langKo => 'Koreanisch';

  @override
  String get overlayBack => 'Öffnen';

  @override
  String get overlayExit => 'Beenden';

  @override
  String get overlayConfirmExit => 'App beenden?';

  @override
  String get notificationChannel => 'Live-Untertitel';

  @override
  String get notificationChannelDescription =>
      'Wird während der Untertitelung angezeigt';

  @override
  String get notificationTitle => 'Live-Untertitel aktiv';

  @override
  String get notificationText => 'Tippen, um die App zu öffnen';

  @override
  String get systemAudioNotificationChannel => 'Untertitel für Systemton';

  @override
  String get systemAudioNotificationTitle =>
      'Ton, der auf diesem Gerät abgespielt wird, wird untertitelt';
}
