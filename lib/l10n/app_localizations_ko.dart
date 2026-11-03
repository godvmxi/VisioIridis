// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Visio Iridis';

  @override
  String get settings => '설정';

  @override
  String get interfaceLanguage => '표시 언어';

  @override
  String get followSystem => '시스템 설정 따르기';

  @override
  String get fontSize => '글자 크기';

  @override
  String get fontStandard => '보통';

  @override
  String get fontLarge => '크게';

  @override
  String get fontHuge => '아주 크게';

  @override
  String get fontExtraHuge => '매우 크게';

  @override
  String get fontGiant => '최대';

  @override
  String get bold => '굵게';

  @override
  String get boldHint => '기록과 플로팅 창을 포함한 모든 자막을 굵게 표시합니다';

  @override
  String get colorMode => '색상 구성';

  @override
  String get colorYellowOnBlack => '검정 바탕에 노랑';

  @override
  String get colorWhiteOnBlack => '검정 바탕에 흰색';

  @override
  String get colorBlackOnWhite => '흰 바탕에 검정';

  @override
  String get colorCustom => '사용자 지정';

  @override
  String get backgroundColor => '배경색';

  @override
  String get textColor => '글자색';

  @override
  String backgroundSwatch(int index) {
    return '배경색 $index';
  }

  @override
  String textSwatch(int index) {
    return '글자색 $index';
  }

  @override
  String lowContrast(String ratio) {
    return '대비가 너무 낮습니다($ratio:1). 자막을 읽기 어려울 수 있으니 4.5:1 이상을 권장합니다.';
  }

  @override
  String get floatingWindow => '플로팅 창';

  @override
  String get showFloatingWindow => '플로팅 창 표시';

  @override
  String get overlayPermissionTitle => '권한 필요';

  @override
  String get overlayPermissionBody =>
      '플로팅 자막을 사용하려면 \"다른 앱 위에 표시\" 권한이 필요합니다.\n시스템 설정에서 이 앱을 찾아 허용한 뒤 돌아오세요.';

  @override
  String get overlayPermissionDenied => '권한이 없어 플로팅 창이 꺼졌습니다';

  @override
  String get goEnable => '설정 열기';

  @override
  String get cancel => '취소';

  @override
  String get done => '완료';

  @override
  String get recognitionModel => '인식 모델';

  @override
  String get recognitionModelHint =>
      '언어마다 사용할 모델을 지정할 수 있습니다. 점수는 10점 만점이며, \"자동\"은 점수가 가장 높은 모델을 선택합니다. 변경 사항은 \"시작\"을 누를 때 적용되며, 필요하면 새 모델 다운로드를 안내합니다.';

  @override
  String modelConfigLoadFailed(String error) {
    return '모델 설정을 불러오지 못했습니다: $error';
  }

  @override
  String get previewHistory => '안녕하세요, 오늘 회의는 몇 시예요?';

  @override
  String get previewFocus => '오후 3시에 봬요';

  @override
  String get swatchSample => '가A';

  @override
  String get language => '언어';

  @override
  String chooseModelFor(String language) {
    return '\"$language\" 모델 선택';
  }

  @override
  String get auto => '자동';

  @override
  String get noModelAvailable => '사용할 수 있는 모델이 없습니다';

  @override
  String autoPicks(String model, int score) {
    return '최고 점수 모델: $model  $score점';
  }

  @override
  String modelScoreTitle(String model, String language, int score) {
    return '$model    $language $score점';
  }

  @override
  String supports(String scores) {
    return '지원: $scores';
  }

  @override
  String get startRecognition => '시작';

  @override
  String get stopRecognition => '중지';

  @override
  String get loadingModel => '인식 모델을 불러오는 중...';

  @override
  String get waitingSpeech => '음성을 기다리는 중...';

  @override
  String get preparingModel => '모델 준비 중...';

  @override
  String get restoringModel => '저장된 모델을 복원하는 중...';

  @override
  String downloadingModel(String model) {
    return '$model 다운로드 중';
  }

  @override
  String get verifyingModel => '모델 파일 확인 중...';

  @override
  String get savingModel => '모델 저장 중...';

  @override
  String get backToLatest => '최신으로';

  @override
  String get soundSource => '소리 입력';

  @override
  String get microphone => '마이크';

  @override
  String get speaker => '스피커';

  @override
  String get recognitionLanguage => '인식 언어';

  @override
  String get clearScreen => '지우기';

  @override
  String currentModel(String model) {
    return '현재 모델: $model';
  }

  @override
  String get notSupportedByModel => '현재 모델이 지원하지 않아 인식하지 않습니다';

  @override
  String get keepOneLanguage => '언어를 하나 이상 선택하세요';

  @override
  String get alsoAutoDetect => '자동으로 인식되는 언어';

  @override
  String get alsoAutoDetectHint => '여러 언어를 선택하면(자동 감지) 이 언어들도 인식됩니다.';

  @override
  String get listSeparator => ', ';

  @override
  String get clearConfirm => '자막 기록을 모두 지울까요?';

  @override
  String get clearConfirmButton => '지우기';

  @override
  String get noModelForLanguages => '선택한 언어를 지원하는 모델이 없습니다';

  @override
  String modelSwitched(String model) {
    return '인식 모델을 \"$model\"(으)로 바꿨습니다';
  }

  @override
  String modelPrepFailed(String error) {
    return '모델 준비 실패: $error';
  }

  @override
  String get modelChangedTitle => '모델이 바뀌었습니다';

  @override
  String modelChangedFrom(String from, String to) {
    return '인식 모델이 \"$from\"에서 \"$to\"(으)로 바뀌었습니다.';
  }

  @override
  String get downloadModelTitle => '모델 다운로드';

  @override
  String downloadNeededWithVad(String model, String size) {
    return '\"$model\"과 음성 감지 모델을 다운로드해야 합니다($size).';
  }

  @override
  String downloadNeeded(String model, String size) {
    return '\"$model\"을(를) 다운로드해야 합니다($size).';
  }

  @override
  String get wifiSuggestion => 'Wi-Fi 사용을 권장합니다.';

  @override
  String useModelFirst(String model) {
    return '우선 \"$model\" 사용';
  }

  @override
  String get download => '다운로드';

  @override
  String get speakerNotice =>
      '시스템 제한으로 스피커 모드에서는 동영상 앱 등에서 재생되는 소리만 인식할 수 있습니다. 전화와 음성·영상 통화는 인식할 수 없습니다.';

  @override
  String get micPermissionDenied => '마이크 권한이 필요합니다';

  @override
  String recordingInterrupted(String error) {
    return '녹음이 중단되었습니다: $error';
  }

  @override
  String get speakerDenied => '스피커 소리 캡처가 허용되지 않아 마이크로 돌아갔습니다';

  @override
  String get speakerEnded => '스피커 소리 캡처가 끝나 마이크로 돌아갔습니다';

  @override
  String switchBackFailed(String error) {
    return '마이크로 돌아가지 못했습니다: $error';
  }

  @override
  String modelLoadFailed(String error) {
    return '모델을 불러오지 못했습니다: $error';
  }

  @override
  String recognitionFailed(String error) {
    return '인식 오류: $error';
  }

  @override
  String get eventLaughter => '웃음소리';

  @override
  String get eventApplause => '박수';

  @override
  String get eventCry => '울음소리';

  @override
  String get langZh => '중국어(표준어)';

  @override
  String get langYue => '광둥어';

  @override
  String get langEn => '영어';

  @override
  String get langHenan => '허난 방언';

  @override
  String get langFr => '프랑스어';

  @override
  String get langDe => '독일어';

  @override
  String get langSichuan => '쓰촨 방언';

  @override
  String get langDongbei => '둥베이 방언';

  @override
  String get langShandong => '산둥 방언';

  @override
  String get langShanghai => '상하이어';

  @override
  String get langMinnan => '민난어';

  @override
  String get langJa => '일본어';

  @override
  String get langKo => '한국어';

  @override
  String get overlayBack => '돌아가기';

  @override
  String get overlayExit => '종료';

  @override
  String get overlayConfirmExit => '앱을 종료할까요?';

  @override
  String get notificationChannel => '실시간 자막';

  @override
  String get notificationChannelDescription => '자막을 인식하는 동안 표시됩니다';

  @override
  String get notificationTitle => '실시간 자막 인식 중';

  @override
  String get notificationText => '눌러서 앱으로 돌아가기';

  @override
  String get systemAudioNotificationChannel => '시스템 소리 자막';

  @override
  String get systemAudioNotificationTitle => '이 기기에서 재생 중인 소리를 인식하고 있습니다';
}
