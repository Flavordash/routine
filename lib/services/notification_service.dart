import 'dart:io';
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

  if (actionId == 'interval_action' && payload != null) {
    Logger.instance.info('🔄 Processing Smart Intervals action in background...');
    NotificationService.instance.handleIntervalAction(payload).catchError((error) {
      Logger.instance.error('Failed to handle Smart Intervals action in background: $error');
    });
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

    // Setup iOS notification categories with Smart Intervals actions
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
              'interval_action',
              'Next Interval',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              'dismiss_action',
              'Dismiss',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.destructive,
              },
            ),
          ],
          options: <DarwinNotificationCategoryOption>{
            DarwinNotificationCategoryOption.allowInCarPlay,
          },
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
        : timeSlot.smartIntervalsEnabled && timeSlot.smartIntervalMinutes > 0
            ? '${timeSlot.startTime} - ${timeSlot.endTime}\n⏱️ Smart Intervals active (${timeSlot.smartIntervalMinutes}min)'
            : '${timeSlot.startTime} - ${timeSlot.endTime}';

    // Create notification actions for Smart Intervals functionality
    final List<AndroidNotificationAction> actions = [];
    if (!isPreAlarm && timeSlot.smartIntervalsEnabled && timeSlot.smartIntervalMinutes > 0) {
      actions.addAll([
        const AndroidNotificationAction(
          'interval_action',
          'Next Interval ⏱️',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'dismiss_action',
          'Dismiss ✖️',
          showsUserInterface: false,
        ),
      ]);
      Logger.instance.info('📱 Added Smart Intervals and dismiss actions to notification for "${timeSlot.label}"');
    } else {
      Logger.instance.info('⚠️ No Smart Intervals actions added: isPreAlarm=$isPreAlarm, smartIntervalsEnabled=${timeSlot.smartIntervalsEnabled}, intervalMinutes=${timeSlot.smartIntervalMinutes}');
    }

    final androidDetails = AndroidNotificationDetails(
      'routine_notifications',
      'Routine Notifications',
      channelDescription: 'Notifications for your scheduled time slots',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: isPreAlarm
          ? Int64List.fromList([0, 800, 300, 800, 300, 800])
          : Int64List.fromList([0, 1500, 500, 1500, 500, 1500, 500, 1500]),
      playSound: true,
      actions: actions,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: !isPreAlarm,
      additionalFlags: !isPreAlarm ? Int32List.fromList([4]) : null, // FLAG_INSISTENT for main alarms
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: timeSlot.smartIntervalsEnabled && timeSlot.smartIntervalMinutes > 0 && !isPreAlarm ? 'Tap Next Interval or Dismiss' : null,
      ),
      visibility: NotificationVisibility.public,
      showWhen: true,
      ongoing: !isPreAlarm, // Makes notification persistent until dismissed
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: timeSlot.smartIntervalsEnabled && timeSlot.smartIntervalMinutes > 0 && !isPreAlarm ? 'ALARM_CATEGORY' : null,
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
        payload: '${timeSlot.id}|${timeSlot.label}|${timeSlot.smartIntervalMinutes}|${timeSlot.silentIntervals ? 1 : 0}|${timeSlot.showProgressMessages ? 1 : 0}',
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      Logger.instance.info(
        'SUCCESS: Scheduled ${isPreAlarm ? 'pre-' : ''}notification for "${timeSlot.label}" '
        'on $targetDayName at $hour:${minute.toString().padLeft(2, '0')} '
        '(ID: $notificationId, Date: ${notificationTime.toString().split(' ')[0]})'
      );

      // Schedule Smart Intervals if enabled and this is the main alarm (not pre-alarm)
      if (!isPreAlarm && timeSlot.smartIntervalsEnabled && timeSlot.smartIntervalMinutes > 0) {
        await _scheduleSmartIntervals(
          timeSlot: timeSlot,
          mainAlarmTime: notificationTime,
          dayOfWeek: dayOfWeek,
        );
      }
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
    final platform = Platform.isIOS ? 'iOS' : Platform.isAndroid ? 'Android' : 'Unknown';

    Logger.instance.info('🔔 [$platform/${isBackground ? 'BACKGROUND' : 'FOREGROUND'}] Notification response received:');
    Logger.instance.info('  - actionId: $actionId');
    Logger.instance.info('  - payload: $payload');
    Logger.instance.info('  - notificationResponseType: ${response.notificationResponseType}');
    Logger.instance.info('  - input: ${response.input}');
    Logger.instance.info('  - id: ${response.id}');

    if (actionId == 'interval_action' && payload != null) {
      Logger.instance.info('🔄 [$platform] Processing Smart Intervals action in ${isBackground ? 'background' : 'foreground'}...');
      handleIntervalAction(payload).catchError((error) {
        Logger.instance.error('❌ [$platform] Failed to handle Smart Intervals action: $error');
      });
    } else if (actionId == 'dismiss_action' && payload != null) {
      Logger.instance.info('✖️ [$platform] Processing dismiss action in ${isBackground ? 'background' : 'foreground'}...');
      handleDismissAction(payload);
    } else {
      Logger.instance.info('ℹ️ [$platform] No matching action found or payload is null');
      Logger.instance.info('  - Expected actionId: interval_action or dismiss_action');
      Logger.instance.info('  - Actual actionId: $actionId');
      Logger.instance.info('  - Payload available: ${payload != null}');
    }
  }


  // Handle Smart Intervals action
  Future<void> handleIntervalAction(String payload) async {
    try {
      Logger.instance.info('⏱️ Handling Smart Intervals action with payload: $payload');

      // Parse payload to extract timeSlot info
      final parts = payload.split('|');
      Logger.instance.info('📝 Payload parts: $parts');

      if (parts.length < 5) {
        Logger.instance.error('❌ Invalid Smart Intervals payload format: $payload (expected 5 parts, got ${parts.length})');
        return;
      }

      final timeSlotId = parts[0];
      final label = parts[1];
      final intervalMinutes = int.parse(parts[2]);
      final silentIntervals = parts[3] == '1';
      final showProgressMessages = parts[4] == '1';

      Logger.instance.info('📊 Smart Intervals parameters:');
      Logger.instance.info('  - timeSlotId: $timeSlotId');
      Logger.instance.info('  - label: $label');
      Logger.instance.info('  - intervalMinutes: $intervalMinutes');
      Logger.instance.info('  - silentIntervals: $silentIntervals');
      Logger.instance.info('  - showProgressMessages: $showProgressMessages');

      if (intervalMinutes <= 0) {
        Logger.instance.info('⚠️ No interval duration set for $label');
        return;
      }

      final nextIntervalTime = DateTime.now().add(Duration(minutes: intervalMinutes));

      Logger.instance.info('⏰ Scheduling next interval notification for: ${nextIntervalTime.toString()}');

      // Schedule next interval notification
      await _scheduleIntervalNotification(
        timeSlotId: timeSlotId,
        label: label,
        intervalTime: nextIntervalTime,
        intervalMinutes: intervalMinutes,
        silentIntervals: silentIntervals,
        showProgressMessages: showProgressMessages,
        intervalNumber: 1, // This is for manual interval scheduling
      );

      Logger.instance.info('✅ Successfully scheduled next interval for "$label" in $intervalMinutes minutes');
    } catch (error) {
      Logger.instance.error('❌ Failed to handle Smart Intervals action: $error');
    }
  }

  // Handle dismiss action
  void handleDismissAction(String payload) {
    Logger.instance.info('Alarm dismissed: $payload');
    // Notification is automatically dismissed, no further action needed
  }

  // Schedule multiple Smart Intervals notifications for a time slot
  Future<void> _scheduleSmartIntervals({
    required RoutineTimeSlot timeSlot,
    required DateTime mainAlarmTime,
    required int dayOfWeek,
  }) async {
    try {
      Logger.instance.info('⏱️ Scheduling Smart Intervals for "${timeSlot.label}"');
      Logger.instance.info('  - Interval duration: ${timeSlot.smartIntervalMinutes} minutes');
      Logger.instance.info('  - Silent mode: ${timeSlot.silentIntervals}');
      Logger.instance.info('  - Progress messages: ${timeSlot.showProgressMessages}');

      // Parse start and end times
      final startTimeParts = timeSlot.startTime.split(':');
      final endTimeParts = timeSlot.endTime.split(':');
      final startHour = int.parse(startTimeParts[0]);
      final startMinute = int.parse(startTimeParts[1]);
      final endHour = int.parse(endTimeParts[0]);
      final endMinute = int.parse(endTimeParts[1]);

      // Calculate the end time of the time slot
      var endDateTime = DateTime(
        mainAlarmTime.year,
        mainAlarmTime.month,
        mainAlarmTime.day,
        endHour,
        endMinute,
      );

      // Handle next day end time
      if (endHour < startHour || (endHour == startHour && endMinute < startMinute)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }

      // Schedule intervals from start time until end time
      var currentIntervalTime = mainAlarmTime.add(Duration(minutes: timeSlot.smartIntervalMinutes));
      int intervalCount = 1;

      while (currentIntervalTime.isBefore(endDateTime)) {
        await _scheduleIntervalNotification(
          timeSlotId: '${timeSlot.id}_interval_$intervalCount',
          label: timeSlot.label ?? 'Routine Activity',
          intervalTime: currentIntervalTime,
          intervalMinutes: timeSlot.smartIntervalMinutes,
          silentIntervals: timeSlot.silentIntervals,
          showProgressMessages: timeSlot.showProgressMessages,
          intervalNumber: intervalCount,
        );

        currentIntervalTime = currentIntervalTime.add(Duration(minutes: timeSlot.smartIntervalMinutes));
        intervalCount++;
      }

      Logger.instance.info('✅ Scheduled ${intervalCount - 1} Smart Intervals for "${timeSlot.label}"');
    } catch (error) {
      Logger.instance.error('❌ Failed to schedule Smart Intervals for "${timeSlot.label}": $error');
    }
  }

  // Schedule a Smart Intervals notification
  Future<void> _scheduleIntervalNotification({
    required String timeSlotId,
    required String label,
    required DateTime intervalTime,
    required int intervalMinutes,
    required bool silentIntervals,
    required bool showProgressMessages,
    required int intervalNumber,
  }) async {
    // Generate unique notification ID for interval (using interval number to avoid conflicts)
    final notificationId = timeSlotId.hashCode.abs() + 60000 + (intervalNumber * 100);

    final payload = '$timeSlotId|$label|$intervalMinutes|${silentIntervals ? 1 : 0}|${showProgressMessages ? 1 : 0}';

    final title = showProgressMessages ? 'Interval #$intervalNumber: $label' : label;
    final body = showProgressMessages
        ? 'Interval #$intervalNumber - Next in $intervalMinutes minutes'
        : 'Smart Interval #$intervalNumber reminder';

    // Create Smart Intervals actions
    final List<AndroidNotificationAction> actions = [
      const AndroidNotificationAction(
        'interval_action',
        'Next Interval ⏱️',
        showsUserInterface: true,
      ),
      const AndroidNotificationAction(
        'dismiss_action',
        'Dismiss ✖️',
        showsUserInterface: false,
      ),
    ];

    final androidDetails = AndroidNotificationDetails(
      'routine_intervals',
      'Smart Intervals',
      channelDescription: 'Smart Intervals notifications for your time slots',
      importance: silentIntervals ? Importance.low : Importance.max,
      priority: silentIntervals ? Priority.low : Priority.high,
      enableVibration: true,
      vibrationPattern: silentIntervals
          ? Int64List.fromList([0, 400, 200, 400]) // Longer vibration for silent intervals
          : Int64List.fromList([0, 1200, 400, 1200, 400, 1200]), // More intense pattern
      playSound: !silentIntervals,
      actions: actions,
      category: AndroidNotificationCategory.reminder,
      fullScreenIntent: !silentIntervals,
      additionalFlags: silentIntervals ? null : Int32List.fromList([4]), // FLAG_INSISTENT only for non-silent
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: !silentIntervals,
      categoryIdentifier: 'ALARM_CATEGORY',
      interruptionLevel: silentIntervals
          ? InterruptionLevel.passive
          : InterruptionLevel.active,
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
        tz.TZDateTime.from(intervalTime, tz.local),
        platformChannelSpecifics,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      Logger.instance.info('✅ Scheduled Smart Intervals notification #$intervalNumber for "$label"');
      Logger.instance.info('  - Time: ${intervalTime.toString()}');
      Logger.instance.info('  - ID: $notificationId');
      Logger.instance.info('  - Silent: $silentIntervals');
      Logger.instance.info('  - Progress messages: $showProgressMessages');
    } catch (error) {
      Logger.instance.error('Failed to schedule Smart Intervals notification: $error');
    }
  }

  /// Test Smart Intervals functionality with short intervals
  Future<void> testSmartIntervals() async {
    Logger.instance.info('🧪 === SMART INTERVALS TEST ===');

    // Create a test time slot with Smart Intervals enabled
    final now = DateTime.now();
    final startTime = now.add(const Duration(minutes: 1)); // Start in 1 minute
    final endTime = now.add(const Duration(minutes: 10)); // End in 10 minutes (9-minute duration)

    final testTimeSlot = RoutineTimeSlot(
      id: 'test_smart_intervals',
      startAngle: 90,
      endAngle: 120,
      startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      endTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      label: 'Smart Intervals Test',
      hasAlarm: true,
      hasPreAlarm: false,
      smartIntervalsEnabled: true,
      smartIntervalMinutes: 2, // 2 minute intervals for quick testing
      silentIntervals: false,
      showProgressMessages: true,
    );

    final testRoutineSlot = RoutineSlot(
      id: 'test_smart_intervals_routine',
      name: 'Smart Intervals Test Routine',
      isActive: true,
      isPaid: true,
      timeSlots: [testTimeSlot],
      selectedDays: [DateTime.now().weekday], // Today only
    );

    Logger.instance.info('📝 Smart Intervals Test Configuration:');
    Logger.instance.info('  - Start time: ${testTimeSlot.startTime}');
    Logger.instance.info('  - End time: ${testTimeSlot.endTime}');
    Logger.instance.info('  - Duration: 9 minutes');
    Logger.instance.info('  - Interval: ${testTimeSlot.smartIntervalMinutes} minutes');
    Logger.instance.info('  - Expected intervals: 4 (at minutes 3, 5, 7, 9)');
    Logger.instance.info('  - Day: ${DateTime.now().weekday} (today)');

    try {
      // Schedule the test alarm and intervals
      await scheduleActiveRoutineNotifications([testRoutineSlot]);

      Logger.instance.info('✅ Smart Intervals test scheduled successfully!');
      Logger.instance.info('📱 You should receive:');
      Logger.instance.info('  1. Main alarm in ~1 minute');
      Logger.instance.info('  2. Interval #1 in ~3 minutes');
      Logger.instance.info('  3. Interval #2 in ~5 minutes');
      Logger.instance.info('  4. Interval #3 in ~7 minutes');
      Logger.instance.info('  5. Interval #4 in ~9 minutes');
      Logger.instance.info('📋 Each interval notification should have "Next Interval" and "Dismiss" buttons');

    } catch (error) {
      Logger.instance.error('❌ Failed to schedule Smart Intervals test: $error');
    }
  }

  /// Create a comprehensive test routine slot with PRO alarm features
  Future<void> testProAlarmFunctionality() async {
    Logger.instance.info('🧪 === COMPREHENSIVE PRO ALARM TEST ===');

    // Create test routine slot with PRO alarm features
    final testTimeSlot = RoutineTimeSlot(
      id: 'test_pro_alarm',
      startAngle: 90,
      endAngle: 120,
      startTime: '${DateTime.now().add(Duration(minutes: 1)).hour.toString().padLeft(2, '0')}:${DateTime.now().add(Duration(minutes: 1)).minute.toString().padLeft(2, '0')}',
      endTime: '${DateTime.now().add(Duration(minutes: 2)).hour.toString().padLeft(2, '0')}:${DateTime.now().add(Duration(minutes: 2)).minute.toString().padLeft(2, '0')}',
      label: 'PRO Alarm Test',
      hasAlarm: true,
      hasPreAlarm: true,
      preAlarmMinutes: 1, // 1 minute before main alarm
      smartIntervalsEnabled: true,
      smartIntervalMinutes: 1, // 1 minute intervals for quick testing
      silentIntervals: false,
      showProgressMessages: true,
    );

    final testRoutineSlot = RoutineSlot(
      id: 'test_pro_routine',
      name: 'PRO Alarm Test Routine',
      isActive: true,
      isPaid: true,
      timeSlots: [testTimeSlot],
      selectedDays: [DateTime.now().weekday], // Today only
    );

    Logger.instance.info('📝 Test Configuration:');
    Logger.instance.info('  - Main alarm time: ${testTimeSlot.startTime}');
    Logger.instance.info('  - Pre-alarm: ${testTimeSlot.preAlarmMinutes} minutes before');
    Logger.instance.info('  - Smart Intervals: ${testTimeSlot.smartIntervalMinutes} minutes, silent: ${testTimeSlot.silentIntervals}');
    Logger.instance.info('  - Day: ${DateTime.now().weekday} (today)');

    try {
      // Schedule the test alarm
      await scheduleActiveRoutineNotifications([testRoutineSlot]);

      Logger.instance.info('✅ PRO alarm test scheduled successfully!');
      Logger.instance.info('📅 Expected timeline:');
      Logger.instance.info('  - Pre-alarm: ${DateTime.now().add(Duration(minutes: 0)).toString().split('.')[0]}');
      Logger.instance.info('  - Main alarm: ${DateTime.now().add(Duration(minutes: 1)).toString().split('.')[0]}');

      Logger.instance.info('⏰ Watch for notifications in the next 2 minutes');
      Logger.instance.info('📱 When notifications appear, test the snooze functionality');

    } catch (error) {
      Logger.instance.error('❌ Failed to schedule PRO alarm test: $error');
    }

    Logger.instance.info('🧪 === END PRO ALARM TEST ===');
  }

  /// Quick test for immediate PRO alarm with all features
  Future<void> testProAlarmImmediate() async {
    Logger.instance.info('🚀 === IMMEDIATE PRO ALARM TEST ===');

    try {
      // Schedule a notification 5 seconds from now with PRO features
      final testTime = DateTime.now().add(Duration(seconds: 5));

      await scheduleTestNotification(
        time: testTime,
        title: 'PRO Alarm Test - 5s',
        body: 'This is a test of PRO alarm features. Try the Snooze button!',
      );

      Logger.instance.info('✅ Immediate PRO alarm test scheduled for 5 seconds from now');
      Logger.instance.info('📱 Expected at: ${testTime.toString().split('.')[0]}');
      Logger.instance.info('🔔 This notification will have Snooze and Dismiss buttons');

    } catch (error) {
      Logger.instance.error('❌ Failed to schedule immediate PRO alarm test: $error');
    }

    Logger.instance.info('🚀 === END IMMEDIATE TEST ===');
  }

  /// Test iOS-specific snooze functionality
  Future<void> testIOSSnooze() async {
    Logger.instance.info('🍎 === iOS SNOOZE TEST ===');

    if (!Platform.isIOS) {
      Logger.instance.info('⚠️ This test is for iOS only. Current platform: ${Platform.operatingSystem}');
      return;
    }

    try {
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'ALARM_CATEGORY',
        interruptionLevel: InterruptionLevel.critical,
      );

      const platformChannelSpecifics = NotificationDetails(
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        997, // Unique ID for iOS snooze test
        'iOS Snooze Test',
        'Tap Snooze to test iOS notification actions. Check logs for detailed debugging.',
        platformChannelSpecifics,
        payload: 'ios_test|iOS Snooze Test|1|2|0', // 1min snooze, max 2 attempts
      );

      Logger.instance.info('✅ iOS snooze test notification sent');
      Logger.instance.info('🔔 Category: ALARM_CATEGORY');
      Logger.instance.info('📋 Expected actions: Snooze, Dismiss');
      Logger.instance.info('⚠️ If actions don\'t appear, check iOS notification settings');

    } catch (error) {
      Logger.instance.error('❌ Failed to send iOS snooze test: $error');
    }

    Logger.instance.info('🍎 === END iOS TEST ===');
  }

  /// Test snooze functionality specifically
  Future<void> testSnoozeOnly() async {
    Logger.instance.info('🔔 === SNOOZE-FOCUSED TEST ===');

    try {
      const androidDetails = AndroidNotificationDetails(
        'test_notifications',
        'Test Notifications',
        channelDescription: 'Test snooze functionality',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        actions: [
          AndroidNotificationAction(
            'snooze_action',
            'Snooze (2min)',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'dismiss_action',
            'Dismiss',
            showsUserInterface: false,
          ),
        ],
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        styleInformation: BigTextStyleInformation(
          'Tap SNOOZE to test snooze functionality. It should reschedule for 2 minutes later.',
          contentTitle: 'Snooze Test - Tap Snooze!',
          summaryText: 'Test: snooze → wait 2min → repeat',
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
        996, // Unique ID for snooze test
        'Snooze Test - Tap Snooze!',
        'Tap SNOOZE to test snooze functionality. It should reschedule for 2 minutes later.',
        platformChannelSpecifics,
        payload: 'snooze_test|Snooze Test|2|3|0', // 2min snooze, max 3 attempts, current count 0
      );

      Logger.instance.info('✅ Snooze test notification sent with actions');
      Logger.instance.info('🔔 Payload: snooze_test|Snooze Test|2|3|0');
      Logger.instance.info('📋 Test steps:');
      Logger.instance.info('  1. Tap "Snooze (2min)" button on the notification');
      Logger.instance.info('  2. Wait 2 minutes for snoozed notification');
      Logger.instance.info('  3. Check if snooze count increments correctly');
      Logger.instance.info('  4. Test max snooze limit (3 attempts)');

    } catch (error) {
      Logger.instance.error('❌ Failed to send snooze test notification: $error');
    }

    Logger.instance.info('🔔 === END SNOOZE TEST ===');
  }

}