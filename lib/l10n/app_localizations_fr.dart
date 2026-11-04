// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Visio Iridis';

  @override
  String get settings => 'Paramètres';

  @override
  String get interfaceLanguage => 'Langue d\'affichage';

  @override
  String get followSystem => 'Langue du système';

  @override
  String get fontSize => 'Taille du texte';

  @override
  String get fontStandard => 'Normale';

  @override
  String get fontLarge => 'Grande';

  @override
  String get fontHuge => 'Très grande';

  @override
  String get fontExtraHuge => 'Extra grande';

  @override
  String get fontGiant => 'Énorme';

  @override
  String get bold => 'Gras';

  @override
  String get boldHint =>
      'Afficher tous les sous-titres en gras, y compris l\'historique et la fenêtre flottante';

  @override
  String get colorMode => 'Couleurs';

  @override
  String get colorYellowOnBlack => 'Jaune sur noir';

  @override
  String get colorWhiteOnBlack => 'Blanc sur noir';

  @override
  String get colorBlackOnWhite => 'Noir sur blanc';

  @override
  String get colorCustom => 'Personnalisé';

  @override
  String get backgroundColor => 'Arrière-plan';

  @override
  String get textColor => 'Couleur du texte';

  @override
  String backgroundSwatch(int index) {
    return 'Couleur d\'arrière-plan $index';
  }

  @override
  String textSwatch(int index) {
    return 'Couleur du texte $index';
  }

  @override
  String lowContrast(String ratio) {
    return 'Contraste faible ($ratio:1). Les sous-titres risquent d\'être difficiles à lire ; 4,5:1 ou plus est recommandé.';
  }

  @override
  String get forceSplit => 'Découpage forcé';

  @override
  String get forceSplitHint =>
      'Force une fin de phrase après ce délai sans résultat. Utile quand le bruit ambiant empêche de détecter les silences. Choisissez « Désactivé » pour vous fier uniquement à la détection vocale.';

  @override
  String get forceSplitOff => 'Désactivé';

  @override
  String get floatingWindow => 'Fenêtre flottante';

  @override
  String get showFloatingWindow => 'Afficher la fenêtre flottante';

  @override
  String get overlayPermissionTitle => 'Autorisation requise';

  @override
  String get overlayPermissionBody =>
      'Les sous-titres flottants nécessitent l\'autorisation « Afficher par-dessus les autres applis ».\nTrouvez cette appli dans les paramètres du système, autorisez-la, puis revenez.';

  @override
  String get overlayPermissionDenied =>
      'Autorisation refusée. La fenêtre flottante est désactivée.';

  @override
  String get goEnable => 'Ouvrir les paramètres';

  @override
  String get cancel => 'Annuler';

  @override
  String get done => 'OK';

  @override
  String get recognitionModel => 'Modèle de reconnaissance';

  @override
  String get recognitionModelHint =>
      'Choisissez une langue, puis un dialecte, puis un modèle. Les notes sont sur 10 et les modèles sont classés de la meilleure à la moins bonne note. Les changements s\'appliquent quand vous appuyez sur « Démarrer », et le téléchargement d\'un nouveau modèle vous sera proposé si nécessaire.';

  @override
  String modelConfigLoadFailed(String error) {
    return 'Impossible de charger la configuration des modèles : $error';
  }

  @override
  String get previewHistory =>
      'Bonjour, à quelle heure est la réunion aujourd\'hui ?';

  @override
  String get previewFocus => 'À 15 h, à tout à l\'heure.';

  @override
  String get swatchSample => 'Aa';

  @override
  String get language => 'Langue';

  @override
  String get languageGroup => 'Langue';

  @override
  String get dialect => 'Dialecte';

  @override
  String get langGroupChinese => 'Chinois';

  @override
  String autoDetectLanguages(String languages) {
    return 'Détection auto : $languages';
  }

  @override
  String currentSelection(String path) {
    return 'Actuel : $path';
  }

  @override
  String chooseModelFor(String language) {
    return 'Modèle pour : $language';
  }

  @override
  String get auto => 'Auto';

  @override
  String get noModelAvailable => 'Aucun modèle disponible';

  @override
  String modelScoreTitle(String model, String language, int score) {
    return '$model    $language $score/10';
  }

  @override
  String supports(String scores) {
    return 'Langues : $scores';
  }

  @override
  String get startRecognition => 'Démarrer';

  @override
  String get stopRecognition => 'Arrêter';

  @override
  String get loadingModel => 'Chargement du modèle...';

  @override
  String get waitingSpeech => 'En attente de parole...';

  @override
  String get preparingModel => 'Préparation du modèle...';

  @override
  String get restoringModel => 'Restauration du modèle enregistré...';

  @override
  String downloadingModel(String model) {
    return 'Téléchargement de $model';
  }

  @override
  String get verifyingModel => 'Vérification des fichiers du modèle...';

  @override
  String get savingModel => 'Enregistrement du modèle...';

  @override
  String get backToLatest => 'Récent';

  @override
  String get soundSource => 'Source du son';

  @override
  String get microphone => 'Micro';

  @override
  String get speaker => 'Haut-parleur';

  @override
  String get recognitionLanguage => 'Langue reconnue';

  @override
  String get clearScreen => 'Effacer';

  @override
  String currentModel(String model) {
    return 'Modèle actuel : $model';
  }

  @override
  String get listSeparator => ', ';

  @override
  String get clearConfirm => 'Effacer tout l\'historique des sous-titres ?';

  @override
  String get clearConfirmButton => 'Effacer';

  @override
  String get noModelForLanguages => 'Aucun modèle de reconnaissance disponible';

  @override
  String modelSwitched(String model) {
    return 'Modèle de reconnaissance changé pour « $model »';
  }

  @override
  String modelPrepFailed(String error) {
    return 'Échec de la préparation du modèle : $error';
  }

  @override
  String get modelChangedTitle => 'Modèle modifié';

  @override
  String modelChangedFrom(String from, String to) {
    return 'Le modèle de reconnaissance est passé de « $from » à « $to ».';
  }

  @override
  String get downloadModelTitle => 'Télécharger le modèle';

  @override
  String downloadNeededWithVad(String model, String size) {
    return '« $model » et le modèle de détection vocale doivent être téléchargés ($size).';
  }

  @override
  String downloadNeeded(String model, String size) {
    return '« $model » doit être téléchargé ($size).';
  }

  @override
  String get wifiSuggestion => 'Le Wi-Fi est recommandé.';

  @override
  String useModelFirst(String model) {
    return 'Utiliser « $model » pour l\'instant';
  }

  @override
  String get download => 'Télécharger';

  @override
  String get speakerNotice =>
      'En raison des limites du système, le mode Haut-parleur ne capte que le son joué par des applis comme les lecteurs multimédias. Les appels téléphoniques et les appels audio/vidéo ne peuvent pas être captés.';

  @override
  String get micPermissionDenied => 'L\'autorisation du micro est requise';

  @override
  String recordingInterrupted(String error) {
    return 'Enregistrement interrompu : $error';
  }

  @override
  String get speakerDenied =>
      'La capture du haut-parleur n\'a pas été autorisée. Retour au micro.';

  @override
  String get speakerEnded =>
      'La capture du haut-parleur s\'est arrêtée. Retour au micro.';

  @override
  String switchBackFailed(String error) {
    return 'Impossible de revenir au micro : $error';
  }

  @override
  String modelLoadFailed(String error) {
    return 'Impossible de charger le modèle : $error';
  }

  @override
  String recognitionFailed(String error) {
    return 'Erreur de reconnaissance : $error';
  }

  @override
  String get eventLaughter => 'rires';

  @override
  String get eventApplause => 'applaudissements';

  @override
  String get eventCry => 'pleurs';

  @override
  String get langZh => 'Mandarin';

  @override
  String get langYue => 'Cantonais';

  @override
  String get langEn => 'Anglais';

  @override
  String get langHenan => 'Dialecte du Henan';

  @override
  String get langFr => 'Français';

  @override
  String get langDe => 'Allemand';

  @override
  String get langSichuan => 'Sichuanais';

  @override
  String get langDongbei => 'Mandarin du Nord-Est';

  @override
  String get langShandong => 'Dialecte du Shandong';

  @override
  String get langWu => 'Wu (shanghaïen)';

  @override
  String get langMinnan => 'Hokkien (minnan)';

  @override
  String get langJa => 'Japonais';

  @override
  String get langKo => 'Coréen';

  @override
  String get overlayBack => 'Ouvrir';

  @override
  String get overlayExit => 'Quitter';

  @override
  String get overlayConfirmExit => 'Quitter l\'appli ?';

  @override
  String get notificationChannel => 'Sous-titres en direct';

  @override
  String get notificationChannelDescription =>
      'Affiché pendant le sous-titrage';

  @override
  String get notificationTitle => 'Sous-titres en direct activés';

  @override
  String get notificationText => 'Appuyez pour ouvrir l\'appli';

  @override
  String get systemAudioNotificationChannel => 'Sous-titres du son système';

  @override
  String get systemAudioNotificationTitle =>
      'Sous-titrage du son joué sur cet appareil';

  @override
  String get regionMainland => 'Chine continentale';

  @override
  String get regionOverseas => 'International';

  @override
  String get regionUnknown => 'Inconnue';

  @override
  String get configUpdateTitle => 'Mise à jour de la configuration des modèles';

  @override
  String configUpdateBody(String region, int currentVersion, int newVersion) {
    return 'Région : $region\nConfiguration : v$currentVersion → v$newVersion\n\nUne nouvelle configuration a été enregistrée en arrière-plan. Elle peut inclure des modèles de reconnaissance mis à jour. L\'appliquer maintenant et vérifier les téléchargements de modèles ?';
  }

  @override
  String get configUpdateLater => 'Plus tard';

  @override
  String get configUpdateNow => 'Appliquer';

  @override
  String get configUpdated =>
      'Configuration mise à jour : appuyez sur « Démarrer » pour vérifier et télécharger les nouveaux modèles';

  @override
  String get onboardingWelcomeTitle => 'Bienvenue dans Visio Iridis';

  @override
  String get onboardingWelcomeBody =>
      'Visio Iridis est un outil de sous-titrage en temps réel hors ligne conçu pour les personnes malentendantes. Tout fonctionne localement sur votre appareil.\n\nCommençons par configurer les autorisations nécessaires.';

  @override
  String get onboardingMicTitle => 'Micro';

  @override
  String get onboardingMicBody =>
      'La reconnaissance vocale a besoin d\'accéder au micro. Le mode Haut-parleur (capture du son système) en a aussi besoin.';

  @override
  String get onboardingMicButton => 'Autoriser le micro';

  @override
  String get onboardingNotifTitle => 'Notifications';

  @override
  String get onboardingNotifBody =>
      'Une notification permanente maintient l\'appli active pendant le sous-titrage. Sur Android 13 et versions ultérieures, l\'autorisation doit être accordée manuellement.';

  @override
  String get onboardingNotifButton => 'Autoriser les notifications';

  @override
  String get onboardingOverlayTitle => 'Fenêtre flottante';

  @override
  String get onboardingOverlayBody =>
      'Affichez les sous-titres dans une fenêtre flottante pendant que vous utilisez d\'autres applis. À activer dans les paramètres du système.';

  @override
  String get onboardingOverlayButton =>
      'Ouvrir les paramètres de superposition';

  @override
  String get onboardingBatteryTitle => 'Activité en arrière-plan';

  @override
  String get onboardingBatteryBody =>
      'Pour éviter que le système n\'interrompe la reconnaissance, excluez cette appli de l\'optimisation de la batterie dans les paramètres du système.';

  @override
  String get onboardingBatteryButton => 'Lever les limites de batterie';

  @override
  String get onboardingRegionTitle => 'Détection de la région';

  @override
  String get onboardingRegionBody =>
      'Vérification de votre réseau pour choisir la meilleure source de mises à jour de configuration et de téléchargement des modèles.';

  @override
  String get onboardingRegionDetecting => 'Détection…';

  @override
  String onboardingRegionResult(String region) {
    return 'Région détectée : $region';
  }

  @override
  String get onboardingRegionMainlandHint =>
      'La configuration et les téléchargements utiliseront Gitee';

  @override
  String get onboardingRegionOverseasHint =>
      'La configuration et les téléchargements utiliseront GitHub';

  @override
  String get onboardingRegionUnknownHint =>
      'Région incertaine : la détection se poursuivra en arrière-plan';

  @override
  String get onboardingDone => 'Commencer';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingGranted => 'Autorisé';

  @override
  String get onboardingOpenedSettings =>
      'Paramètres ouverts : revenez une fois terminé';

  @override
  String get onboardingNext => 'Suivant';
}
