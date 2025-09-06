import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:rive/rive.dart' as rive;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:vibration/vibration.dart';
import 'models/routine_slot_model.dart';
import 'l10n/app_localizations.dart';
import 'services/ad_service.dart';
import 'services/purchase_service.dart';

class TimeSlot {
  final String id;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final String title;
  final String description;
  final Color color;
  final bool notificationEnabled;
  final bool hasAlarm;
  final bool hasPreAlarm;
  final int preAlarmMinutes;
  final bool snoozeEnabled;
  final int snoozeDuration;
  final int maxSnoozeCount;

  TimeSlot({
    required this.id,
    required this.startHour,
    this.startMinute = 0,
    required this.endHour,
    this.endMinute = 0,
    required this.title,
    this.description = '',
    required this.color,
    this.notificationEnabled = true,
    this.hasAlarm = false,
    this.hasPreAlarm = false,
    this.preAlarmMinutes = 15,
    this.snoozeEnabled = true,
    this.snoozeDuration = 10,
    this.maxSnoozeCount = 3,
  });
}

const List<Color> availableColors = [
  Color(0xFFFF6B6B), // Red
  Color(0xFF4ECDC4), // Teal
  Color(0xFF45B7D1), // Blue
  Color(0xFF96CEB4), // Green
  Color(0xFFFECA57), // Yellow
  Color(0xFFFF9FF3), // Pink
  Color(0xFF54A0FF), // Light Blue
  Color(0xFF5F27CD), // Purple
  Color(0xFFFF6348), // Orange
  Color(0xFF01A3A4), // Dark Teal
];

class SelectableClockWidget extends StatefulWidget {
  const SelectableClockWidget({
    super.key, 
    required this.isDarkMode,
    this.onBackgroundTap,
    this.isProUser = false,
    this.timeSlots = const [],
    this.onTimeSlotsChanged,
  });

  final bool isDarkMode;
  final VoidCallback? onBackgroundTap;
  final bool isProUser;
  final List<RoutineTimeSlot> timeSlots;
  final Function(List<RoutineTimeSlot>)? onTimeSlotsChanged;

  @override
  State<SelectableClockWidget> createState() => _SelectableClockWidgetState();
}

class _SelectableClockWidgetState extends State<SelectableClockWidget> with TickerProviderStateMixin {
  int? startHour;
  int? endHour;
  List<TimeSlot> timeSlots = [];
  late AnimationController _highlightController;
  late AnimationController _addButtonController;
  late Animation<double> _highlightAnimation;
  late AnimationController _pulseController;
  late AnimationController _sparkController;
  late Animation<double> _sparkAnimation;
  final List<SparkParticle> _sparks = [];

  // Purchase service
  late PurchaseService _purchaseService;

  // Notification settings
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool globalNotificationsEnabled = true;

  // Removed hover functionality as it doesn't work on mobile

  @override
  void initState() {
    super.initState();

    // Convert widget timeSlots to internal TimeSlot format
    timeSlots = widget.timeSlots.map(_routineTimeSlotToTimeSlot).toList();
    

    // Initialize main animations first
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _highlightAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _sparkController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _sparkAnimation = CurvedAnimation(
      parent: _sparkController,
      curve: Curves.easeOut,
    );

    _addButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _initializeNotifications();
    _initializePurchaseService();
  }

