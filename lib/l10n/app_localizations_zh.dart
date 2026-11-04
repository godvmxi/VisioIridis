// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '伊利斯之视';

  @override
  String get settings => '设置';

  @override
  String get interfaceLanguage => '界面语言';

  @override
  String get followSystem => '跟随系统';

  @override
  String get fontSize => '字体大小';

  @override
  String get fontStandard => '标准';

  @override
  String get fontLarge => '大';

  @override
  String get fontHuge => '特大';

  @override
  String get fontExtraHuge => '超大';

  @override
  String get fontGiant => '巨大';

  @override
  String get bold => '粗体';

  @override
  String get boldHint => '历史记录、浮动字幕等所有字幕文字使用粗体';

  @override
  String get colorMode => '配色模式';

  @override
  String get colorYellowOnBlack => '黄字黑底';

  @override
  String get colorWhiteOnBlack => '白字黑底';

  @override
  String get colorBlackOnWhite => '黑字白底';

  @override
  String get colorCustom => '自定义';

  @override
  String get backgroundColor => '背景色';

  @override
  String get textColor => '文字颜色';

  @override
  String backgroundSwatch(int index) {
    return '背景颜色 $index';
  }

  @override
  String textSwatch(int index) {
    return '文字颜色 $index';
  }

  @override
  String lowContrast(String ratio) {
    return '对比度较低（$ratio:1），字幕可能不易看清，建议不低于 4.5:1';
  }

  @override
  String get forceSplit => '强制切断';

  @override
  String get forceSplitHint =>
      '语音开始后超过设定时间仍无结果时，强制完成本句。适用于背景噪音导致无法检测到停顿的情况。设为「关」则完全依赖语音检测。';

  @override
  String get forceSplitOff => '关';

  @override
  String get floatingWindow => '浮动窗';

  @override
  String get showFloatingWindow => '显示浮动窗';

  @override
  String get overlayPermissionTitle => '需要悬浮窗权限';

  @override
  String get overlayPermissionBody =>
      '浮动字幕需要“显示在其他应用上层”权限。\n接下来请在系统设置中找到本应用并允许，然后返回。';

  @override
  String get overlayPermissionDenied => '未获得悬浮窗权限，浮动窗未开启';

  @override
  String get goEnable => '去开启';

  @override
  String get cancel => '取消';

  @override
  String get done => '完成';

  @override
  String get recognitionModel => '识别模型';

  @override
  String get recognitionModelHint =>
      '为每种语言指定使用的模型，打分为 10 分制；“自动”选择打分最高的模型。修改后点击“开始识别”时生效，需要时会提示下载新模型。';

  @override
  String modelConfigLoadFailed(String error) {
    return '模型配置加载失败：$error';
  }

  @override
  String get previewHistory => '你好，请问今天几点开会？';

  @override
  String get previewFocus => '下午三点见';

  @override
  String get swatchSample => '字';

  @override
  String get language => '语言';

  @override
  String chooseModelFor(String language) {
    return '为“$language”选择模型';
  }

  @override
  String get auto => '自动';

  @override
  String get noModelAvailable => '没有可用模型';

  @override
  String autoPicks(String model, int score) {
    return '选打分最高的模型：$model  $score 分';
  }

  @override
  String modelScoreTitle(String model, String language, int score) {
    return '$model    $language $score 分';
  }

  @override
  String supports(String scores) {
    return '支持：$scores';
  }

  @override
  String get startRecognition => '开始识别';

  @override
  String get stopRecognition => '停止识别';

  @override
  String get loadingModel => '正在加载识别模型...';

  @override
  String get waitingSpeech => '等待语音输入...';

  @override
  String get preparingModel => '正在准备模型...';

  @override
  String get restoringModel => '正在从保存目录恢复模型...';

  @override
  String downloadingModel(String model) {
    return '正在下载 $model';
  }

  @override
  String get verifyingModel => '正在校验模型文件...';

  @override
  String get savingModel => '正在保存模型...';

  @override
  String get backToLatest => '回到最新';

  @override
  String get soundSource => '声音来源';

  @override
  String get microphone => '麦克风';

  @override
  String get speaker => '喇叭';

  @override
  String get recognitionLanguage => '识别语言';

  @override
  String get clearScreen => '清屏';

  @override
  String currentModel(String model) {
    return '当前模型：$model';
  }

  @override
  String get notSupportedByModel => '当前模型不支持，不会识别';

  @override
  String get keepOneLanguage => '至少保留一种识别语言';

  @override
  String get alsoAutoDetect => '还可自动识别';

  @override
  String get alsoAutoDetectHint => '勾选多种语言（自动识别）时可识别这些语言。';

  @override
  String get listSeparator => '、';

  @override
  String get clearConfirm => '确认清空所有历史字幕记录？';

  @override
  String get clearConfirmButton => '确认清空';

  @override
  String get noModelForLanguages => '当前语言组合没有可用的识别模型';

  @override
  String modelSwitched(String model) {
    return '识别模型已切换为「$model」';
  }

  @override
  String modelPrepFailed(String error) {
    return '模型准备失败：$error';
  }

  @override
  String get modelChangedTitle => '识别模型已变更';

  @override
  String modelChangedFrom(String from, String to) {
    return '识别模型由「$from」变更为「$to」。';
  }

  @override
  String get downloadModelTitle => '下载识别模型';

  @override
  String downloadNeededWithVad(String model, String size) {
    return '需要下载「$model」及语音检测模型，共 $size。';
  }

  @override
  String downloadNeeded(String model, String size) {
    return '需要下载「$model」，共 $size。';
  }

  @override
  String get wifiSuggestion => '建议连接 Wi-Fi 后再下载。';

  @override
  String useModelFirst(String model) {
    return '先用「$model」';
  }

  @override
  String get download => '下载';

  @override
  String get speakerNotice => '因系统限制，喇叭模式只能识别播放器等应用播放的声音，无法识别电话和语音/视频通话的声音';

  @override
  String get micPermissionDenied => '需要麦克风权限才能识别';

  @override
  String recordingInterrupted(String error) {
    return '录音中断：$error';
  }

  @override
  String get speakerDenied => '未获得录制喇叭声音的授权，已切回麦克风';

  @override
  String get speakerEnded => '喇叭声音录制已结束，已切回麦克风';

  @override
  String switchBackFailed(String error) {
    return '切回麦克风失败：$error';
  }

  @override
  String modelLoadFailed(String error) {
    return '模型加载失败：$error';
  }

  @override
  String recognitionFailed(String error) {
    return '识别出错：$error';
  }

  @override
  String get eventLaughter => '笑声';

  @override
  String get eventApplause => '掌声';

  @override
  String get eventCry => '哭泣声';

  @override
  String get langZh => '普通话';

  @override
  String get langYue => '粤语';

  @override
  String get langEn => '英语';

  @override
  String get langHenan => '河南话';

  @override
  String get langFr => '法语';

  @override
  String get langDe => '德语';

  @override
  String get langSichuan => '四川话';

  @override
  String get langDongbei => '东北话';

  @override
  String get langShandong => '山东话';

  @override
  String get langWu => '吴语（上海话）';

  @override
  String get langMinnan => '闽南语';

  @override
  String get langJa => '日语';

  @override
  String get langKo => '韩语';

  @override
  String get overlayBack => '返回';

  @override
  String get overlayExit => '退出';

  @override
  String get overlayConfirmExit => '确定退出？';

  @override
  String get notificationChannel => '实时字幕';

  @override
  String get notificationChannelDescription => '识别进行中时显示';

  @override
  String get notificationTitle => '实时字幕识别中';

  @override
  String get notificationText => '点击返回 App';

  @override
  String get systemAudioNotificationChannel => '系统声音字幕';

  @override
  String get systemAudioNotificationTitle => '正在识别系统播放的声音';

  @override
  String get regionMainland => '中国大陆';

  @override
  String get regionOverseas => '境外';

  @override
  String get regionUnknown => '未知';

  @override
  String get configUpdateTitle => '发现模型配置更新';

  @override
  String configUpdateBody(String region, int currentVersion, int newVersion) {
    return '当前地区：$region\n当前配置版本：v$currentVersion → v$newVersion\n\n配置已在后台更新，可能包含新版本识别模型，是否立即生效并检查模型下载？';
  }

  @override
  String get configUpdateLater => '稍后';

  @override
  String get configUpdateNow => '立即生效';

  @override
  String get configUpdated => '配置已更新，点击「开始识别」以检查并下载新模型';

  @override
  String get onboardingWelcomeTitle => '欢迎使用伊利斯之视';

  @override
  String get onboardingWelcomeBody =>
      '伊利斯之视是专为听障人士设计的离线实时字幕工具，所有识别均在本设备完成，无需联网。\n\n接下来将帮您完成必要的权限配置。';

  @override
  String get onboardingMicTitle => '麦克风权限';

  @override
  String get onboardingMicBody => '实时语音识别需要使用麦克风。若使用喇叭模式识别系统播放的声音，也需要先授权麦克风。';

  @override
  String get onboardingMicButton => '授权麦克风';

  @override
  String get onboardingNotifTitle => '通知权限';

  @override
  String get onboardingNotifBody =>
      '识别进行中时会显示持续通知，防止系统将应用移入后台而中断识别。Android 13 及以上需手动授权。';

  @override
  String get onboardingNotifButton => '允许通知';

  @override
  String get onboardingOverlayTitle => '悬浮窗权限';

  @override
  String get onboardingOverlayBody => '切换到其他应用时，可通过悬浮窗继续查看字幕。此权限需在系统设置中手动开启。';

  @override
  String get onboardingOverlayButton => '去开启悬浮窗';

  @override
  String get onboardingBatteryTitle => '后台运行';

  @override
  String get onboardingBatteryBody =>
      '为防止系统在后台中断识别，建议将本应用加入电池优化白名单。此设置需在系统设置中手动完成。';

  @override
  String get onboardingBatteryButton => '去关闭电量限制';

  @override
  String get onboardingRegionTitle => '检测所在地区';

  @override
  String get onboardingRegionBody => '正在检测网络环境，以确定模型配置更新地址和模型下载来源。';

  @override
  String get onboardingRegionDetecting => '正在检测中…';

  @override
  String onboardingRegionResult(String region) {
    return '检测完成：$region';
  }

  @override
  String get onboardingRegionMainlandHint => '将从 Gitee 获取模型配置和下载地址';

  @override
  String get onboardingRegionOverseasHint => '将从 GitHub 获取模型配置和下载地址';

  @override
  String get onboardingRegionUnknownHint => '无法判断所在地区，后台将继续自动检测';

  @override
  String get onboardingDone => '开始使用';

  @override
  String get onboardingSkip => '跳过';

  @override
  String get onboardingGranted => '已授权';

  @override
  String get onboardingOpenedSettings => '已打开系统设置，完成后返回本应用';

  @override
  String get onboardingNext => '下一步';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => '伊利斯之視';

  @override
  String get settings => '設定';

  @override
  String get interfaceLanguage => '介面語言';

  @override
  String get followSystem => '跟隨系統';

  @override
  String get fontSize => '字體大小';

  @override
  String get fontStandard => '標準';

  @override
  String get fontLarge => '大';

  @override
  String get fontHuge => '特大';

  @override
  String get fontExtraHuge => '超大';

  @override
  String get fontGiant => '巨大';

  @override
  String get bold => '粗體';

  @override
  String get boldHint => '歷史記錄、浮動字幕等所有字幕文字使用粗體';

  @override
  String get colorMode => '配色模式';

  @override
  String get colorYellowOnBlack => '黃字黑底';

  @override
  String get colorWhiteOnBlack => '白字黑底';

  @override
  String get colorBlackOnWhite => '黑字白底';

  @override
  String get colorCustom => '自訂';

  @override
  String get backgroundColor => '背景色';

  @override
  String get textColor => '文字顏色';

  @override
  String backgroundSwatch(int index) {
    return '背景顏色 $index';
  }

  @override
  String textSwatch(int index) {
    return '文字顏色 $index';
  }

  @override
  String lowContrast(String ratio) {
    return '對比度較低（$ratio:1），字幕可能不易看清，建議不低於 4.5:1';
  }

  @override
  String get forceSplit => '強制切斷';

  @override
  String get forceSplitHint =>
      '語音開始後超過設定時間仍無結果時，強制完成本句。適用於背景噪音導致無法偵測到停頓的情況。設為「關」則完全依賴語音偵測。';

  @override
  String get forceSplitOff => '關';

  @override
  String get floatingWindow => '浮動窗';

  @override
  String get showFloatingWindow => '顯示浮動窗';

  @override
  String get overlayPermissionTitle => '需要懸浮窗權限';

  @override
  String get overlayPermissionBody =>
      '浮動字幕需要「顯示在其他應用程式上層」權限。\n接下來請在系統設定中找到本應用程式並允許，然後返回。';

  @override
  String get overlayPermissionDenied => '未取得懸浮窗權限，浮動窗未開啟';

  @override
  String get goEnable => '前往開啟';

  @override
  String get cancel => '取消';

  @override
  String get done => '完成';

  @override
  String get recognitionModel => '辨識模型';

  @override
  String get recognitionModelHint =>
      '為每種語言指定使用的模型，評分為 10 分制；「自動」選擇評分最高的模型。修改後點擊「開始辨識」時生效，需要時會提示下載新模型。';

  @override
  String modelConfigLoadFailed(String error) {
    return '模型設定載入失敗：$error';
  }

  @override
  String get previewHistory => '你好，請問今天幾點開會？';

  @override
  String get previewFocus => '下午三點見';

  @override
  String get swatchSample => '字';

  @override
  String get language => '語言';

  @override
  String chooseModelFor(String language) {
    return '為「$language」選擇模型';
  }

  @override
  String get auto => '自動';

  @override
  String get noModelAvailable => '沒有可用模型';

  @override
  String autoPicks(String model, int score) {
    return '選評分最高的模型：$model  $score 分';
  }

  @override
  String modelScoreTitle(String model, String language, int score) {
    return '$model    $language $score 分';
  }

  @override
  String supports(String scores) {
    return '支援：$scores';
  }

  @override
  String get startRecognition => '開始辨識';

  @override
  String get stopRecognition => '停止辨識';

  @override
  String get loadingModel => '正在載入辨識模型...';

  @override
  String get waitingSpeech => '等待語音輸入...';

  @override
  String get preparingModel => '正在準備模型...';

  @override
  String get restoringModel => '正在從儲存目錄還原模型...';

  @override
  String downloadingModel(String model) {
    return '正在下載 $model';
  }

  @override
  String get verifyingModel => '正在校驗模型檔案...';

  @override
  String get savingModel => '正在儲存模型...';

  @override
  String get backToLatest => '回到最新';

  @override
  String get soundSource => '聲音來源';

  @override
  String get microphone => '麥克風';

  @override
  String get speaker => '喇叭';

  @override
  String get recognitionLanguage => '辨識語言';

  @override
  String get clearScreen => '清除畫面';

  @override
  String currentModel(String model) {
    return '目前模型：$model';
  }

  @override
  String get notSupportedByModel => '目前模型不支援，不會辨識';

  @override
  String get keepOneLanguage => '至少保留一種辨識語言';

  @override
  String get alsoAutoDetect => '還可自動辨識';

  @override
  String get alsoAutoDetectHint => '勾選多種語言（自動辨識）時可辨識這些語言。';

  @override
  String get listSeparator => '、';

  @override
  String get clearConfirm => '確認清除所有歷史字幕記錄？';

  @override
  String get clearConfirmButton => '確認清除';

  @override
  String get noModelForLanguages => '目前語言組合沒有可用的辨識模型';

  @override
  String modelSwitched(String model) {
    return '辨識模型已切換為「$model」';
  }

  @override
  String modelPrepFailed(String error) {
    return '模型準備失敗：$error';
  }

  @override
  String get modelChangedTitle => '辨識模型已變更';

  @override
  String modelChangedFrom(String from, String to) {
    return '辨識模型由「$from」變更為「$to」。';
  }

  @override
  String get downloadModelTitle => '下載辨識模型';

  @override
  String downloadNeededWithVad(String model, String size) {
    return '需要下載「$model」及語音偵測模型，共 $size。';
  }

  @override
  String downloadNeeded(String model, String size) {
    return '需要下載「$model」，共 $size。';
  }

  @override
  String get wifiSuggestion => '建議連接 Wi-Fi 後再下載。';

  @override
  String useModelFirst(String model) {
    return '先用「$model」';
  }

  @override
  String get download => '下載';

  @override
  String get speakerNotice => '因系統限制，喇叭模式只能辨識播放器等應用程式播放的聲音，無法辨識電話和語音／視訊通話的聲音';

  @override
  String get micPermissionDenied => '需要麥克風權限才能辨識';

  @override
  String recordingInterrupted(String error) {
    return '錄音中斷：$error';
  }

  @override
  String get speakerDenied => '未取得錄製喇叭聲音的授權，已切回麥克風';

  @override
  String get speakerEnded => '喇叭聲音錄製已結束，已切回麥克風';

  @override
  String switchBackFailed(String error) {
    return '切回麥克風失敗：$error';
  }

  @override
  String modelLoadFailed(String error) {
    return '模型載入失敗：$error';
  }

  @override
  String recognitionFailed(String error) {
    return '辨識出錯：$error';
  }

  @override
  String get eventLaughter => '笑聲';

  @override
  String get eventApplause => '掌聲';

  @override
  String get eventCry => '哭泣聲';

  @override
  String get langZh => '普通話';

  @override
  String get langYue => '粵語';

  @override
  String get langEn => '英語';

  @override
  String get langHenan => '河南話';

  @override
  String get langFr => '法語';

  @override
  String get langDe => '德語';

  @override
  String get langSichuan => '四川話';

  @override
  String get langDongbei => '東北話';

  @override
  String get langShandong => '山東話';

  @override
  String get langWu => '吳語（上海話）';

  @override
  String get langMinnan => '閩南語';

  @override
  String get langJa => '日語';

  @override
  String get langKo => '韓語';

  @override
  String get overlayBack => '返回';

  @override
  String get overlayExit => '退出';

  @override
  String get overlayConfirmExit => '確定退出？';

  @override
  String get notificationChannel => '即時字幕';

  @override
  String get notificationChannelDescription => '辨識進行中時顯示';

  @override
  String get notificationTitle => '即時字幕辨識中';

  @override
  String get notificationText => '點擊返回 App';

  @override
  String get systemAudioNotificationChannel => '系統聲音字幕';

  @override
  String get systemAudioNotificationTitle => '正在辨識系統播放的聲音';

  @override
  String get regionMainland => '中國大陸';

  @override
  String get regionOverseas => '境外';

  @override
  String get regionUnknown => '未知';

  @override
  String get configUpdateTitle => '發現模型設定更新';

  @override
  String configUpdateBody(String region, int currentVersion, int newVersion) {
    return '目前地區：$region\n目前設定版本：v$currentVersion → v$newVersion\n\n設定已在後台更新，可能包含新版本辨識模型，是否立即生效並檢查模型下載？';
  }

  @override
  String get configUpdateLater => '稍後';

  @override
  String get configUpdateNow => '立即生效';

  @override
  String get configUpdated => '設定已更新，點擊「開始辨識」以檢查並下載新模型';

  @override
  String get onboardingWelcomeTitle => '歡迎使用伊利斯之視';

  @override
  String get onboardingWelcomeBody =>
      '伊利斯之視是專為聽障人士設計的離線即時字幕工具，所有辨識均在本裝置完成，無需聯網。\n\n接下來將協助您完成必要的權限設定。';

  @override
  String get onboardingMicTitle => '麥克風權限';

  @override
  String get onboardingMicBody => '即時語音辨識需要使用麥克風。若使用喇叭模式辨識系統播放的聲音，也需要先授權麥克風。';

  @override
  String get onboardingMicButton => '授權麥克風';

  @override
  String get onboardingNotifTitle => '通知權限';

  @override
  String get onboardingNotifBody =>
      '辨識進行中時會顯示持續通知，防止系統將應用程式移入背景而中斷辨識。Android 13 及以上需手動授權。';

  @override
  String get onboardingNotifButton => '允許通知';

  @override
  String get onboardingOverlayTitle => '懸浮窗權限';

  @override
  String get onboardingOverlayBody => '切換到其他應用程式時，可透過懸浮窗繼續查看字幕。此權限需在系統設定中手動開啟。';

  @override
  String get onboardingOverlayButton => '去開啟懸浮窗';

  @override
  String get onboardingBatteryTitle => '背景執行';

  @override
  String get onboardingBatteryBody =>
      '為防止系統在背景中斷辨識，建議將本應用程式加入電池最佳化白名單。此設定需在系統設定中手動完成。';

  @override
  String get onboardingBatteryButton => '去關閉電量限制';

  @override
  String get onboardingRegionTitle => '偵測所在地區';

  @override
  String get onboardingRegionBody => '正在偵測網路環境，以確定模型設定更新地址和模型下載來源。';

  @override
  String get onboardingRegionDetecting => '正在偵測中…';

  @override
  String onboardingRegionResult(String region) {
    return '偵測完成：$region';
  }

  @override
  String get onboardingRegionMainlandHint => '將從 Gitee 取得模型設定和下載地址';

  @override
  String get onboardingRegionOverseasHint => '將從 GitHub 取得模型設定和下載地址';

  @override
  String get onboardingRegionUnknownHint => '無法判斷所在地區，背景將繼續自動偵測';

  @override
  String get onboardingDone => '開始使用';

  @override
  String get onboardingSkip => '跳過';

  @override
  String get onboardingGranted => '已授權';

  @override
  String get onboardingOpenedSettings => '已開啟系統設定，完成後返回本應用程式';

  @override
  String get onboardingNext => '下一步';
}
