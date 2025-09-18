import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/routine_slot_model.dart';
import '../utils/logger.dart';

// Top-level function for handling background notification responses
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  final payload = response.payload;
  final actionId = response.actionId;

  Logger.instance.info('🔔 Background notification response received:');
  Logger.instance.info('  - actionId: $actionId');
  Logger.instance.info('  - payload: $payload');

  if (actionId == 'snooze_action' && payload != null) {
    Logger.instance.info('🔄 Processing snooze action in background...');
    NotificationService.instance.handleSnoozeAction(payload);
  } else if (actionId == 'dismiss_action' && payload != null) {
    Logger.instance.info('✖️ Processing dismiss action in background...');
    NotificationService.instance.handleDismissAction(payload);
  }
}

// Test data structures for verification
class NotificationTestResult {
  final bool passed;
  final String scenario;
  final String details;
  final List<String> logs;

  NotificationTestResult({
    required this.passed,
    required this.scenario,
    required this.details,
    this.logs = const [],
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _notificationsEnabled = true;
  static const String _notificationEnabledKey = 'notifications_enabled';

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load saved notification preference
    await _loadNotificationPreference();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Setup iOS notification categories with snooze actions
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'ALARM_CATEGORY',
          actions: [
            DarwinNotificationAction.plain(
              'snooze_action',
              'Snooze',
            ),
            DarwinNotificationAction.plain(
              'dismiss_action',
              'Dismiss',
            ),
          ],
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Request permissions explicitly
    await _requestPermissions();

    _isInitialized = true;

    Logger.instance.info('NotificationService initialized with permissions and notification categories');
  }

  // Get notification permission status
  bool get notificationsEnabled => _notificationsEnabled;

  // Set global notification state and save it
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _saveNotificationPreference(enabled);
    Logger.instance.info('Global notifications ${enabled ? 'enabled' : 'disabled'} and saved');
  }