  @override
  void didUpdateWidget(SelectableClockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update internal timeSlots when widget timeSlots change
    if (oldWidget.timeSlots != widget.timeSlots) {
      setState(() {
        timeSlots = widget.timeSlots.map(_routineTimeSlotToTimeSlot).toList();
      });
    }
    
    // Force rebuild when theme changes
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      setState(() {
        // This will trigger a rebuild with the correct Rive animation
      });
    }
  }

  Widget _buildBackgroundAnimation() {
    return rive.RiveAnimation.asset(
      widget.isDarkMode
          ? 'assets/animations/circle_board.riv'
          : 'assets/animations/circle_light.riv',
      key: ValueKey('rive_${widget.isDarkMode ? 'dark' : 'light'}'),
      fit: BoxFit.contain,
    );
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    
    // Request permissions explicitly for iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // Test vibration method
  Future<void> _testVibration() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      // Custom vibration pattern: [wait, vibrate, wait, vibrate]
      Vibration.vibrate(pattern: [0, 1000, 500, 1000]);
    }
  }

  Future<void> _scheduleNotification(TimeSlot slot, {List<int>? selectedDays}) async {
    if (!globalNotificationsEnabled || !slot.notificationEnabled) return;

    // Default to all days if not specified
    final days = selectedDays ?? [1, 2, 3, 4, 5, 6, 7];
    
    // Schedule notification for each selected day of the week
    for (int dayOfWeek in days) {
      final now = DateTime.now();
      final currentDayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday
      
      // Calculate days until the target day
      int daysUntilTarget = (dayOfWeek - currentDayOfWeek) % 7;
      if (daysUntilTarget == 0) {
        // It's today - check if time has passed
        final todayScheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          slot.startHour,
          slot.startMinute,
        );
        
        if (todayScheduledTime.isBefore(now)) {
          daysUntilTarget = 7; // Schedule for next week
        }
      }
      
      final notificationTime = DateTime(
        now.year,
        now.month,
        now.day + daysUntilTarget,
        slot.startHour,
        slot.startMinute,
      );

      final androidDetails = AndroidNotificationDetails(
        'routine_notifications',
        'Routine Notifications',
        channelDescription: 'Notifications for your scheduled time slots',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]), // Vibration pattern
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

      await flutterLocalNotificationsPlugin.zonedSchedule(
        slot.id.hashCode + dayOfWeek, // Unique ID for each day
        'Time for: ${slot.title}',
        '${_formatTimeWithMinutes(slot.startHour, slot.startMinute)} - ${_formatTimeWithMinutes(slot.endHour, slot.endMinute)}',
        tz.TZDateTime.from(notificationTime, tz.local),
        platformChannelSpecifics,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // Repeat weekly
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> _cancelNotification(String slotId) async {
    await flutterLocalNotificationsPlugin.cancel(slotId.hashCode);
  }

  void _handleBackgroundTap() {
    // Clear selection if there's an active selection
    if (startHour != null || endHour != null) {
      _clearSelection();
    }
    widget.onBackgroundTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleBackgroundTap,
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
        // Clock Circle
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque, // This prevents background tap
            onTapDown: _handleTap,
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: SizedBox(
              width: 300, // Reduced from 360 to 300
              height: 300, // Reduced from 360 to 300
              child: Stack(
                children: [
                  // Background circle animation (always show)
                  _buildBackgroundAnimation(),
                  // Overlay for existing time slots
                  CustomPaint(
                    painter: TimeSlotsPainter(timeSlots: timeSlots),
                    size: const Size(
                      300,
                      300,
                    ), // Updated to match new circle size
                  ),
                  // Overlay for current selection
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _highlightAnimation,
                      _pulseController,
                    ]),
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ClockPainter(
                          startHour: startHour,
                          endHour: endHour,
                          highlightAnimation: _highlightAnimation.value,
                          pulseAnimation: _pulseController.value,
                          selectionColor: Theme.of(context).colorScheme.primary,
                        ),
                        size: const Size(
                          300,
                          300,
                        ), // Updated to match new circle size
                      );
                    },
                  ),
                  // Spark animation overlay
                  AnimatedBuilder(
                    animation: _sparkAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: SparkPainter(
                          sparks: _sparks,
                          progress: _sparkAnimation.value,
                        ),
                        size: const Size(300, 300),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        // Time Slots Cards Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.yourTimeSlots,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              // Add button for manual creation
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () {
                    _addButtonController.forward().then((_) {
                      _addButtonController.reverse();
                    });
                    _showCreateTimeSlotModal();
                  },
                  icon: AnimatedIcon(
                    icon: AnimatedIcons.add_event,
                    progress: _addButtonController,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (timeSlots.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: timeSlots.length,
              itemBuilder: (context, index) {
                return _buildTimeSlotCard(timeSlots[index]);
              },
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.noTimeSlotsYet,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Ad Banner / Pro Status
          const SizedBox(height: 20),
          _buildBanner(),
        ],
      ),
    );
  }

  // Hover functionality removed - not needed for mobile touch interface

  void _handleTap(TapDownDetails details) {
    const center = Offset(150, 150); // Updated center point (half of 300)
    final tappedHour = _getHourFromPosition(details.localPosition, center);

    // Check if tapping on an existing time slot - do nothing (use cards to edit)
    final existingSlot = _findTimeSlotAtHour(tappedHour);
    if (existingSlot != null) {
      // Don't open modal for existing slots - user should use cards below
      // But still clear any current selection
      if (startHour != null || endHour != null) {
        _clearSelection();
      }
      return;
    }

    // Check if tapping on current selection (with more generous range for small selections)
    if (startHour != null && endHour != null) {
      if (_isHourInSelectionWithTolerance(tappedHour)) {
        _showTimeModal();
        return;
      } else {
        // Tapping outside current selection - always clear it
        _clearSelection();
        return;
      }
    }

    // No current selection, so this tap doesn't do anything
  }

  bool _isHourInSelectionWithTolerance(int hour) {
    if (startHour == null || endHour == null) return false;

    int start = startHour!;
    int end = endHour!;

    // Add tolerance for small selections (1-2 hours)
    int duration = _calculateDuration();
    if (duration <= 2) {
      // For small selections, allow clicking 1 hour before or after
      start = (start - 1 + 24) % 24;
      end = (end + 1) % 24;
    }

    // Handle wrap-around cases
    if (start <= end) {
      return hour >= start && hour <= end;
    } else {
      return hour >= start || hour <= end;
    }
  }

  TimeSlot? _findTimeSlotAtHour(int hour) {
    for (final slot in timeSlots) {
      if (_isHourInTimeSlot(hour, slot)) {
        return slot;
      }
    }
    return null;
  }

  bool _isHourInTimeSlot(int hour, TimeSlot slot) {
    int start = slot.startHour;
    int end = slot.endHour;

    // Handle same hour case (check if the hour contains any part of the slot)
    if (start == end) {
      return hour == start;
    }

    if (start <= end) {
      return hour >= start && hour < end; // Exclude end hour
    } else {
      return hour >= start || hour < end; // Exclude end hour
    }
  }

  void _clearSelection() {
    // Stop any running animations
    _pulseController.stop();
    _pulseController.reset();

    // Animate out and clear
    _highlightController.reverse().then((_) {
      if (mounted) {
        setState(() {
          startHour = null;
          endHour = null;
        });
      }
    });
  }

  void _showTimeModal() {
    _showCreateTimeSlotModal();
  }

  void _showCreateTimeSlotModal([TimeSlot? existingSlot]) {
    final titleController = TextEditingController(
      text: existingSlot?.title ?? '',
    );
    final descriptionController = TextEditingController(
      text: existingSlot?.description ?? '',
    );
    Color selectedColor = existingSlot?.color ?? availableColors[0];
    bool notificationEnabled =
        existingSlot?.notificationEnabled ?? globalNotificationsEnabled;
    
    // Pro alarm settings
    bool hasAlarm = existingSlot?.hasAlarm ?? widget.isProUser;
    bool hasPreAlarm = existingSlot?.hasPreAlarm ?? false;
    int preAlarmMinutes = existingSlot?.preAlarmMinutes ?? 15;
    bool snoozeEnabled = existingSlot?.snoozeEnabled ?? true;
    int snoozeDuration = existingSlot?.snoozeDuration ?? 10;
    int maxSnoozeCount = existingSlot?.maxSnoozeCount ?? 3;

    // Initialize time values with proper null handling
    int selectedStartHour = existingSlot?.startHour ?? (startHour ?? 0);
    int selectedStartMinute = existingSlot?.startMinute ?? 0;
    int selectedEndHour =
        existingSlot?.endHour ?? (endHour ?? (selectedStartHour + 1) % 24);
    int selectedEndMinute = existingSlot?.endMinute ?? 0;

    // Ensure minute values are valid (5-minute intervals)
    final validMinutes = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];
    if (!validMinutes.contains(selectedStartMinute)) selectedStartMinute = 0;
    if (!validMinutes.contains(selectedEndMinute)) selectedEndMinute = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 1,
                ),
              ),
              title: Text(
                existingSlot != null ? AppLocalizations.of(context)!.editTimeSlot : AppLocalizations.of(context)!.createTimeSlot,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time Range Display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: selectedColor, width: 1),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${_formatTimeWithMinutes(selectedStartHour, selectedStartMinute)} - ${_formatTimeWithMinutes(selectedEndHour, selectedEndMinute)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Duration: ${_calculateDurationWithMinutes(selectedStartHour, selectedStartMinute, selectedEndHour, selectedEndMinute)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title Input
                    Text(
                      AppLocalizations.of(context)!.titleOfThisTime,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.titleHint,
                        hintStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description Input
                    Text(
                      AppLocalizations.of(context)!.descriptionOfThisTime,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 1, // Restrict to one line
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.descriptionHint,
                        hintStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Time Adjustment Section
                    Text(
                      AppLocalizations.of(context)!.adjustTime,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Start Time
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.from,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              // Start Hour
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: selectedStartHour,
                                  dropdownColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  items: List.generate(
                                    24,
                                    (index) => DropdownMenuItem(
                                      value: index,
                                      child: Text(
                                        index.toString().padLeft(2, '0'),
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setModalState(() {
                                      selectedStartHour = value!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Start Minute
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: selectedStartMinute,
                                  dropdownColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  items: [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]
                                      .map(
                                        (minute) => DropdownMenuItem(
                                          value: minute,
                                          child: Text(
                                            '${minute.toString().padLeft(2, '0')}m',
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setModalState(() {
                                      selectedStartMinute = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // End Time
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.to,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              // End Hour
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: selectedEndHour,
                                  dropdownColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  items: List.generate(
                                    24,
                                    (index) => DropdownMenuItem(
                                      value: index,
                                      child: Text(
                                        index.toString().padLeft(2, '0'),
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setModalState(() {
                                      selectedEndHour = value!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // End Minute
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: selectedEndMinute,
                                  dropdownColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  items: [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]
                                      .map(
                                        (minute) => DropdownMenuItem(
                                          value: minute,
                                          child: Text(
                                            '${minute.toString().padLeft(2, '0')}m',
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setModalState(() {
                                      selectedEndMinute = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Color Picker
                    Text(
                      AppLocalizations.of(context)!.chooseColor,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableColors.map((color) {
                        final isSelected = color == selectedColor;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Notification Toggle
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.enableNotifications,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Switch(
                          value: notificationEnabled,
                          onChanged: (value) {
                            setModalState(() {
                              notificationEnabled = value;
                            });
                          },
                          activeThumbColor: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                          activeTrackColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                          inactiveThumbColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                          inactiveTrackColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                        ),
                      ],
                    ),
                    
                    // Pro Alarm Settings Section
                    if (notificationEnabled) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'PRO Alarm Settings',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            if (widget.isProUser) ...[
                              // Pre-Alarm Settings
                                Row(
                                  children: [
                                    Icon(
                                      Icons.alarm_add,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Pre-Alarm',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Switch(
                                      value: hasPreAlarm,
                                      onChanged: (value) {
                                        setModalState(() {
                                          hasPreAlarm = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                
                                if (hasPreAlarm) ...[
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 26),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Pre-alarm time:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ),
                                        DropdownButton<int>(
                                          value: preAlarmMinutes,
                                          underline: Container(),
                                          items: [5, 10, 15, 20, 30].map((minutes) {
                                            return DropdownMenuItem(
                                              value: minutes,
                                              child: Text(
                                                '$minutes min',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setModalState(() {
                                              preAlarmMinutes = value!;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                const SizedBox(height: 12),
                                
                                // Snooze Settings
                                Row(
                                  children: [
                                    Icon(
                                      Icons.snooze,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Allow Snooze',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Switch(
                                      value: snoozeEnabled,
                                      onChanged: (value) {
                                        setModalState(() {
                                          snoozeEnabled = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                
                                if (snoozeEnabled) ...[
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 26),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Duration:',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                            DropdownButton<int>(
                                              value: snoozeDuration,
                                              underline: Container(),
                                              items: [5, 10, 15, 20].map((minutes) {
                                                return DropdownMenuItem(
                                                  value: minutes,
                                                  child: Text(
                                                    '$minutes min',
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                setModalState(() {
                                                  snoozeDuration = value!;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Max attempts:',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                            DropdownButton<int>(
                                              value: maxSnoozeCount,
                                              underline: Container(),
                                              items: [1, 2, 3, 4, 5].map((count) {
                                                return DropdownMenuItem(
                                                  value: count,
                                                  child: Text(
                                                    '$count times',
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                setModalState(() {
                                                  maxSnoozeCount = value!;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                            ] else ...[
                              // Free User Upgrade Prompt
                              Column(
                                children: [
                                  Text(
                                    'Get advanced alarm features with pre-alarm warnings and snooze functionality.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _showUpgradeDialog();
                                      },
                                      child: Text(
                                        'Upgrade to PRO',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (existingSlot != null)
                  TextButton(
                    onPressed: () {
                      timeSlots.remove(existingSlot);
                      _cancelNotification(existingSlot.id);
                      Navigator.of(context).pop();
                      setState(() {});
                      _notifyTimeSlotsChanged();
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      return;
                    }

                    final newSlot = TimeSlot(
                      id:
                          existingSlot?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      startHour: selectedStartHour,
                      startMinute: selectedStartMinute,
                      endHour: selectedEndHour,
                      endMinute: selectedEndMinute,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      color: selectedColor,
                      notificationEnabled: notificationEnabled,
                      hasAlarm: hasAlarm,
                      hasPreAlarm: hasPreAlarm,
                      preAlarmMinutes: preAlarmMinutes,
                      snoozeEnabled: snoozeEnabled,
                      snoozeDuration: snoozeDuration,
                      maxSnoozeCount: maxSnoozeCount,
                    );

                    if (existingSlot != null) {
                      final index = timeSlots.indexOf(existingSlot);
                      timeSlots[index] = newSlot;
                      _cancelNotification(existingSlot.id);
                    } else {
                      timeSlots.add(newSlot);
                      // Trigger spark animation for new slots
                      _triggerSparkAnimation(selectedColor);
                    }
                    _notifyTimeSlotsChanged();

                    // Schedule notification if enabled
                    _scheduleNotification(newSlot);

                    Navigator.of(context).pop();
                    _clearSelection();
                    setState(() {});
                  },
                  child: Text(existingSlot != null ? AppLocalizations.of(context)!.update : AppLocalizations.of(context)!.create),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: slot.color, width: 2),
        ),
        child: InkWell(
          onTap: () => _showCreateTimeSlotModal(slot),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: slot.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        slot.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          final index = timeSlots.indexOf(slot);
                          final updatedSlot = TimeSlot(
                            id: slot.id,
                            startHour: slot.startHour,
                            startMinute: slot.startMinute,
                            endHour: slot.endHour,
                            endMinute: slot.endMinute,
                            title: slot.title,
                            description: slot.description,
                            color: slot.color,
                            notificationEnabled: !slot.notificationEnabled,
                          );
                          timeSlots[index] = updatedSlot;
                          _notifyTimeSlotsChanged();

                          if (updatedSlot.notificationEnabled) {
                            _scheduleNotification(updatedSlot);
                          } else {
                            _cancelNotification(updatedSlot.id);
                          }
                        });
                      },
                      child: Icon(
                        slot.notificationEnabled
                            ? Icons.notifications
                            : Icons.notifications_off,
                        color: slot.notificationEnabled
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3),
                        size: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Description (if not empty)
                if (slot.description.isNotEmpty) ...[
                  Text(
                    slot.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  '${_formatTimeWithMinutes(slot.startHour, slot.startMinute)} - ${_formatTimeWithMinutes(slot.endHour, slot.endMinute)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '${_calculateDurationWithMinutes(slot.startHour, slot.startMinute, slot.endHour, slot.endMinute)} duration',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _calculateDuration() {
    if (startHour == null || endHour == null) return 0;

    int start = startHour!;
    int end = endHour!;

    if (start <= end) {
      return end - start;
    } else {
      return (24 - start) + end;
    }
  }

  void _handlePanStart(DragStartDetails details) {
    const center = Offset(
      150,
      150,
    ); // Updated center point (half of 300) // Half of the size
    final hour = _getHourFromPosition(details.localPosition, center);

    // Don't start dragging if starting on an existing time slot
    final existingSlot = _findTimeSlotAtHour(hour);
    if (existingSlot != null) {
      return;
    }

    setState(() {
      startHour = hour;
      endHour = hour;
    });

    _highlightController.forward();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    const center = Offset(150, 150); // Updated center point (half of 300)
    final hour = _getHourFromPosition(details.localPosition, center);

    setState(() {
      endHour = hour;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    _pulseController.repeat(reverse: true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _pulseController.stop();
        _pulseController.reset();
      }
    });

    if (startHour != null && endHour != null) {
      debugPrint(
        'Selected time range: ${_formatHour(startHour!)} - ${_formatHour(endHour!)}',
      );
    }
  }

  int _getHourFromPosition(Offset position, Offset center) {
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;

    // Calculate angle from center, with 0 degrees at top (12 o'clock position)
    double angle = math.atan2(dx, -dy);

    // Convert to degrees and normalize to 0-360
    angle = (angle * 180 / math.pi) % 360;
    if (angle < 0) angle += 360;

    // Map to 24 hours: 0° = 0h, 90° = 6h, 180° = 12h, 270° = 18h
    int hour = ((angle / 15).round()) % 24;
    return hour;
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour < 12) return '$hour:00 AM';
    if (hour == 12) return '12:00 PM';
    return '${hour - 12}:00 PM';
  }

  String _formatTimeWithMinutes(int hour, int minute) {
    String period = hour < 12 ? 'AM' : 'PM';
    int displayHour = hour;
    if (hour == 0) {
      displayHour = 12;
    } else if (hour > 12) {
      displayHour = hour - 12;
    }
    return '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _calculateDurationWithMinutes(
    int startHour,
    int startMinute,
    int endHour,
    int endMinute,
  ) {
    int startMinutes = startHour * 60 + startMinute;
    int endMinutes = endHour * 60 + endMinute;

    if (endMinutes <= startMinutes) {
      endMinutes += 24 * 60; // Add 24 hours
    }

    int durationMinutes = endMinutes - startMinutes;
    int hours = durationMinutes ~/ 60;
    int minutes = durationMinutes % 60;

    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }

  void _triggerSparkAnimation(Color color) {
    _sparks.clear();

    // Generate sparks around the circle
    const center = Offset(150, 150);
    const radius = 120;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180; // Every 30 degrees
      final startX = center.dx + math.cos(angle) * radius;
      final startY = center.dy + math.sin(angle) * radius;

      _sparks.add(
        SparkParticle(
          startPosition: Offset(startX, startY),
          angle: angle,
          color: color,
        ),
      );
    }

    _sparkController.reset();
    _sparkController.forward();
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.onSurface,
            width: 1,
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.star,
              color: Colors.amber,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.upgradeToProButton,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.proFeatures),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.unlimitedSlots),
            Text(AppLocalizations.of(context)!.scheduleSpecificDaysFull),
            Text(AppLocalizations.of(context)!.duplicateRoutines),
            Text(AppLocalizations.of(context)!.advancedNotificationsFull),
            Text(AppLocalizations.of(context)!.prioritySupport),
            Text(AppLocalizations.of(context)!.advancedCustomization),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.later,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSubscriptionDialog();
            },
            child: Text(AppLocalizations.of(context)!.upgradeNow),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.onSurface,
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.upgradeToProButton,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.getUnlimitedAccess,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Pro Features List
                _buildProFeature(Icons.block, AppLocalizations.of(context)!.removeAllAds),
                _buildProFeature(Icons.all_inclusive, AppLocalizations.of(context)!.unlimitedSlots.substring(2)), // Remove the bullet point
                _buildProFeature(Icons.calendar_today, AppLocalizations.of(context)!.scheduleSpecificDays),
                _buildProFeature(Icons.notifications_active, AppLocalizations.of(context)!.advancedNotifications),
                _buildProFeature(Icons.backup, AppLocalizations.of(context)!.cloudSyncBackup),
                _buildProFeature(Icons.support, AppLocalizations.of(context)!.prioritySupport.substring(2)), // Remove the bullet point
                
                const SizedBox(height: 20),
                
                // Subscription Options
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.chooseYourPlan,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Monthly Plan
                      _buildSubscriptionOption(
                        title: AppLocalizations.of(context)!.monthlyPlan,
                        price: AppLocalizations.of(context)!.monthlyPrice,
                        savings: null,
                        isPopular: false,
                        onTap: () => _purchaseSubscription(monthly: true),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Yearly Plan  
                      _buildSubscriptionOption(
                        title: AppLocalizations.of(context)!.yearlyPlan,
                        price: AppLocalizations.of(context)!.yearlyPrice,
                        savings: AppLocalizations.of(context)!.savingsText,
                        isPopular: true,
                        onTap: () => _purchaseSubscription(monthly: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.later,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restorePurchases();
              },
              child: Text(
                AppLocalizations.of(context)!.restore,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOption({
    required String title,
    required String price,
    String? savings,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPopular 
            ? Colors.amber.withValues(alpha: 0.2)
            : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPopular ? Colors.amber : Colors.grey,
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (isPopular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  AppLocalizations.of(context)!.popular,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isPopular) const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    price,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  if (savings != null)
                    Text(
                      savings,
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  void _purchaseSubscription({required bool monthly}) {
    Navigator.of(context).pop();
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.processingPurchase,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );

    // Use actual purchase service
    final productId = monthly 
        ? PurchaseService.kMonthlySubscriptionId 
        : PurchaseService.kYearlySubscriptionId;
    _purchaseService.buySubscription(productId);
  }

  void _restorePurchases() {
    Navigator.of(context).pop();
    
    // Use actual restore service
    _purchaseService.restorePurchases();
  }

  void _initializePurchaseService() {
    _purchaseService = PurchaseService();
    _purchaseService.onPurchaseSuccess = () {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase successful! You now have PRO access.'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the widget to show PRO features
        setState(() {});
      }
    };
    
    _purchaseService.onPurchaseError = (error) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    };
    
    _purchaseService.onRestoreSuccess = () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchases restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    };
    
    _purchaseService.onRestoreError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    };
    
    _purchaseService.initialize();
  }

  @override
  void dispose() {
    _highlightController.dispose();
    _pulseController.dispose();
    _sparkController.dispose();
    _addButtonController.dispose();
    _purchaseService.dispose();
    super.dispose();
  }

  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isProUser 
                ? [Colors.amber.shade300, Colors.amber.shade600]
                : [Colors.blue.shade300, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (widget.isProUser ? Colors.amber : Colors.blue).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: widget.isProUser ? _buildProBanner() : _buildAdBanner(),
      ),
    );
  }

  Widget _buildProBanner() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.star,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.proMember,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context)!.thanksForSupporting,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdBanner() {
    // Initialize banner ad if not already done
    if (AdService.instance.bannerAd == null) {
      AdService.instance.createBannerAd();
    }

    return Column(
      children: [
        // Real AdMob Banner Ad
        Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: AdService.instance.bannerAd != null
              ? AdWidget(ad: AdService.instance.bannerAd!)
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.ads_click,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Loading Ad...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.upgradeToProAd,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Helper methods to convert between TimeSlot and RoutineTimeSlot
  TimeSlot _routineTimeSlotToTimeSlot(RoutineTimeSlot routineTimeSlot) {
    final startTime = routineTimeSlot.startTime.split(':');
    final endTime = routineTimeSlot.endTime.split(':');
    
    return TimeSlot(
      id: routineTimeSlot.id,
      startHour: int.tryParse(startTime[0]) ?? 0,
      startMinute: int.tryParse(startTime[1]) ?? 0,
      endHour: int.tryParse(endTime[0]) ?? 0,
      endMinute: int.tryParse(endTime[1]) ?? 0,
      title: routineTimeSlot.label ?? 'Routine',
      description: routineTimeSlot.description ?? '',
      color: routineTimeSlot.color != null 
        ? Color(routineTimeSlot.color!) 
        : availableColors.first,
      notificationEnabled: true,
    );
  }

  RoutineTimeSlot _timeSlotToRoutineTimeSlot(TimeSlot timeSlot) {
    return RoutineTimeSlot(
      id: timeSlot.id,
      startAngle: _hourToAngle(timeSlot.startHour, timeSlot.startMinute),
      endAngle: _hourToAngle(timeSlot.endHour, timeSlot.endMinute),
      startTime: '${timeSlot.startHour.toString().padLeft(2, '0')}:${timeSlot.startMinute.toString().padLeft(2, '0')}',
      endTime: '${timeSlot.endHour.toString().padLeft(2, '0')}:${timeSlot.endMinute.toString().padLeft(2, '0')}',
      label: timeSlot.title,
      description: timeSlot.description,
      color: timeSlot.color.toARGB32(),
      createdAt: DateTime.now(),
    );
  }

  double _hourToAngle(int hour, int minute) {
    final totalMinutes = (hour % 24) * 60 + minute;
    return (totalMinutes / (24 * 60)) * 360;
  }

  void _notifyTimeSlotsChanged() {
    if (widget.onTimeSlotsChanged != null) {
      final routineTimeSlots = timeSlots.map(_timeSlotToRoutineTimeSlot).toList();
      widget.onTimeSlotsChanged!(routineTimeSlots);
    }
  }
}

class ClockPainter extends CustomPainter {
  final int? startHour;
  final int? endHour;
  final double highlightAnimation;
  final double pulseAnimation;
  final Color selectionColor;

  const ClockPainter({
    this.startHour,
    this.endHour,
    required this.highlightAnimation,
    required this.pulseAnimation,
    required this.selectionColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 10;
    final innerRadius = outerRadius - 40;

    // Draw time selection overlay if active and visible
    if (startHour != null && endHour != null && highlightAnimation > 0) {
      _drawSelection(canvas, center, outerRadius, innerRadius);
    }

    // Draw center dot for reference
    final centerDotPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 3, centerDotPaint);
  }

  void _drawSelection(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
  ) {
    if (startHour == null || endHour == null) return;

    // Convert hours to angles: 0h at top, clockwise
    final startAngle = (startHour! * 15 - 90) * math.pi / 180;
    final endAngle = (endHour! * 15 - 90) * math.pi / 180;

    double sweepAngle = endAngle - startAngle;
    if (sweepAngle <= 0) sweepAngle += 2 * math.pi;

    final selectionPaint = Paint()
      ..color = selectionColor.withValues(
        alpha: 0.3 * highlightAnimation * (0.7 + 0.3 * pulseAnimation),
      )
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = selectionColor.withValues(alpha: 0.8 * highlightAnimation)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final selectionRect = Rect.fromCircle(
      center: center,
      radius: (outerRadius + innerRadius) / 2,
    );

    canvas.drawArc(selectionRect, startAngle, sweepAngle, true, selectionPaint);
    canvas.drawArc(selectionRect, startAngle, sweepAngle, false, strokePaint);

    final boundaryPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.9 * highlightAnimation)
      ..strokeWidth = 2;

    final startLineEnd = Offset(
      center.dx + outerRadius * math.cos(startAngle),
      center.dy + outerRadius * math.sin(startAngle),
    );
    canvas.drawLine(center, startLineEnd, boundaryPaint);

    final endLineEnd = Offset(
      center.dx + outerRadius * math.cos(endAngle),
      center.dy + outerRadius * math.sin(endAngle),
    );
    canvas.drawLine(center, endLineEnd, boundaryPaint);

    // Draw time labels next to the selection
    _drawTimeLabels(canvas, center, outerRadius, startAngle, endAngle);
  }

  void _drawTimeLabels(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double startAngle,
    double endAngle,
  ) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Draw start time label - closer to circle for mobile
    final startLabelRadius = outerRadius + 10;
    final startLabelX = center.dx + startLabelRadius * math.cos(startAngle);
    final startLabelY = center.dy + startLabelRadius * math.sin(startAngle);

    textPainter.text = TextSpan(
      text: '${startHour!}:00',
      style: const TextStyle(
        color: Colors.blue,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.white,
      ),
    );

    textPainter.layout();

    // Draw background for start label
    final startBgRect = Rect.fromCenter(
      center: Offset(startLabelX, startLabelY),
      width: textPainter.width + 8,
      height: textPainter.height + 4,
    );

    final labelBgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(startBgRect, const Radius.circular(4)),
      labelBgPaint,
    );

    textPainter.paint(
      canvas,
      Offset(
        startLabelX - textPainter.width / 2,
        startLabelY - textPainter.height / 2,
      ),
    );

    // Draw end time label (only if different from start)
    if (startHour != endHour) {
      final endLabelRadius = outerRadius + 10;
      final endLabelX = center.dx + endLabelRadius * math.cos(endAngle);
      final endLabelY = center.dy + endLabelRadius * math.sin(endAngle);

      textPainter.text = TextSpan(
        text: '${endHour!}:00',
        style: TextStyle(
          color: selectionColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white,
        ),
      );

      textPainter.layout();

      // Draw background for end label
      final endBgRect = Rect.fromCenter(
        center: Offset(endLabelX, endLabelY),
        width: textPainter.width + 8,
        height: textPainter.height + 4,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(endBgRect, const Radius.circular(4)),
        labelBgPaint,
      );

      textPainter.paint(
        canvas,
        Offset(
          endLabelX - textPainter.width / 2,
          endLabelY - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TimeSlotsPainter extends CustomPainter {
  final List<TimeSlot> timeSlots;

  const TimeSlotsPainter({required this.timeSlots});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 10;
    final innerRadius = outerRadius - 40;

    for (final slot in timeSlots) {
      _drawTimeSlot(canvas, center, outerRadius, innerRadius, slot);
    }
  }

  void _drawTimeSlot(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
    TimeSlot slot,
  ) {
    // Convert hours and minutes to angles: 0h at top, clockwise
    // Each hour = 15 degrees, each minute = 0.25 degrees (15/60)
    final startAngle =
        ((slot.startHour * 15) + (slot.startMinute * 0.25) - 90) *
        math.pi /
        180;
    final endAngle =
        ((slot.endHour * 15) + (slot.endMinute * 0.25) - 90) * math.pi / 180;

    double sweepAngle = endAngle - startAngle;
    if (sweepAngle <= 0) sweepAngle += 2 * math.pi;

    final slotPaint = Paint()
      ..color = slot.color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = slot.color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final slotRect = Rect.fromCircle(
      center: center,
      radius: (outerRadius + innerRadius) / 2,
    );

    canvas.drawArc(slotRect, startAngle, sweepAngle, true, slotPaint);
    canvas.drawArc(slotRect, startAngle, sweepAngle, false, strokePaint);

    // Draw boundary lines
    final boundaryPaint = Paint()
      ..color = slot.color.withValues(alpha: 0.9)
      ..strokeWidth = 2;

    final startLineEnd = Offset(
      center.dx + outerRadius * math.cos(startAngle),
      center.dy + outerRadius * math.sin(startAngle),
    );
    canvas.drawLine(center, startLineEnd, boundaryPaint);

    final endLineEnd = Offset(
      center.dx + outerRadius * math.cos(endAngle),
      center.dy + outerRadius * math.sin(endAngle),
    );
    canvas.drawLine(center, endLineEnd, boundaryPaint);

    // Draw time labels for this slot
    _drawTimeSlotLabels(
      canvas,
      center,
      outerRadius,
      startAngle,
      endAngle,
      slot,
    );
  }

  void _drawTimeSlotLabels(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double startAngle,
    double endAngle,
    TimeSlot slot,
  ) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Calculate label positions - place them closer to circle edge for mobile
    final labelRadius = outerRadius + 20;

    // Start time label
    final startLabelX = center.dx + labelRadius * math.cos(startAngle);
    final startLabelY = center.dy + labelRadius * math.sin(startAngle);

    textPainter.text = TextSpan(
      text: _formatTimeForCircle(slot.startHour, slot.startMinute),
      style: TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            blurRadius: 2,
            color: Colors.black.withValues(alpha: 0.8),
            offset: const Offset(0.5, 0.5),
          ),
        ],
      ),
    );

    textPainter.layout();

    // Draw background for start label
    final startBgRect = Rect.fromCenter(
      center: Offset(startLabelX, startLabelY),
      width: textPainter.width + 8,
      height: textPainter.height + 6,
    );

    final labelBgPaint = Paint()
      ..color = slot.color.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    final labelBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(
      RRect.fromRectAndRadius(startBgRect, const Radius.circular(2)),
      labelBgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(startBgRect, const Radius.circular(2)),
      labelBorderPaint,
    );

    textPainter.paint(
      canvas,
      Offset(
        startLabelX - textPainter.width / 2,
        startLabelY - textPainter.height / 2,
      ),
    );

    // End time label (only if different from start or duration > 15 minutes)
    final durationMinutes = _calculateMinutesBetween(
      slot.startHour,
      slot.startMinute,
      slot.endHour,
      slot.endMinute,
    );

    if (durationMinutes > 15) {
      final endLabelX = center.dx + labelRadius * math.cos(endAngle);
      final endLabelY = center.dy + labelRadius * math.sin(endAngle);

      textPainter.text = TextSpan(
        text: _formatTimeForCircle(slot.endHour, slot.endMinute),
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 2,
              color: Colors.black.withValues(alpha: 0.8),
              offset: const Offset(0.5, 0.5),
            ),
          ],
        ),
      );

      textPainter.layout();

      // Draw background for end label
      final endBgRect = Rect.fromCenter(
        center: Offset(endLabelX, endLabelY),
        width: textPainter.width + 8,
        height: textPainter.height + 6,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(endBgRect, const Radius.circular(2)),
        labelBgPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(endBgRect, const Radius.circular(2)),
        labelBorderPaint,
      );

      textPainter.paint(
        canvas,
        Offset(
          endLabelX - textPainter.width / 2,
          endLabelY - textPainter.height / 2,
        ),
      );
    }
  }

  String _formatTimeForCircle(int hour, int minute) {
    String period = hour < 12 ? 'AM' : 'PM';
    int displayHour = hour;
    if (hour == 0) {
      displayHour = 12;
    } else if (hour > 12) {
      displayHour = hour - 12;
    }

    if (minute == 0) {
      return '$displayHour$period';
    }
    return '$displayHour:${minute.toString().padLeft(2, '0')}$period';
  }

  int _calculateMinutesBetween(
    int startHour,
    int startMinute,
    int endHour,
    int endMinute,
  ) {
    int startMinutes = startHour * 60 + startMinute;
    int endMinutes = endHour * 60 + endMinute;

    if (endMinutes <= startMinutes) {
      endMinutes += 24 * 60; // Add 24 hours
    }

    return endMinutes - startMinutes;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SparkParticle {
  final Offset startPosition;
  final double angle;
  final Color color;

  SparkParticle({
    required this.startPosition,
    required this.angle,
    required this.color,
  });
}

class SparkPainter extends CustomPainter {
  final List<SparkParticle> sparks;
  final double progress;

  SparkPainter({required this.sparks, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || sparks.isEmpty) return;

    for (final spark in sparks) {
      final paint = Paint()
        ..color = spark.color.withValues(alpha: (1 - progress) * 0.8)
        ..style = PaintingStyle.fill;

      // Calculate spark position based on progress
      final distance = progress * 60; // Max distance of 60 pixels
      final x = spark.startPosition.dx + math.cos(spark.angle) * distance;
      final y = spark.startPosition.dy + math.sin(spark.angle) * distance;

      // Draw spark as small circle that gets smaller over time
      final radius = (1 - progress) * 4 + 1; // Start at 5, end at 1
      canvas.drawCircle(Offset(x, y), radius, paint);

      // Add sparkle trail effect
      for (int i = 1; i <= 3; i++) {
        final trailProgress = (progress - i * 0.1).clamp(0.0, 1.0);
        if (trailProgress > 0) {
          final trailDistance = trailProgress * 60 * 0.7;
          final trailX =
              spark.startPosition.dx + math.cos(spark.angle) * trailDistance;
          final trailY =
              spark.startPosition.dy + math.sin(spark.angle) * trailDistance;
          final trailPaint = Paint()
            ..color = spark.color.withValues(alpha: (1 - trailProgress) * 0.4)
            ..style = PaintingStyle.fill;
          final trailRadius = (1 - trailProgress) * 2;
          canvas.drawCircle(Offset(trailX, trailY), trailRadius, trailPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
