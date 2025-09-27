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
  String get contactSupport => 'Contact Support';

  @override
  String get getHelpAndAssistance => 'Get help and assistance';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get viewPrivacyPolicy => 'View our privacy policy';

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
      '订阅专业版每年\$6.99，解锁无限日程槽位、无广告体验、社区模板分享、高级闹钟、云同步和更多高级功能。免费用户可获得1个槽位。';

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
  String get scheduleSpecificDaysFull => '为特定日期安排例程（周一至周日）';

  @override
  String get advancedNotificationsFull => '具有振动功能的高级通知';

  @override
  String get getUnlimitedAccess => '获得无限访问权限';

  @override
  String get removeAllAds => '移除所有广告';

  @override
  String get scheduleSpecificDays => '安排特定日期';

  @override
  String get advancedNotifications => '高级通知';

  @override
  String get cloudSyncBackup => '云同步和备份';

  @override
  String get chooseYourPlan => '选择您的计划';

  @override
  String get monthlyPlan => '月度计划';

  @override
  String get monthlyPrice => '\$3.99/月';

  @override
  String get yearlyPlan => '年度计划';

  @override
  String get yearlyPrice => '\$7.99/年';

  @override
  String get savingsText => '节省42%';

  @override
  String get restore => '恢复';

  @override
  String get popular => '热门';

  @override
  String get processingPurchase => '正在处理购买...';

  @override
  String get purchasePlaceholder => '正在处理您的购买，请稍候...';

  @override
  String get restorePlaceholder => '正在恢复您的购买，请稍候...';

  @override
  String get shareTemplates => '• 与社区分享您的自定义模板';

  @override
  String get advancedAlarmFeatures => '• 具有预警和智能间隔功能的高级闹钟';

  @override
  String get browseImportTemplates => '• 浏览和导入社区模板';

  @override
  String get removeAllAdsFull => '• 移除所有广告';

  @override
  String get cloudSyncBackupFull => '• 云同步和备份';

  @override
  String get notifications => '通知';

  @override
  String get notificationPermissions => '通知权限';

  @override
  String get notificationsEnabled => '已启用';

  @override
  String get notificationsDisabled => '已禁用';

  @override
  String get notificationSettings => '通知设置';

  @override
  String get notificationPermissionDescription => '允许通知以接收您例程的闹钟和提醒';

  @override
  String get openSettings => '打开设置';

  @override
  String get notificationPermissionGranted => '通知已启用！您将收到例程的闹钟。';

  @override
  String get notificationPermissionDenied => '请在设备设置中启用通知以接收闹钟。';

  @override
  String get preAlarm => '预警闹钟';

  @override
  String get preAlarmTime => '预警时间:';

  @override
  String get smartIntervals => '智能间隔';

  @override
  String get intervalDuration => '间隔持续时间:';

  @override
  String get silentIntervals => '静音间隔';

  @override
  String get progressMessages => '进度消息';

  @override
  String minutesShort(int minutes) {
    return '$minutes分钟';
  }

  @override
  String timesCount(int count) {
    return '$count次';
  }

  @override
  String get advancedAlarmPromoText => '获取具有预警提醒和智能间隔功能的高级闹钟功能。';

  @override
  String get fillFreeTime => '填充自由时间';

  @override
  String get browseTemplates => '浏览模板';

  @override
  String get filledFreeTime => '已用自由时间填满24小时!';

  @override
  String get noFreeTimeGaps => '未找到可填充的自由时间空隙';

  @override
  String get purchaseSuccessful => '购买成功！您现在拥有PRO访问权限。';

  @override
  String purchaseFailed(String error) {
    return '购买失败：$error';
  }

  @override
  String get purchasesRestored => '购买已成功恢复！';

  @override
  String restoreFailed(String error) {
    return '恢复失败：$error';
  }

  @override
  String get monday => '星期一';

  @override
  String get tuesday => '星期二';

  @override
  String get wednesday => '星期三';

  @override
  String get thursday => '星期四';

  @override
  String get friday => '星期五';

  @override
  String get saturday => '星期六';

  @override
  String get sunday => '星期日';

  @override
  String get selectDaysActive => '选择此例程应活跃的日期：';

  @override
  String get newest => '最新';

  @override
  String get mostLiked => '最受欢迎';

  @override
  String get mostUsed => '使用最多';

  @override
  String get searchPlaceholder => '搜索模板...';

  @override
  String get category => '类别';

  @override
  String get lifestyle => '生活方式';

  @override
  String get sortBy => '排序方式';

  @override
  String get loadingTemplates => '正在加载模板...';

  @override
  String get noTemplatesFound => '未找到模板';

  @override
  String get clearFilters => '清除筛选';

  @override
  String get noTemplatesAvailable => '没有可用的模板';

  @override
  String get retry => '重试';

  @override
  String templateCategory(String category) {
    return '类别：$category';
  }

  @override
  String failedToLoadTemplates(String error) {
    return '加载某些模板失败：$error';
  }

  @override
  String get all => '全部';

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
