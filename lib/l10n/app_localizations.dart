import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'伊利斯之视'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @interfaceLanguage.
  ///
  /// In zh, this message translates to:
  /// **'界面语言'**
  String get interfaceLanguage;

  /// No description provided for @followSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get followSystem;

  /// No description provided for @fontSize.
  ///
  /// In zh, this message translates to:
  /// **'字体大小'**
  String get fontSize;

  /// No description provided for @fontStandard.
  ///
  /// In zh, this message translates to:
  /// **'标准'**
  String get fontStandard;

  /// No description provided for @fontLarge.
  ///
  /// In zh, this message translates to:
  /// **'大'**
  String get fontLarge;

  /// No description provided for @fontHuge.
  ///
  /// In zh, this message translates to:
  /// **'特大'**
  String get fontHuge;

  /// No description provided for @fontExtraHuge.
  ///
  /// In zh, this message translates to:
  /// **'超大'**
  String get fontExtraHuge;

  /// No description provided for @fontGiant.
  ///
  /// In zh, this message translates to:
  /// **'巨大'**
  String get fontGiant;

  /// No description provided for @bold.
  ///
  /// In zh, this message translates to:
  /// **'粗体'**
  String get bold;

  /// No description provided for @boldHint.
  ///
  /// In zh, this message translates to:
  /// **'历史记录、浮动字幕等所有字幕文字使用粗体'**
  String get boldHint;

  /// No description provided for @colorMode.
  ///
  /// In zh, this message translates to:
  /// **'配色模式'**
  String get colorMode;

  /// No description provided for @colorYellowOnBlack.
  ///
  /// In zh, this message translates to:
  /// **'黄字黑底'**
  String get colorYellowOnBlack;

  /// No description provided for @colorWhiteOnBlack.
  ///
  /// In zh, this message translates to:
  /// **'白字黑底'**
  String get colorWhiteOnBlack;

  /// No description provided for @colorBlackOnWhite.
  ///
  /// In zh, this message translates to:
  /// **'黑字白底'**
  String get colorBlackOnWhite;

  /// No description provided for @colorCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get colorCustom;

  /// No description provided for @backgroundColor.
  ///
  /// In zh, this message translates to:
  /// **'背景色'**
  String get backgroundColor;

  /// No description provided for @textColor.
  ///
  /// In zh, this message translates to:
  /// **'文字颜色'**
  String get textColor;

  /// No description provided for @backgroundSwatch.
  ///
  /// In zh, this message translates to:
  /// **'背景颜色 {index}'**
  String backgroundSwatch(int index);

  /// No description provided for @textSwatch.
  ///
  /// In zh, this message translates to:
  /// **'文字颜色 {index}'**
  String textSwatch(int index);

  /// No description provided for @lowContrast.
  ///
  /// In zh, this message translates to:
  /// **'对比度较低（{ratio}:1），字幕可能不易看清，建议不低于 4.5:1'**
  String lowContrast(String ratio);

  /// No description provided for @floatingWindow.
  ///
  /// In zh, this message translates to:
  /// **'浮动窗'**
  String get floatingWindow;

  /// No description provided for @showFloatingWindow.
  ///
  /// In zh, this message translates to:
  /// **'显示浮动窗'**
  String get showFloatingWindow;

  /// No description provided for @overlayPermissionTitle.
  ///
  /// In zh, this message translates to:
  /// **'需要悬浮窗权限'**
  String get overlayPermissionTitle;

  /// No description provided for @overlayPermissionBody.
  ///
  /// In zh, this message translates to:
  /// **'浮动字幕需要“显示在其他应用上层”权限。\n接下来请在系统设置中找到本应用并允许，然后返回。'**
  String get overlayPermissionBody;

  /// No description provided for @overlayPermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'未获得悬浮窗权限，浮动窗未开启'**
  String get overlayPermissionDenied;

  /// No description provided for @goEnable.
  ///
  /// In zh, this message translates to:
  /// **'去开启'**
  String get goEnable;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @recognitionModel.
  ///
  /// In zh, this message translates to:
  /// **'识别模型'**
  String get recognitionModel;

  /// No description provided for @recognitionModelHint.
  ///
  /// In zh, this message translates to:
  /// **'为每种语言指定使用的模型，打分为 10 分制；“自动”选择打分最高的模型。修改后点击“开始识别”时生效，需要时会提示下载新模型。'**
  String get recognitionModelHint;

  /// No description provided for @modelConfigLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'模型配置加载失败：{error}'**
  String modelConfigLoadFailed(String error);

  /// No description provided for @previewHistory.
  ///
  /// In zh, this message translates to:
  /// **'你好，请问今天几点开会？'**
  String get previewHistory;

  /// No description provided for @previewFocus.
  ///
  /// In zh, this message translates to:
  /// **'下午三点见'**
  String get previewFocus;

  /// No description provided for @swatchSample.
  ///
  /// In zh, this message translates to:
  /// **'字'**
  String get swatchSample;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @chooseModelFor.
  ///
  /// In zh, this message translates to:
  /// **'为“{language}”选择模型'**
  String chooseModelFor(String language);

  /// No description provided for @auto.
  ///
  /// In zh, this message translates to:
  /// **'自动'**
  String get auto;

  /// No description provided for @noModelAvailable.
  ///
  /// In zh, this message translates to:
  /// **'没有可用模型'**
  String get noModelAvailable;

  /// No description provided for @autoPicks.
  ///
  /// In zh, this message translates to:
  /// **'选打分最高的模型：{model}  {score} 分'**
  String autoPicks(String model, int score);

  /// No description provided for @modelScoreTitle.
  ///
  /// In zh, this message translates to:
  /// **'{model}    {language} {score} 分'**
  String modelScoreTitle(String model, String language, int score);

  /// No description provided for @supports.
  ///
  /// In zh, this message translates to:
  /// **'支持：{scores}'**
  String supports(String scores);

  /// No description provided for @startRecognition.
  ///
  /// In zh, this message translates to:
  /// **'开始识别'**
  String get startRecognition;

  /// No description provided for @stopRecognition.
  ///
  /// In zh, this message translates to:
  /// **'停止识别'**
  String get stopRecognition;

  /// No description provided for @loadingModel.
  ///
  /// In zh, this message translates to:
  /// **'正在加载识别模型...'**
  String get loadingModel;

  /// No description provided for @waitingSpeech.
  ///
  /// In zh, this message translates to:
  /// **'等待语音输入...'**
  String get waitingSpeech;

  /// No description provided for @preparingModel.
  ///
  /// In zh, this message translates to:
  /// **'正在准备模型...'**
  String get preparingModel;

  /// No description provided for @restoringModel.
  ///
  /// In zh, this message translates to:
  /// **'正在从保存目录恢复模型...'**
  String get restoringModel;

  /// No description provided for @downloadingModel.
  ///
  /// In zh, this message translates to:
  /// **'正在下载 {model}'**
  String downloadingModel(String model);

  /// No description provided for @verifyingModel.
  ///
  /// In zh, this message translates to:
  /// **'正在校验模型文件...'**
  String get verifyingModel;

  /// No description provided for @savingModel.
  ///
  /// In zh, this message translates to:
  /// **'正在保存模型...'**
  String get savingModel;

  /// No description provided for @backToLatest.
  ///
  /// In zh, this message translates to:
  /// **'回到最新'**
  String get backToLatest;

  /// No description provided for @soundSource.
  ///
  /// In zh, this message translates to:
  /// **'声音来源'**
  String get soundSource;

  /// No description provided for @microphone.
  ///
  /// In zh, this message translates to:
  /// **'麦克风'**
  String get microphone;

  /// No description provided for @speaker.
  ///
  /// In zh, this message translates to:
  /// **'喇叭'**
  String get speaker;

  /// No description provided for @recognitionLanguage.
  ///
  /// In zh, this message translates to:
  /// **'识别语言'**
  String get recognitionLanguage;

  /// No description provided for @clearScreen.
  ///
  /// In zh, this message translates to:
  /// **'清屏'**
  String get clearScreen;

  /// No description provided for @currentModel.
  ///
  /// In zh, this message translates to:
  /// **'当前模型：{model}'**
  String currentModel(String model);

  /// No description provided for @notSupportedByModel.
  ///
  /// In zh, this message translates to:
  /// **'当前模型不支持，不会识别'**
  String get notSupportedByModel;

  /// No description provided for @keepOneLanguage.
  ///
  /// In zh, this message translates to:
  /// **'至少保留一种识别语言'**
  String get keepOneLanguage;

  /// No description provided for @alsoAutoDetect.
  ///
  /// In zh, this message translates to:
  /// **'还可自动识别'**
  String get alsoAutoDetect;

  /// No description provided for @alsoAutoDetectHint.
  ///
  /// In zh, this message translates to:
  /// **'勾选多种语言（自动识别）时可识别这些语言。'**
  String get alsoAutoDetectHint;

  /// No description provided for @listSeparator.
  ///
  /// In zh, this message translates to:
  /// **'、'**
  String get listSeparator;

  /// No description provided for @clearConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认清空所有历史字幕记录？'**
  String get clearConfirm;

  /// No description provided for @clearConfirmButton.
  ///
  /// In zh, this message translates to:
  /// **'确认清空'**
  String get clearConfirmButton;

  /// No description provided for @noModelForLanguages.
  ///
  /// In zh, this message translates to:
  /// **'当前语言组合没有可用的识别模型'**
  String get noModelForLanguages;

  /// No description provided for @modelSwitched.
  ///
  /// In zh, this message translates to:
  /// **'识别模型已切换为「{model}」'**
  String modelSwitched(String model);

  /// No description provided for @modelPrepFailed.
  ///
  /// In zh, this message translates to:
  /// **'模型准备失败：{error}'**
  String modelPrepFailed(String error);

  /// No description provided for @modelChangedTitle.
  ///
  /// In zh, this message translates to:
  /// **'识别模型已变更'**
  String get modelChangedTitle;

  /// No description provided for @modelChangedFrom.
  ///
  /// In zh, this message translates to:
  /// **'识别模型由「{from}」变更为「{to}」。'**
  String modelChangedFrom(String from, String to);

  /// No description provided for @downloadModelTitle.
  ///
  /// In zh, this message translates to:
  /// **'下载识别模型'**
  String get downloadModelTitle;

  /// No description provided for @downloadNeededWithVad.
  ///
  /// In zh, this message translates to:
  /// **'需要下载「{model}」及语音检测模型，共 {size}。'**
  String downloadNeededWithVad(String model, String size);

  /// No description provided for @downloadNeeded.
  ///
  /// In zh, this message translates to:
  /// **'需要下载「{model}」，共 {size}。'**
  String downloadNeeded(String model, String size);

  /// No description provided for @wifiSuggestion.
  ///
  /// In zh, this message translates to:
  /// **'建议连接 Wi-Fi 后再下载。'**
  String get wifiSuggestion;

  /// No description provided for @useModelFirst.
  ///
  /// In zh, this message translates to:
  /// **'先用「{model}」'**
  String useModelFirst(String model);

  /// No description provided for @download.
  ///
  /// In zh, this message translates to:
  /// **'下载'**
  String get download;

  /// No description provided for @speakerNotice.
  ///
  /// In zh, this message translates to:
  /// **'因系统限制，喇叭模式只能识别播放器等应用播放的声音，无法识别电话和语音/视频通话的声音'**
  String get speakerNotice;

  /// No description provided for @micPermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'需要麦克风权限才能识别'**
  String get micPermissionDenied;

  /// No description provided for @recordingInterrupted.
  ///
  /// In zh, this message translates to:
  /// **'录音中断：{error}'**
  String recordingInterrupted(String error);

  /// No description provided for @speakerDenied.
  ///
  /// In zh, this message translates to:
  /// **'未获得录制喇叭声音的授权，已切回麦克风'**
  String get speakerDenied;

  /// No description provided for @speakerEnded.
  ///
  /// In zh, this message translates to:
  /// **'喇叭声音录制已结束，已切回麦克风'**
  String get speakerEnded;

  /// No description provided for @switchBackFailed.
  ///
  /// In zh, this message translates to:
  /// **'切回麦克风失败：{error}'**
  String switchBackFailed(String error);

  /// No description provided for @modelLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'模型加载失败：{error}'**
  String modelLoadFailed(String error);

  /// No description provided for @recognitionFailed.
  ///
  /// In zh, this message translates to:
  /// **'识别出错：{error}'**
  String recognitionFailed(String error);

  /// No description provided for @eventLaughter.
  ///
  /// In zh, this message translates to:
  /// **'笑声'**
  String get eventLaughter;

  /// No description provided for @eventApplause.
  ///
  /// In zh, this message translates to:
  /// **'掌声'**
  String get eventApplause;

  /// No description provided for @eventCry.
  ///
  /// In zh, this message translates to:
  /// **'哭泣声'**
  String get eventCry;

  /// No description provided for @langZh.
  ///
  /// In zh, this message translates to:
  /// **'普通话'**
  String get langZh;

  /// No description provided for @langYue.
  ///
  /// In zh, this message translates to:
  /// **'粤语'**
  String get langYue;

  /// No description provided for @langEn.
  ///
  /// In zh, this message translates to:
  /// **'英语'**
  String get langEn;

  /// No description provided for @langHenan.
  ///
  /// In zh, this message translates to:
  /// **'河南话'**
  String get langHenan;

  /// No description provided for @langFr.
  ///
  /// In zh, this message translates to:
  /// **'法语'**
  String get langFr;

  /// No description provided for @langDe.
  ///
  /// In zh, this message translates to:
  /// **'德语'**
  String get langDe;

  /// No description provided for @langSichuan.
  ///
  /// In zh, this message translates to:
  /// **'四川话'**
  String get langSichuan;

  /// No description provided for @langDongbei.
  ///
  /// In zh, this message translates to:
  /// **'东北话'**
  String get langDongbei;

  /// No description provided for @langShandong.
  ///
  /// In zh, this message translates to:
  /// **'山东话'**
  String get langShandong;

  /// No description provided for @langShanghai.
  ///
  /// In zh, this message translates to:
  /// **'上海话'**
  String get langShanghai;

  /// No description provided for @langMinnan.
  ///
  /// In zh, this message translates to:
  /// **'闽南语'**
  String get langMinnan;

  /// No description provided for @langJa.
  ///
  /// In zh, this message translates to:
  /// **'日语'**
  String get langJa;

  /// No description provided for @langKo.
  ///
  /// In zh, this message translates to:
  /// **'韩语'**
  String get langKo;

  /// No description provided for @overlayBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get overlayBack;

  /// No description provided for @overlayExit.
  ///
  /// In zh, this message translates to:
  /// **'退出'**
  String get overlayExit;

  /// No description provided for @overlayConfirmExit.
  ///
  /// In zh, this message translates to:
  /// **'确定退出？'**
  String get overlayConfirmExit;

  /// No description provided for @notificationChannel.
  ///
  /// In zh, this message translates to:
  /// **'实时字幕'**
  String get notificationChannel;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In zh, this message translates to:
  /// **'识别进行中时显示'**
  String get notificationChannelDescription;

  /// No description provided for @notificationTitle.
  ///
  /// In zh, this message translates to:
  /// **'实时字幕识别中'**
  String get notificationTitle;

  /// No description provided for @notificationText.
  ///
  /// In zh, this message translates to:
  /// **'点击返回 App'**
  String get notificationText;

  /// No description provided for @systemAudioNotificationChannel.
  ///
  /// In zh, this message translates to:
  /// **'系统声音字幕'**
  String get systemAudioNotificationChannel;

  /// No description provided for @systemAudioNotificationTitle.
  ///
  /// In zh, this message translates to:
  /// **'正在识别系统播放的声音'**
  String get systemAudioNotificationTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'fr',
    'ja',
    'ko',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
