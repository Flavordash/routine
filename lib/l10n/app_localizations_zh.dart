// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '日程 - 24小时时钟选择器';

  @override
  String get homeTitle => '24小时时钟选择器';

  @override
  String get settings => '设置';

  @override
  String get yourTimeSlots => '您的时间段';

  @override
  String get noTimeSlotsYet => '还没有时间段。点击+创建一个或在圆圈上拖拽！';

  @override
  String get routineSlots => '日程槽位';

  @override
  String get signInToSync => '登录以同步您的日程';

  @override
  String get signIn => '登录';

  @override
  String get signUp => '注册';

  @override
  String get continueWithGoogle => '使用Google继续';

  @override
  String get continueWithFacebook => '使用Facebook继续';

  @override
  String get email => '邮箱';

  @override
  String get password => '密码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get cancel => '取消';

  @override
  String get signInWithEmail => '使用邮箱登录';

  @override
  String get signUpWithEmail => '使用邮箱注册';

  @override
  String get logout => '退出登录';

  @override
  String get upgradeToProButton => '升级到专业版';

  @override
  String get proMember => '专业版会员';

  @override
  String get freeUser => '免费用户';

  @override
  String get addNewRoutineSlot => '添加新的日程槽位';

  @override
  String get currentlyActive => '当前激活';

  @override
  String get tapToActivate => '点击激活';

  @override
  String get rename => '重命名';

  @override
  String get duplicate => '复制';

  @override
  String get delete => '删除';

  @override
  String get renameRoutine => '重命名日程';

  @override
  String get routineName => '日程名称';

  @override
  String get save => '保存';

  @override
  String get deleteRoutine => '删除日程';

  @override
  String deleteRoutineConfirm(String name) {
    return '您确定要删除\"$name\"吗？';
  }

  @override
  String get createTimeSlot => '创建时间段';

  @override
  String get editTimeSlot => '编辑时间段';

  @override
  String get titleOfThisTime => '这个时间的标题';

  @override
  String get titleHint => '例如：工作、锻炼、睡觉...';

  @override
  String get descriptionOfThisTime => '这个时间的描述';

  @override
  String get descriptionHint => '例如：晨练例程、团队会议...';

  @override
  String get adjustTime => '调整时间：';

  @override
  String get from => '从：';

  @override
  String get to => '到：';

  @override
  String get chooseColor => '选择颜色：';

  @override
  String get enableNotifications => '启用通知';

  @override
  String get create => '创建';

  @override
  String get update => '更新';

  @override
  String duration(String duration) {
    return '时长：$duration';
  }

  @override
  String durationSuffix(String duration) {
    return '$duration 时长';
  }

  @override
  String get appearance => '外观';

  @override
  String get theme => '主题';

  @override
  String get darkMode => '深色模式';

  @override
  String get lightMode => '浅色模式';

  @override
  String get language => '语言';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get helpAndSupport => '帮助与支持';

  @override
  String get tutorial => '教程';

  @override
  String get learnHowToUse => '学习如何使用应用';

  @override
  String get about => '关于';

  @override
  String get developedBy => '由Kwanhoon Lee开发';

  @override
  String get copyright => '© 2025 - 为我和您而制作';

  @override
  String languageChanged(String language) {
    return '语言已更改为$language';
  }

  @override
  String get welcomeToRoutine => '欢迎使用日程24';

  @override
  String get planYourDay => '使用我们的交互式24小时时钟界面规划您的一天。';

  @override
  String get creatingTimeSlots => '创建时间段';

  @override
  String get creatingTimeSlotsDesc => '在时钟上点击并拖拽来为您的活动创建时间段。外圈代表小时（0-23）。';

  @override
  String get managingYourSchedule => '管理您的日程';

  @override
  String get managingYourScheduleDesc => '您的时间段将显示开始和结束时间。点击现有时间段来修改或删除它们。';

  @override
  String get settingsCustomization => '设置与自定义';

  @override
  String get settingsCustomizationDesc => '点击右上角的设置按钮来访问主题切换、语言选项和更多自定义功能。';

  @override
  String get proSubscriptionBenefits => '专业版订阅优势';

  @override
  String get proSubscriptionBenefitsDesc =>
      '订阅专业版每年\$6.99，解锁无限日程槽位、无广告体验和高级功能。免费用户可获得1个槽位。';

  @override
  String get getStarted => '开始使用';

  @override
  String get previous => '上一步';

  @override
  String get next => '下一步';

  @override
  String get freeUsersOneSlot => '免费用户可以使用1个槽位。升级到专业版获得无限槽位。';

  @override
  String get proFeatures => '专业版功能包括：';

  @override
  String get unlimitedSlots => '• 无限日程槽位';

  @override
  String get duplicateRoutines => '• 复制日程';

  @override
  String get prioritySupport => '• 优先支持';

  @override
  String get advancedCustomization => '• 高级自定义';

  @override
  String get later => '稍后';

  @override
  String get upgradeNow => '立即升级';

  @override
  String get thanksForSupporting => '感谢支持日程24！享受无限槽位和无广告体验。';

  @override
  String get advertisementSpace => '广告位';

  @override
  String get upgradeToProAd => '升级到专业版每年\$6.99 - 无广告，无限槽位！';

  @override
  String get signInSuccess => '登录成功！';

  @override
  String get signOutSuccess => '退出登录成功';

  @override
  String get accountCreatedSuccess => '账户创建成功！';

  @override
  String get passwordsDoNotMatch => '密码不匹配';

  @override
  String get passwordMinLength => '密码必须至少6个字符';

  @override
  String get upgradeToProUnlimited => '升级到专业版获得无限槽位';

  @override
  String get mediaNotFound => '找不到媒体';

  @override
  String get or => '或';

  @override
  String get defaultRoutine => '默认日程';

  @override
  String get scheduleSpecificDaysFull =>
      'Schedule routine for specific days (Mon-Sun)';

  @override
  String get advancedNotificationsFull =>
      'Advanced notification with vibration';

  @override
  String get getUnlimitedAccess => 'Get Unlimited Access';

  @override
  String get removeAllAds => 'Remove all advertisements';

  @override
  String get scheduleSpecificDays => 'Schedule Specific Days';

  @override
  String get advancedNotifications => 'Advanced Notifications';

  @override
  String get cloudSyncBackup => 'Cloud Sync & Backup';

  @override
  String get chooseYourPlan => 'Choose Your Plan';

  @override
  String get monthlyPlan => 'Monthly Plan';

  @override
  String get monthlyPrice => '\$0.99/month';

  @override
  String get yearlyPlan => 'Yearly Plan';

  @override
  String get yearlyPrice => '\$6.99/year';

  @override
  String get savingsText => 'Save 42%';

  @override
  String get restore => 'Restore';

  @override
  String get popular => 'Popular';

  @override
  String get processingPurchase => 'Processing Purchase...';

  @override
  String get purchasePlaceholder => 'Processing your purchase. Please wait...';

  @override
  String get restorePlaceholder => 'Restoring your purchases. Please wait...';
}
