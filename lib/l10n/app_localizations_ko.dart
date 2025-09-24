// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '루틴 - 24시간 시계 선택기';

  @override
  String get homeTitle => '24시간 시계 선택기';

  @override
  String get settings => '설정';

  @override
  String get yourTimeSlots => '당신의 시간대';

  @override
  String get noTimeSlotsYet => '아직 시간대가 없습니다. +를 눌러 만들거나 원 위에서 드래그하세요!';

  @override
  String get routineSlots => '루틴 슬롯';

  @override
  String get signInToSync => '루틴을 동기화하려면 로그인하세요';

  @override
  String get signIn => '로그인';

  @override
  String get signUp => '회원가입';

  @override
  String get continueWithGoogle => 'Google로 계속';

  @override
  String get continueWithFacebook => 'Facebook으로 계속';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get confirmPassword => '비밀번호 확인';

  @override
  String get cancel => '취소';

  @override
  String get signInWithEmail => '이메일로 로그인';

  @override
  String get signUpWithEmail => '이메일로 회원가입';

  @override
  String get logout => '로그아웃';

  @override
  String get upgradeToProButton => '프로로 업그레이드';

  @override
  String get proMember => '프로 멤버';

  @override
  String get freeUser => '무료 사용자';

  @override
  String get addNewRoutineSlot => '새 루틴 슬롯 추가';

  @override
  String get currentlyActive => '현재 활성화됨';

  @override
  String get tapToActivate => '활성화하려면 탭하세요';

  @override
  String get rename => '이름 변경';

  @override
  String get duplicate => '복제';

  @override
  String get delete => '삭제';

  @override
  String get renameRoutine => '루틴 이름 변경';

  @override
  String get routineName => '루틴 이름';

  @override
  String get save => '저장';

  @override
  String get deleteRoutine => '루틴 삭제';

  @override
  String deleteRoutineConfirm(String name) {
    return '\"$name\"을(를) 삭제하시겠습니까?';
  }

  @override
  String get createTimeSlot => '시간대 생성';

  @override
  String get editTimeSlot => '시간대 편집';

  @override
  String get titleOfThisTime => '이 시간의 제목';

  @override
  String get titleHint => '예: 일, 운동, 수면...';

  @override
  String get descriptionOfThisTime => '이 시간의 설명';

  @override
  String get descriptionHint => '예: 아침 운동 루틴, 팀 미팅...';

  @override
  String get adjustTime => '시간 조정:';

  @override
  String get from => '시작: ';

  @override
  String get to => '종료: ';

  @override
  String get chooseColor => '색상 선택:';

  @override
  String get enableNotifications => '알림 활성화';

  @override
  String get create => '생성';

  @override
  String get update => '업데이트';

  @override
  String duration(String duration) {
    return '기간: $duration';
  }

  @override
  String durationSuffix(String duration) {
    return '$duration 기간';
  }

  @override
  String get appearance => '외관';

  @override
  String get theme => '테마';

  @override
  String get darkMode => '다크 모드';

  @override
  String get lightMode => '라이트 모드';

  @override
  String get language => '언어';

  @override
  String get selectLanguage => '언어 선택';

  @override
  String get helpAndSupport => '도움말 및 지원';

  @override
  String get tutorial => '튜토리얼';

  @override
  String get learnHowToUse => '앱 사용법 배우기';

  @override
  String get about => '정보';

  @override
  String get developedBy => '개발자: Kwanhoon Lee';

  @override
  String get copyright => '© 2025 - 나와 당신을 위해 제작';

  @override
  String languageChanged(String language) {
    return '언어가 $language(으)로 변경되었습니다';
  }

  @override
  String get welcomeToRoutine => '루틴 24에 오신 것을 환영합니다';

  @override
  String get planYourDay => '인터랙티브 24시간 시계 인터페이스로 하루를 계획하세요.';

  @override
  String get creatingTimeSlots => '시간대 생성하기';

  @override
  String get creatingTimeSlotsDesc =>
      '시계를 탭하고 드래그하여 활동에 대한 시간대를 생성하세요. 외부 링은 시간(0-23)을 나타냅니다.';

  @override
  String get managingYourSchedule => '일정 관리하기';

  @override
  String get managingYourScheduleDesc =>
      '시간대가 시작 및 종료 시간과 함께 표시됩니다. 기존 슬롯을 탭하여 수정하거나 삭제하세요.';

  @override
  String get settingsCustomization => '설정 및 사용자 정의';

  @override
  String get settingsCustomizationDesc =>
      '우측 상단의 설정 버튼을 탭하여 테마 토글, 언어 옵션 및 더 많은 사용자 정의 기능에 액세스하세요.';

  @override
  String get proSubscriptionBenefits => '프로 구독 혜택';

  @override
  String get proSubscriptionBenefitsDesc =>
      '연간 \$7.99로 프로 구독하여 무제한 루틴 슬롯, 광고 없는 경험, 커뮤니티 템플릿 공유, 고급 알람, 클라우드 동기화 및 더 많은 프리미엄 기능을 잠금 해제하세요. 무료 사용자는 1개 슬롯을 얻습니다.';

  @override
  String get getStarted => '시작하기';

  @override
  String get previous => '이전';

  @override
  String get next => '다음';

  @override
  String get freeUsersOneSlot =>
      '무료 사용자는 1개 슬롯을 사용할 수 있습니다. 무제한 슬롯을 위해 프로로 업그레이드하세요.';

  @override
  String get proFeatures => '프로 기능 포함:';

  @override
  String get unlimitedSlots => '• 무제한 루틴 슬롯';

  @override
  String get duplicateRoutines => '• 루틴 복제';

  @override
  String get prioritySupport => '• 우선 지원';

  @override
  String get advancedCustomization => '• 고급 사용자 정의';

  @override
  String get later => '나중에';

  @override
  String get upgradeNow => '지금 업그레이드';

  @override
  String get thanksForSupporting =>
      '루틴 24를 지원해 주셔서 감사합니다! 무제한 슬롯과 광고 없는 경험을 즐기세요.';

  @override
  String get advertisementSpace => '광고 공간';

  @override
  String get upgradeToProAd => '연간 \$6.99로 프로 업그레이드 - 광고 없음, 무제한 슬롯!';

  @override
  String get signInSuccess => '성공적으로 로그인했습니다!';

  @override
  String get signOutSuccess => '성공적으로 로그아웃했습니다';

  @override
  String get accountCreatedSuccess => '계정이 성공적으로 생성되었습니다!';

  @override
  String get passwordsDoNotMatch => '비밀번호가 일치하지 않습니다';

  @override
  String get passwordMinLength => '비밀번호는 최소 6자 이상이어야 합니다';

  @override
  String get upgradeToProUnlimited => '무제한 슬롯을 위해 프로로 업그레이드';

  @override
  String get mediaNotFound => '미디어를 찾을 수 없음';

  @override
  String get or => '또는';

  @override
  String get defaultRoutine => '기본 루틴';

  @override
  String get scheduleSpecificDaysFull => '특정 요일(월-일)에 루틴 예약';

  @override
  String get advancedNotificationsFull => '진동과 함께하는 고급 알림';

  @override
  String get getUnlimitedAccess => '무제한 접근 권한 얻기';

  @override
  String get removeAllAds => '모든 광고 제거';

  @override
  String get scheduleSpecificDays => '특정 요일 예약';

  @override
  String get advancedNotifications => '고급 알림';

  @override
  String get cloudSyncBackup => '클라우드 동기화 및 백업';

  @override
  String get chooseYourPlan => '요금제를 선택하세요';

  @override
  String get monthlyPlan => '월간 요금제';

  @override
  String get monthlyPrice => '\$3.99/월';

  @override
  String get yearlyPlan => '연간 요금제';

  @override
  String get yearlyPrice => '\$7.99/년';

  @override
  String get savingsText => '42% 절약';

  @override
  String get restore => '복원';

  @override
  String get popular => '인기';

  @override
  String get processingPurchase => '구매 처리 중...';

  @override
  String get purchasePlaceholder => '구매를 처리 중입니다. 잠시 기다려 주세요...';

  @override
  String get restorePlaceholder => '구매를 복원 중입니다. 잠시 기다려 주세요...';

  @override
  String get shareTemplates => '• 커뮤니티에 나만의 템플릿 공유';

  @override
  String get advancedAlarmFeatures => '• 사전 알람 및 스마트 간격 기능이 포함된 고급 알람';

  @override
  String get browseImportTemplates => '• 커뮤니티 템플릿 탐색 및 가져오기';

  @override
  String get removeAllAdsFull => '• 모든 광고 제거';

  @override
  String get cloudSyncBackupFull => '• 클라우드 동기화 및 백업';

  @override
  String get notifications => '알림';

  @override
  String get notificationPermissions => '알림 권한';

  @override
  String get notificationsEnabled => '활성화됨';

  @override
  String get notificationsDisabled => '비활성화됨';

  @override
  String get notificationSettings => '알림 설정';

  @override
  String get notificationPermissionDescription =>
      '루틴에 대한 알람과 리마인더를 받으려면 알림을 허용하세요';

  @override
  String get openSettings => '설정 열기';

  @override
  String get notificationPermissionGranted =>
      '알림이 활성화되었습니다! 루틴에 대한 알람을 받을 수 있습니다.';

  @override
  String get notificationPermissionDenied => '알람을 받으려면 기기 설정에서 알림을 활성화해 주세요.';

  @override
  String get preAlarm => '사전 알람';

  @override
  String get preAlarmTime => '사전 알람 시간:';

  @override
  String get smartIntervals => '스마트 간격';

  @override
  String get intervalDuration => '간격 지속 시간:';

  @override
  String get silentIntervals => '무음 간격';

  @override
  String get progressMessages => '진행 메시지';

  @override
  String minutesShort(int minutes) {
    return '$minutes분';
  }

  @override
  String timesCount(int count) {
    return '$count회';
  }

  @override
  String get advancedAlarmPromoText =>
      '사전 알람 경고 및 스마트 간격 기능이 포함된 고급 알람 기능을 이용하세요.';

  @override
  String get fillFreeTime => '자유 시간 채우기';

  @override
  String get browseTemplates => '템플릿 탐색';

  @override
  String get filledFreeTime => '24시간을 자유 시간으로 채웠습니다!';

  @override
  String get noFreeTimeGaps => '채울 자유 시간 공백이 없습니다';

  @override
  String get purchaseSuccessful => '구매 성공! 이제 PRO 액세스가 가능합니다.';

  @override
  String purchaseFailed(String error) {
    return '구매 실패: $error';
  }

  @override
  String get purchasesRestored => '구매가 성공적으로 복원되었습니다!';

  @override
  String restoreFailed(String error) {
    return '복원 실패: $error';
  }

  @override
  String get monday => '월요일';

  @override
  String get tuesday => '화요일';

  @override
  String get wednesday => '수요일';

  @override
  String get thursday => '목요일';

  @override
  String get friday => '금요일';

  @override
  String get saturday => '토요일';

  @override
  String get sunday => '일요일';

  @override
  String get selectDaysActive => '이 루틴이 활성화될 요일을 선택하세요:';

  @override
  String get newest => '최신순';

  @override
  String get mostLiked => '좋아요 순';

  @override
  String get mostUsed => '사용량 순';

  @override
  String get searchPlaceholder => '템플릿 검색...';

  @override
  String get category => '카테고리';

  @override
  String get lifestyle => '라이프스타일';

  @override
  String get sortBy => '정렬 기준';

  @override
  String get loadingTemplates => '템플릿 로딩 중...';

  @override
  String get noTemplatesFound => '템플릿을 찾을 수 없습니다';

  @override
  String get clearFilters => '필터 지우기';

  @override
  String get noTemplatesAvailable => '사용 가능한 템플릿이 없습니다';

  @override
  String get retry => '다시 시도';

  @override
  String templateCategory(String category) {
    return '카테고리: $category';
  }

  @override
  String failedToLoadTemplates(String error) {
    return '일부 템플릿 로드 실패: $error';
  }

  @override
  String get all => '전체';

  @override
  String get colorSettings => 'Color Settings';

  @override
  String get shareAsTemplate => 'Share as Template';

  @override
  String get daySettings => 'Day Settings';

  @override
  String get renameRoutineDialog => 'Rename Routine';

  @override
  String get deleteRoutineDialog => 'Delete Routine';

  @override
  String deleteConfirmMessage(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String daySettingsFor(String name) {
    return 'Day Settings for $name';
  }

  @override
  String chooseColorFor(String name) {
    return 'Choose Color for $name';
  }

  @override
  String get defaultColor => 'Default';

  @override
  String get templateName => 'Template Name';

  @override
  String get description => 'Description';

  @override
  String get enterTemplateName => 'Enter template name...';

  @override
  String get describeRoutine => 'Describe this routine...';

  @override
  String get lifestyleType => 'Lifestyle Type';

  @override
  String get sharingTemplate => 'Sharing template...';

  @override
  String get share => 'Share';

  @override
  String get pleaseEnterTemplateName => 'Please enter a template name';

  @override
  String templateSharedSuccess(String name) {
    return 'Template \"$name\" shared successfully!';
  }

  @override
  String get templateShareFailed =>
      'Failed to share template. Please try again.';

  @override
  String get everyDay => 'Every day';

  @override
  String get noDaysSelected => 'No days selected';

  @override
  String get hoursShort => 'h';

  @override
  String get minutesShortFormat => 'm';
}
