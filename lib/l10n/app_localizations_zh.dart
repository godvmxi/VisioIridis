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
}
