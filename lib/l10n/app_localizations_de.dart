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
  String get forceSplit => 'Erzwungene Trennung';

  @override
  String get forceSplitHint =>
      'Erzwingt ein Satzende, wenn so lange kein Ergebnis kam. Nützlich, wenn Hintergrundgeräusche die Pausenerkennung verhindern. Bei „Aus“ wird nur die Spracherkennung verwendet.';

  @override
  String get forceSplitOff => 'Aus';

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
      'Wähle eine Sprache, dann einen Dialekt, dann ein Modell. Die Bewertung reicht bis 10, Modelle sind nach Bewertung sortiert. Änderungen gelten, wenn du auf „Starten“ tippst; bei Bedarf wirst du gefragt, ein neues Modell herunterzuladen.';

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
  String get languageGroup => 'Sprache';

  @override
  String get dialect => 'Dialekt';

  @override
  String get langGroupChinese => 'Chinesisch';

  @override
  String autoDetectLanguages(String languages) {
    return 'Automatisch erkennen: $languages';
  }

  @override
  String currentSelection(String path) {
    return 'Aktuell: $path';
  }

  @override
  String chooseModelFor(String language) {
    return 'Modell für $language';
  }

  @override
  String get auto => 'Automatisch';

  @override
  String get noModelAvailable => 'Kein Modell verfügbar';

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
  String get listSeparator => ', ';

  @override
  String get clearConfirm => 'Gesamten Untertitelverlauf löschen?';

  @override
  String get clearConfirmButton => 'Löschen';

  @override
  String get noModelForLanguages => 'Kein Erkennungsmodell verfügbar';

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
  String get langWu => 'Wu (Shanghainesisch)';

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

  @override
  String get regionMainland => 'Festlandchina';

  @override
  String get regionOverseas => 'International';

  @override
  String get regionUnknown => 'Unbekannt';

  @override
  String get configUpdateTitle => 'Update der Modellkonfiguration verfügbar';

  @override
  String configUpdateBody(String region, int currentVersion, int newVersion) {
    return 'Region: $region\nKonfiguration: v$currentVersion → v$newVersion\n\nEine neue Konfiguration wurde im Hintergrund gespeichert. Sie kann aktualisierte Erkennungsmodelle enthalten. Jetzt übernehmen und nach Modell-Downloads suchen?';
  }

  @override
  String get configUpdateLater => 'Später';

  @override
  String get configUpdateNow => 'Jetzt übernehmen';

  @override
  String get configUpdated =>
      'Konfiguration aktualisiert – tippe auf „Starten“, um neue Modelle zu prüfen und herunterzuladen';

  @override
  String get onboardingWelcomeTitle => 'Willkommen bei Visio Iridis';

  @override
  String get onboardingWelcomeBody =>
      'Visio Iridis ist ein Offline-Tool für Live-Untertitel, entwickelt für Menschen mit Hörverlust. Alles läuft lokal auf deinem Gerät.\n\nRichten wir zuerst die nötigen Berechtigungen ein.';

  @override
  String get onboardingMicTitle => 'Mikrofon';

  @override
  String get onboardingMicBody =>
      'Die Spracherkennung benötigt Zugriff auf das Mikrofon. Auch der Lautsprechermodus (Aufnahme des Systemtons) braucht ihn.';

  @override
  String get onboardingMicButton => 'Mikrofon erlauben';

  @override
  String get onboardingNotifTitle => 'Benachrichtigungen';

  @override
  String get onboardingNotifBody =>
      'Eine dauerhafte Benachrichtigung hält die App während der Untertitelung aktiv. Ab Android 13 muss sie manuell erlaubt werden.';

  @override
  String get onboardingNotifButton => 'Benachrichtigungen erlauben';

  @override
  String get onboardingOverlayTitle => 'Schwebendes Fenster';

  @override
  String get onboardingOverlayBody =>
      'Sieh Untertitel in einem schwebenden Fenster, während du andere Apps nutzt. Muss in den Systemeinstellungen aktiviert werden.';

  @override
  String get onboardingOverlayButton => 'Einblende-Einstellungen öffnen';

  @override
  String get onboardingBatteryTitle => 'Hintergrundaktivität';

  @override
  String get onboardingBatteryBody =>
      'Damit das System die Erkennung nicht unterbricht, nimm diese App in den Systemeinstellungen von der Akkuoptimierung aus.';

  @override
  String get onboardingBatteryButton => 'Akkubeschränkung aufheben';

  @override
  String get onboardingRegionTitle => 'Region erkennen';

  @override
  String get onboardingRegionBody =>
      'Deine Netzwerkumgebung wird geprüft, um die beste Quelle für Konfigurations-Updates und Modell-Downloads zu wählen.';

  @override
  String get onboardingRegionDetecting => 'Wird erkannt…';

  @override
  String onboardingRegionResult(String region) {
    return 'Erkannt: $region';
  }

  @override
  String get onboardingRegionMainlandHint =>
      'Konfiguration und Downloads nutzen Gitee';

  @override
  String get onboardingRegionOverseasHint =>
      'Konfiguration und Downloads nutzen GitHub';

  @override
  String get onboardingRegionUnknownHint =>
      'Region unklar – die Erkennung läuft im Hintergrund weiter';

  @override
  String get onboardingDone => 'Los geht\'s';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingGranted => 'Erlaubt';

  @override
  String get onboardingOpenedSettings =>
      'Einstellungen geöffnet – komm zurück, wenn du fertig bist';

  @override
  String get onboardingNext => 'Weiter';
}