  // Load notification preference from SharedPreferences
  Future<void> _loadNotificationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_notificationEnabledKey) ?? true;
      Logger.instance.info('💾 Loaded notification preference: $_notificationsEnabled');
    } catch (error) {
      Logger.instance.error('❌ Failed to load notification preference: $error');
      _notificationsEnabled = true; // Default to enabled
    }
  }

  // Save notification preference to SharedPreferences
  Future<void> _saveNotificationPreference(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationEnabledKey, enabled);
      Logger.instance.info('💾 Saved notification preference: $enabled');
    } catch (error) {
      Logger.instance.error('❌ Failed to save notification preference: $error');
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      Logger.instance.info('SUCCESS: All notifications cancelled');
    } catch (error) {
      Logger.instance.error('FAILED: Could not cancel all notifications: $error');
      rethrow;
    }
  }

  // Cancel notifications for a specific routine slot
  Future<void> cancelRoutineNotifications(String routineSlotId) async {
    try {
      Logger.instance.info('Cancelling notifications for routine slot: $routineSlotId');
      int cancelledCount = 0;
      
      // Cancel all time slot notifications for this routine
      for (int dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
        // Cancel main notification
        final mainNotificationId = _generateNotificationId(routineSlotId, dayOfWeek);
        await _notificationsPlugin.cancel(mainNotificationId);
        cancelledCount++;
        
        // Cancel pre-alarm notification
        final preAlarmNotificationId = _generateNotificationId(routineSlotId, dayOfWeek, isPreAlarm: true);
        await _notificationsPlugin.cancel(preAlarmNotificationId);
        cancelledCount++;
      }
      
      Logger.instance.info('SUCCESS: Cancelled $cancelledCount notifications for routine slot: $routineSlotId');
    } catch (error) {
      Logger.instance.error('FAILED: Could not cancel notifications for routine slot $routineSlotId: $error');
    }
  }

  // Cancel notifications for a specific time slot
  Future<void> cancelTimeSlotNotifications(String timeSlotId) async {
    try {
      Logger.instance.info('Cancelling notifications for time slot: $timeSlotId');
      int cancelledCount = 0;
      
      for (int dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
        // Cancel main notification
        final mainNotificationId = _generateNotificationId(timeSlotId, dayOfWeek);
        await _notificationsPlugin.cancel(mainNotificationId);
        cancelledCount++;
        
        // Cancel pre-alarm notification
        final preAlarmNotificationId = _generateNotificationId(timeSlotId, dayOfWeek, isPreAlarm: true);
        await _notificationsPlugin.cancel(preAlarmNotificationId);
        cancelledCount++;
      }
      
      Logger.instance.info('SUCCESS: Cancelled $cancelledCount notifications for time slot: $timeSlotId');
    } catch (error) {
      Logger.instance.error('FAILED: Could not cancel notifications for time slot $timeSlotId: $error');
    }
  }

  // Schedule notifications for the active routine only
  Future<void> scheduleActiveRoutineNotifications(
    List<RoutineSlot> routineSlots,
  ) async {
    Logger.instance.info('=== SCHEDULING NOTIFICATIONS ===');
    Logger.instance.info('Notifications enabled: $_notificationsEnabled');

    if (!_notificationsEnabled) {
      Logger.instance.info('Notifications disabled, skipping scheduling');
      return;
    }

    // First, cancel all existing notifications
    await cancelAllNotifications();

    // Detailed logging for debugging
    Logger.instance.info('Total routine slots received: ${routineSlots.length}');

    // Find the active routine slot
    final activeSlots = routineSlots.where((slot) => slot.isActive).toList();

    // Validation: Ensure only one active routine
    if (activeSlots.length > 1) {
      Logger.instance.warning('Multiple active routines detected (${activeSlots.length}). Using first one.');
      for (int i = 0; i < activeSlots.length; i++) {
        Logger.instance.warning('Active routine ${i + 1}: ${activeSlots[i].name}');
      }
    }

    final activeSlot = activeSlots.isEmpty ? null : activeSlots.first;

    if (activeSlot == null) {
      Logger.instance.info('No active routine slot found - no notifications will be scheduled');
      // Log all routine states for debugging
      for (final slot in routineSlots) {
        Logger.instance.info('Routine "${slot.name}": isActive=${slot.isActive}');
      }
      return;
    }

    Logger.instance.info('Scheduling notifications for active routine: "${activeSlot.name}"');
    Logger.instance.info('Active routine has ${activeSlot.timeSlots.length} time slots');
    Logger.instance.info('Selected days: ${activeSlot.selectedDays}');

    // Check time slots with alarms
    final alarmedSlots = activeSlot.timeSlots.where((slot) => slot.hasAlarm).toList();
    Logger.instance.info('Time slots with alarms: ${alarmedSlots.length}');

    for (int i = 0; i < alarmedSlots.length; i++) {
      final slot = alarmedSlots[i];
      Logger.instance.info('Alarm slot $i: "${slot.label}" at ${slot.startTime}');
    }

    // Schedule notifications for all time slots in the active routine
    for (final timeSlot in activeSlot.timeSlots) {
      if (timeSlot.hasAlarm) {
        Logger.instance.info('Scheduling alarm for "${timeSlot.label}" at ${timeSlot.startTime}');
        await _scheduleTimeSlotNotifications(
          timeSlot,
          activeSlot.selectedDays,
          routineSlotId: activeSlot.id,
        );
      } else {
        Logger.instance.info('Skipping "${timeSlot.label}" - no alarm enabled');
      }
    }

    Logger.instance.info('=== SCHEDULING COMPLETE ===');
  }

  // Schedule notifications for a specific time slot
  Future<void> _scheduleTimeSlotNotifications(
    RoutineTimeSlot timeSlot,
    List<int> selectedDays, {
    required String routineSlotId,
  }) async {
    if (!_notificationsEnabled || !timeSlot.hasAlarm) return;

    // Validate selectedDays array
    if (selectedDays.isEmpty) {
      Logger.instance.warning('No days selected for time slot: ${timeSlot.label}');
      return;
    }

    // Validate each day is in range 1-7
    final validDays = selectedDays.where((day) => day >= 1 && day <= 7).toList();
    if (validDays.length != selectedDays.length) {
      Logger.instance.warning('Invalid days found in selectedDays: $selectedDays. Using valid days: $validDays');
    }

    if (validDays.isEmpty) {
      Logger.instance.warning('No valid days (1-7) found for time slot: ${timeSlot.label}');
      return;
    }

    Logger.instance.info('Scheduling notifications for time slot: "${timeSlot.label}" on days: $validDays');

    // Parse start time from timeSlot.startTime (format: "HH:mm")
    final timeParts = timeSlot.startTime.split(':');
    if (timeParts.length != 2) {
      Logger.instance.error('Invalid time format: ${timeSlot.startTime}');
      return;
    }

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      Logger.instance.error('Invalid time values: ${timeSlot.startTime}');
      return;
    }

    // Schedule notification for each valid selected day of the week
    for (int dayOfWeek in validDays) {
      await _scheduleWeeklyNotification(
        timeSlot: timeSlot,
        dayOfWeek: dayOfWeek,
        hour: hour,
        minute: minute,
        routineSlotId: routineSlotId,
      );
    }

    // Schedule pre-alarm if enabled
    if (timeSlot.hasPreAlarm) {
      final preAlarmHour = hour;
      final preAlarmMinute = minute - timeSlot.preAlarmMinutes;

      // Handle minute overflow
      final adjustedTime = _adjustTime(preAlarmHour, preAlarmMinute);

      for (int dayOfWeek in validDays) {
        await _scheduleWeeklyNotification(
          timeSlot: timeSlot,
          dayOfWeek: dayOfWeek,
          hour: adjustedTime['hour']!,
          minute: adjustedTime['minute']!,
          routineSlotId: routineSlotId,
          isPreAlarm: true,
        );
      }
    }
  }

  // Schedule a weekly repeating notification
  Future<void> _scheduleWeeklyNotification({
    required RoutineTimeSlot timeSlot,
    required int dayOfWeek,
    required int hour,
    required int minute,
    required String routineSlotId,
    bool isPreAlarm = false,
  }) async {
    // Validate day of week
    if (dayOfWeek < 1 || dayOfWeek > 7) {
      Logger.instance.error('Invalid dayOfWeek: $dayOfWeek. Must be 1-7 (Monday-Sunday)');
      return;
    }

    final now = DateTime.now();
    final currentDayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday

    // Day names for logging
    const dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final targetDayName = dayNames[dayOfWeek];

    // Calculate days until the target day
    int daysUntilTarget = (dayOfWeek - currentDayOfWeek) % 7;
    if (daysUntilTarget == 0) {
      // It's today - check if time has passed
      final todayScheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (todayScheduledTime.isBefore(now)) {
        daysUntilTarget = 7; // Schedule for next week
        Logger.instance.info('Time has passed today, scheduling for next $targetDayName');
      } else {
        Logger.instance.info('Scheduling for today ($targetDayName)');
      }
    } else {
      Logger.instance.info('Scheduling for $targetDayName in $daysUntilTarget days');
    }

    final notificationTime = DateTime(
      now.year,
      now.month,
      now.day + daysUntilTarget,
      hour,
      minute,
    );

    final notificationId = _generateNotificationId(
      timeSlot.id, 
      dayOfWeek,
      isPreAlarm: isPreAlarm,
    );

    final title = isPreAlarm 
        ? 'Upcoming: ${timeSlot.label}' 
        : 'Time for: ${timeSlot.label}';
    
    final body = isPreAlarm
        ? 'Starting in ${timeSlot.preAlarmMinutes} minutes'
        : timeSlot.snoozeEnabled
            ? '${timeSlot.startTime} - ${timeSlot.endTime}\n📱 Hold to snooze or dismiss'
            : '${timeSlot.startTime} - ${timeSlot.endTime}';

    // Create notification actions for snooze functionality
    final List<AndroidNotificationAction> actions = [];
    if (!isPreAlarm && timeSlot.snoozeEnabled) {
      actions.addAll([
        const AndroidNotificationAction(
          'snooze_action',
          'Snooze ⏰',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_snooze'),
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'dismiss_action',
          'Dismiss ✖️',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_clear'),
          showsUserInterface: false,
        ),
      ]);
      Logger.instance.info('📱 Added snooze and dismiss actions to notification for "${timeSlot.label}"');
    } else {
      Logger.instance.info('⚠️ No snooze actions added: isPreAlarm=$isPreAlarm, snoozeEnabled=${timeSlot.snoozeEnabled}');
    }

    final androidDetails = AndroidNotificationDetails(
      'routine_notifications',
      'Routine Notifications',
      channelDescription: 'Notifications for your scheduled time slots',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: isPreAlarm
          ? Int64List.fromList([0, 500, 200, 500])
          : Int64List.fromList([0, 1000, 500, 1000]),
      playSound: true,
      actions: actions,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: !isPreAlarm,
      additionalFlags: !isPreAlarm ? Int32List.fromList([4]) : null, // FLAG_INSISTENT for main alarms
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: timeSlot.snoozeEnabled && !isPreAlarm ? 'Tap Snooze or Dismiss' : null,
      ),
      visibility: NotificationVisibility.public,
      showWhen: true,
      ongoing: !isPreAlarm, // Makes notification persistent until dismissed
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: timeSlot.snoozeEnabled && !isPreAlarm ? 'ALARM_CATEGORY' : null,
      interruptionLevel: isPreAlarm
          ? InterruptionLevel.active
          : InterruptionLevel.critical,
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(notificationTime, tz.local),
        platformChannelSpecifics,
        payload: '${timeSlot.id}|${timeSlot.label}|${timeSlot.snoozeDuration}|${timeSlot.maxSnoozeCount}',
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      Logger.instance.info(
        'SUCCESS: Scheduled ${isPreAlarm ? 'pre-' : ''}notification for "${timeSlot.label}" '
        'on $targetDayName at $hour:${minute.toString().padLeft(2, '0')} '
        '(ID: $notificationId, Date: ${notificationTime.toString().split(' ')[0]})'
      );
    } catch (error) {
      Logger.instance.error(
        'FAILED: Could not schedule ${isPreAlarm ? 'pre-' : ''}notification for "${timeSlot.label}" '
        'on $targetDayName at $hour:${minute.toString().padLeft(2, '0')}: $error'
      );
    }
  }

  // Generate unique notification ID
  int _generateNotificationId(String timeSlotId, int dayOfWeek, {bool isPreAlarm = false}) {
    // Validate inputs
    if (dayOfWeek < 1 || dayOfWeek > 7) {
      Logger.instance.error('Invalid dayOfWeek for ID generation: $dayOfWeek');
      dayOfWeek = 1; // Fallback to Monday
    }

    // Create a unique ID by combining timeSlotId hash, day of week, and pre-alarm flag
    // Format: [pre-alarm bit][day of week][base ID % 1000000]
    final baseId = timeSlotId.hashCode.abs() % 100000; // Ensure positive, max 5 digits
    final dayMultiplier = dayOfWeek * 100000; // Days 1-7 become 100000-700000
    final preAlarmOffset = isPreAlarm ? 10000000 : 0; // Pre-alarm flag in high bit
    
    final notificationId = preAlarmOffset + dayMultiplier + baseId;
    
    Logger.instance.info(
      'Generated notification ID: $notificationId for timeSlot: $timeSlotId, '
      'day: $dayOfWeek, preAlarm: $isPreAlarm'
    );
    
    return notificationId;
  }

  // Adjust time when minutes go negative or exceed 60
  Map<String, int> _adjustTime(int hour, int minute) {
    while (minute < 0) {
      minute += 60;
      hour -= 1;
    }
    while (minute >= 60) {
      minute -= 60;
      hour += 1;
    }
    if (hour < 0) hour += 24;
    if (hour >= 24) hour -= 24;
    
    return {'hour': hour, 'minute': minute};
  }

  // === VERIFICATION & TESTING METHODS ===

  // Test Scenario 1: Active routine, selected days [1,2,3] (Mon-Wed)
  Future<NotificationTestResult> testScenario1() async {
    Logger.instance.info('=== TEST SCENARIO 1: Active routine Mon-Wed ===');
    
    final testSlots = [
      RoutineSlot(
        id: 'test1',
        name: 'Weekday Routine',
        isActive: true,
        isPaid: true,
        selectedDays: [1, 2, 3], // Mon-Wed
        timeSlots: [
          RoutineTimeSlot(
            id: 'time1',
            startAngle: 90,
            endAngle: 120,
            startTime: '09:00',
            endTime: '10:00',
            label: 'Morning Meeting',
            hasAlarm: true,
          ),
        ],
      ),
      RoutineSlot(
        id: 'test2',
        name: 'Weekend Routine',
        isActive: false, // INACTIVE
        isPaid: true,
        selectedDays: [6, 7], // Sat-Sun
        timeSlots: [
          RoutineTimeSlot(
            id: 'time2',
            startAngle: 120,
            endAngle: 150,
            startTime: '10:00',
            endTime: '11:00',
            label: 'Weekend Activity',
            hasAlarm: true,
          ),
        ],
      ),
    ];

    await scheduleActiveRoutineNotifications(testSlots);
    
    return NotificationTestResult(
      passed: true,
      scenario: 'Scenario 1: Active routine Mon-Wed',
      details: 'Should schedule notifications only for Mon-Wed, not Sat-Sun',
    );
  }

  // Test Scenario 2: Inactive routine, any selected days
  Future<NotificationTestResult> testScenario2() async {
    Logger.instance.info('=== TEST SCENARIO 2: All routines inactive ===');
    
    final testSlots = [
      RoutineSlot(
        id: 'test3',
        name: 'Inactive Routine 1',
        isActive: false, // INACTIVE
        isPaid: true,
        selectedDays: [1, 2, 3, 4, 5],
        timeSlots: [
          RoutineTimeSlot(
            id: 'time3',
            startAngle: 90,
            endAngle: 120,
            startTime: '09:00',
            endTime: '10:00',
            label: 'Should Not Schedule',
            hasAlarm: true,
          ),
        ],
      ),
      RoutineSlot(
        id: 'test4',
        name: 'Inactive Routine 2',
        isActive: false, // INACTIVE
        isPaid: true,
        selectedDays: [6, 7],
        timeSlots: [
          RoutineTimeSlot(
            id: 'time4',
            startAngle: 120,
            endAngle: 150,
            startTime: '10:00',
            endTime: '11:00',
            label: 'Also Should Not Schedule',
            hasAlarm: true,
          ),
        ],
      ),
    ];

    await scheduleActiveRoutineNotifications(testSlots);
    
    return NotificationTestResult(
      passed: true,
      scenario: 'Scenario 2: All routines inactive',
      details: 'Should schedule NO notifications',
    );
  }

  // Test Scenario 3: Active routine, selected days [6,7] (Sat-Sun)
  Future<NotificationTestResult> testScenario3() async {
    Logger.instance.info('=== TEST SCENARIO 3: Active routine weekends only ===');
    
    final testSlots = [
      RoutineSlot(
        id: 'test5',
        name: 'Weekend Only Routine',
        isActive: true,
        isPaid: true,
        selectedDays: [6, 7], // Sat-Sun only
        timeSlots: [
          RoutineTimeSlot(
            id: 'time5',
            startAngle: 90,
            endAngle: 120,
            startTime: '10:00',
            endTime: '11:00',
            label: 'Weekend Activity',
            hasAlarm: true,
          ),
          RoutineTimeSlot(
            id: 'time6',
            startAngle: 150,
            endAngle: 180,
            startTime: '14:00',
            endTime: '15:00',
            label: 'Afternoon Weekend',
            hasAlarm: true,
            hasPreAlarm: true,
            preAlarmMinutes: 30,
          ),
        ],
      ),
    ];

    await scheduleActiveRoutineNotifications(testSlots);
    
    return NotificationTestResult(
      passed: true,
      scenario: 'Scenario 3: Active routine weekends only',
      details: 'Should schedule notifications for Saturday and Sunday only, including pre-alarms',
    );
  }

  // Test immediate notification (for debugging)
  Future<void> testImmediateNotification() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'test_notifications',
        'Test Notifications',
        channelDescription: 'Test notifications to verify setup',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      );

      const platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        999,
        'Test Notification',
        'If you see this, notifications are working!',
        platformChannelSpecifics,
      );

      Logger.instance.info('SUCCESS: Test notification sent');
    } catch (error) {
      Logger.instance.error('FAILED: Test notification failed: $error');
    }
  }

  // Test immediate notification with snooze actions (for debugging)
  Future<void> testImmediateSnoozeNotification() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'test_notifications',
        'Test Notifications',
        channelDescription: 'Test notifications with snooze actions',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        actions: [
          AndroidNotificationAction(
            'snooze_action',
            'Snooze ⏰',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'dismiss_action',
            'Dismiss ✖️',
            showsUserInterface: false,
          ),
        ],
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        styleInformation: BigTextStyleInformation(
          'Tap Snooze or Dismiss to test functionality',
          contentTitle: 'Test Snooze Notification',
          summaryText: 'Snooze and Dismiss buttons should be visible',
        ),
        visibility: NotificationVisibility.public,
        ongoing: true,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'ALARM_CATEGORY',
        interruptionLevel: InterruptionLevel.critical,
      );

      const platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        998,
        'Test Snooze Notification',
        'Tap Snooze or Dismiss to test functionality',
        platformChannelSpecifics,
        payload: 'test_id|Test Alarm|5|3|0', // Test payload: 5min snooze, max 3 attempts
      );

      Logger.instance.info('SUCCESS: Test snooze notification sent with actions');
    } catch (error) {
      Logger.instance.error('FAILED: Test snooze notification failed: $error');
    }
  }

  // Schedule a test notification for specific time (for debugging)
  Future<void> scheduleTestNotification({
    required DateTime time,
    required String title,
    required String body,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'test_notifications',
        'Test Notifications',
        channelDescription: 'Test scheduled notifications with snooze to verify timing',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true,
        actions: [
          AndroidNotificationAction(
            'snooze_action',
            'Snooze ⏰',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'dismiss_action',
            'Dismiss ✖️',
            showsUserInterface: false,
          ),
        ],
        category: AndroidNotificationCategory.alarm,
        styleInformation: BigTextStyleInformation(
          'Try tapping Snooze to test the functionality',
          contentTitle: 'Test Alarm with Snooze',
          summaryText: 'Buttons should be visible below',
        ),
        visibility: NotificationVisibility.public,
        ongoing: true,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'ALARM_CATEGORY',
        interruptionLevel: InterruptionLevel.critical,
      );

      const platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        997, // Different ID from other test notifications
        title,
        body,
        tz.TZDateTime.from(time, tz.local),
        platformChannelSpecifics,
        payload: 'test_scheduled|$title|2|3|0', // Test payload: 2min snooze, max 3 attempts
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      Logger.instance.info('SUCCESS: Test notification scheduled for $time');
    } catch (error) {
      Logger.instance.error('FAILED: Test notification scheduling failed: $error');
    }
  }

  // Run all test scenarios
  Future<List<NotificationTestResult>> runAllTests() async {
    Logger.instance.info('===== STARTING NOTIFICATION SYSTEM VERIFICATION =====');
    
    final results = <NotificationTestResult>[];
    
    try {
      results.add(await testScenario1());
      await Future.delayed(Duration(milliseconds: 100)); // Small delay between tests
      
      results.add(await testScenario2());
      await Future.delayed(Duration(milliseconds: 100));
      
      results.add(await testScenario3());
      
      Logger.instance.info('===== NOTIFICATION SYSTEM VERIFICATION COMPLETE =====');
      
      // Summary
      final passedTests = results.where((r) => r.passed).length;
      Logger.instance.info('Test Results: $passedTests/${results.length} passed');
      
    } catch (error) {
      Logger.instance.error('Test execution failed: $error');
      results.add(NotificationTestResult(
        passed: false,
        scenario: 'Test Execution',
        details: 'Failed to run tests: $error',
      ));
    }
    
    return results;
  }

  // Verify day-of-week calculation accuracy
  bool verifyDayOfWeekCalculation() {
    Logger.instance.info('=== VERIFYING DAY-OF-WEEK CALCULATIONS ===');
    
    final now = DateTime.now();
    final currentDayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday
    
    Logger.instance.info('Current day of week: $currentDayOfWeek (${_getDayName(currentDayOfWeek)})');
    
    // Test calculations for each day
    for (int targetDay = 1; targetDay <= 7; targetDay++) {
      final daysUntilTarget = (targetDay - currentDayOfWeek) % 7;
      final targetDate = DateTime(now.year, now.month, now.day + daysUntilTarget);
      final calculatedDayOfWeek = targetDate.weekday;
      
      final isCorrect = calculatedDayOfWeek == targetDay;
      Logger.instance.info(
        'Target: ${_getDayName(targetDay)} ($targetDay), '
        'Days until: $daysUntilTarget, '
        'Calculated day: ${_getDayName(calculatedDayOfWeek)} ($calculatedDayOfWeek), '
        'Correct: $isCorrect'
      );
      
      if (!isCorrect) {
        Logger.instance.error('Day calculation error detected!');
        return false;
      }
    }
    
    Logger.instance.info('All day-of-week calculations are correct');
    return true;
  }

  String _getDayName(int dayOfWeek) {
    const dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return dayOfWeek >= 1 && dayOfWeek <= 7 ? dayNames[dayOfWeek] : 'Invalid';
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      // Android 13+ permission request
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        Logger.instance.info('Android notification permission granted: $granted');

        // Request exact alarm permission for Android 12+
        final exactAlarmPermission = await androidImplementation.requestExactAlarmsPermission();
        Logger.instance.info('Android exact alarm permission granted: $exactAlarmPermission');
      }

      // iOS permission request
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
        );
        Logger.instance.info('iOS notification permissions granted: $granted');
      }
    } catch (error) {
      Logger.instance.error('Failed to request notification permissions: $error');
    }
  }


  // Handle notification responses (for snooze/dismiss actions)
  void _onNotificationResponse(NotificationResponse response) {
    _handleNotificationResponse(response, isBackground: false);
  }

  // Common notification response handler
  void _handleNotificationResponse(NotificationResponse response, {required bool isBackground}) {
    final payload = response.payload;
    final actionId = response.actionId;

    Logger.instance.info('🔔 Notification response received (background: $isBackground):');
    Logger.instance.info('  - actionId: $actionId');
    Logger.instance.info('  - payload: $payload');
    Logger.instance.info('  - notificationResponseType: ${response.notificationResponseType}');

    if (actionId == 'snooze_action' && payload != null) {
      Logger.instance.info('🔄 Processing snooze action in ${isBackground ? 'background' : 'foreground'}...');
      handleSnoozeAction(payload);
    } else if (actionId == 'dismiss_action' && payload != null) {
      Logger.instance.info('✖️ Processing dismiss action in ${isBackground ? 'background' : 'foreground'}...');
      handleDismissAction(payload);
    } else {
      Logger.instance.info('ℹ️ No matching action found or payload is null');
    }
  }


  // Handle snooze action
  void handleSnoozeAction(String payload) {
    try {
      Logger.instance.info('🔄 Handling snooze action with payload: $payload');

      // Parse payload to extract timeSlot info and current snooze count
      final parts = payload.split('|');
      Logger.instance.info('📝 Payload parts: $parts');

      if (parts.length < 4) {
        Logger.instance.error('❌ Invalid snooze payload format: $payload (expected at least 4 parts, got ${parts.length})');
        return;
      }

      final timeSlotId = parts[0];
      final label = parts[1];
      final snoozeDuration = int.parse(parts[2]);
      final maxSnoozeCount = int.parse(parts[3]);
      final currentSnoozeCount = parts.length > 4 ? int.parse(parts[4]) : 0;

      Logger.instance.info('📊 Snooze parameters:');
      Logger.instance.info('  - timeSlotId: $timeSlotId');
      Logger.instance.info('  - label: $label');
      Logger.instance.info('  - snoozeDuration: $snoozeDuration minutes');
      Logger.instance.info('  - maxSnoozeCount: $maxSnoozeCount');
      Logger.instance.info('  - currentSnoozeCount: $currentSnoozeCount');

      if (currentSnoozeCount >= maxSnoozeCount) {
        Logger.instance.info('⚠️ Max snooze count reached for $label ($currentSnoozeCount/$maxSnoozeCount)');
        return;
      }

      final newSnoozeCount = currentSnoozeCount + 1;
      final snoozeTime = DateTime.now().add(Duration(minutes: snoozeDuration));

      Logger.instance.info('⏰ Scheduling snooze notification for: ${snoozeTime.toString()}');

      // Schedule snoozed notification
      _scheduleSnoozeNotification(
        timeSlotId: timeSlotId,
        label: label,
        snoozeTime: snoozeTime,
        snoozeDuration: snoozeDuration,
        maxSnoozeCount: maxSnoozeCount,
        currentSnoozeCount: newSnoozeCount,
      );

      Logger.instance.info('✅ Successfully snoozed "$label" for $snoozeDuration minutes (attempt $newSnoozeCount/$maxSnoozeCount)');
    } catch (error) {
      Logger.instance.error('❌ Failed to handle snooze action: $error');
    }
  }

  // Handle dismiss action
  void handleDismissAction(String payload) {
    Logger.instance.info('Alarm dismissed: $payload');
    // Notification is automatically dismissed, no further action needed
  }

  // Schedule a snoozed notification
  Future<void> _scheduleSnoozeNotification({
    required String timeSlotId,
    required String label,
    required DateTime snoozeTime,
    required int snoozeDuration,
    required int maxSnoozeCount,
    required int currentSnoozeCount,
  }) async {
    final notificationId = timeSlotId.hashCode.abs() + 50000 + currentSnoozeCount;

    final payload = '$timeSlotId|$label|$snoozeDuration|$maxSnoozeCount|$currentSnoozeCount';

    final title = 'Snoozed: $label';
    final body = 'Snooze attempt $currentSnoozeCount/$maxSnoozeCount';

    // Create snooze actions (if not max attempts)
    final List<AndroidNotificationAction> actions = [];
    if (currentSnoozeCount < maxSnoozeCount) {
      actions.addAll([
        const AndroidNotificationAction(
          'snooze_action',
          'Snooze',
        ),
        const AndroidNotificationAction(
          'dismiss_action',
          'Dismiss',
        ),
      ]);
    }

    final androidDetails = AndroidNotificationDetails(
      'routine_notifications',
      'Routine Notifications',
      channelDescription: 'Snoozed notifications for your scheduled time slots',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      playSound: true,
      actions: actions,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: currentSnoozeCount < maxSnoozeCount ? 'ALARM_CATEGORY' : null,
      interruptionLevel: InterruptionLevel.critical,
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(snoozeTime, tz.local),
        platformChannelSpecifics,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      Logger.instance.info('Scheduled snooze notification for "$label" at $snoozeTime (ID: $notificationId)');
    } catch (error) {
      Logger.instance.error('Failed to schedule snooze notification: $error');
    }
  }

}