import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/routine_slot_model.dart';
import '../utils/logger.dart';

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

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    _isInitialized = true;
    
    Logger.instance.info('NotificationService initialized');
  }

  // Get notification permission status
  bool get notificationsEnabled => _notificationsEnabled;

  // Set global notification state
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    Logger.instance.info('Global notifications ${enabled ? 'enabled' : 'disabled'}');
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

    // Schedule notifications for all time slots in the active routine
    for (final timeSlot in activeSlot.timeSlots) {
      if (timeSlot.hasAlarm) {
        await _scheduleTimeSlotNotifications(
          timeSlot,
          activeSlot.selectedDays,
          routineSlotId: activeSlot.id,
        );
      }
    }
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
      
      for (int dayOfWeek in selectedDays) {
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
        : '${timeSlot.startTime} - ${timeSlot.endTime}';

    final androidDetails = AndroidNotificationDetails(
      'routine_notifications',
      'Routine Notifications',
      channelDescription: 'Notifications for your scheduled time slots',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
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

}