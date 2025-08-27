import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:rive/rive.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class TimeSlot {
  final String id;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final String title;
  final Color color;
  final bool notificationEnabled;

  TimeSlot({
    required this.id,
    required this.startHour,
    this.startMinute = 0,
    required this.endHour,
    this.endMinute = 0,
    required this.title,
    required this.color,
    this.notificationEnabled = true,
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
  const SelectableClockWidget({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  State<SelectableClockWidget> createState() => _SelectableClockWidgetState();
}

class _SelectableClockWidgetState extends State<SelectableClockWidget>
    with TickerProviderStateMixin {
  int? startHour;
  int? endHour;
  List<TimeSlot> timeSlots = [];
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;
  late AnimationController _pulseController;
  late AnimationController _sparkController;
  late Animation<double> _sparkAnimation;
  final List<SparkParticle> _sparks = [];

  // Notification settings
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool globalNotificationsEnabled = true;

  // Removed hover functionality as it doesn't work on mobile

  @override
  void initState() {
    super.initState();

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

    _initializeNotifications();
  }

  Widget _buildBackgroundAnimation() {
    // Always show the appropriate background circle
    return RiveAnimation.asset(
      widget.isDarkMode
          ? 'assets/animations/circle_board.riv'
          : 'assets/animations/circle light.riv',
      fit: BoxFit.contain,
      key: ValueKey(widget.isDarkMode ? 'dark_bg' : 'light_bg'),
    );
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _scheduleNotification(TimeSlot slot) async {
    if (!globalNotificationsEnabled || !slot.notificationEnabled) return;

    // Schedule daily notification for this time slot
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      slot.startHour,
      slot.startMinute,
    );

    // If the time has passed today, schedule for tomorrow
    final notificationTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    const androidDetails = AndroidNotificationDetails(
      'routine_notifications',
      'Routine Notifications',
      channelDescription: 'Notifications for your scheduled time slots',
      importance: Importance.max,
      priority: Priority.high,
    );

    const platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      slot.id.hashCode,
      'Time for: ${slot.title}',
      '${_formatTimeWithMinutes(slot.startHour, slot.startMinute)} - ${_formatTimeWithMinutes(slot.endHour, slot.endMinute)}',
      tz.TZDateTime.from(notificationTime, tz.local),
      platformChannelSpecifics,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _cancelNotification(String slotId) async {
    await flutterLocalNotificationsPlugin.cancel(slotId.hashCode);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Clock Circle
        Center(
          child: GestureDetector(
            onTapDown: _handleTap,
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: SizedBox(
              width: 360, // Increased from 320 to 360 (12.5% bigger)
              height: 360, // Increased from 320 to 360 (12.5% bigger)
              child: Stack(
                children: [
                  // Background circle animation (always show)
                  _buildBackgroundAnimation(),
                  // Overlay for existing time slots
                  CustomPaint(
                    painter: TimeSlotsPainter(timeSlots: timeSlots),
                    size: const Size(
                      360,
                      360,
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
                          360,
                          360,
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
                        size: const Size(360, 360),
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
                'Your Time Slots',
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
                  onPressed: () => _showCreateTimeSlotModal(),
                  icon: Icon(
                    Icons.add,
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
                'No time slots yet. Tap + to create one or drag on the circle!',
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
      ],
    );
  }

  // Hover functionality removed - not needed for mobile touch interface

  void _handleTap(TapDownDetails details) {
    const center = Offset(180, 180); // Updated center point (half of 360)
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
    Color selectedColor = existingSlot?.color ?? availableColors[0];
    bool notificationEnabled =
        existingSlot?.notificationEnabled ?? globalNotificationsEnabled;

    // Initialize time values with proper null handling
    int selectedStartHour = existingSlot?.startHour ?? (startHour ?? 0);
    int selectedStartMinute = existingSlot?.startMinute ?? 0;
    int selectedEndHour =
        existingSlot?.endHour ?? (endHour ?? (selectedStartHour + 1) % 24);
    int selectedEndMinute = existingSlot?.endMinute ?? 0;

    // Ensure minute values are valid (0, 15, 30, or 45)
    final validMinutes = [0, 15, 30, 45];
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
                existingSlot != null ? 'Edit Time Slot' : 'Create Time Slot',
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
                      'Title of this time',
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
                        hintText: 'e.g., Work, Exercise, Sleep...',
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
                      'Adjust time:',
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
                          'From: ',
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
                                        '${index.toString().padLeft(2, '0')}h',
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
                                  items: [0, 15, 30, 45]
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
                          'To: ',
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
                                        '${index.toString().padLeft(2, '0')}h',
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
                                  items: [0, 15, 30, 45]
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
                      'Choose a color:',
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
                            'Enable notifications',
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
                      color: selectedColor,
                      notificationEnabled: notificationEnabled,
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

                    // Schedule notification if enabled
                    _scheduleNotification(newSlot);

                    Navigator.of(context).pop();
                    _clearSelection();
                    setState(() {});
                  },
                  child: Text(existingSlot != null ? 'Update' : 'Create'),
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
                            color: slot.color,
                            notificationEnabled: !slot.notificationEnabled,
                          );
                          timeSlots[index] = updatedSlot;

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
      180,
      180,
    ); // Updated center point (half of 360) // Half of the size
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
    const center = Offset(180, 180); // Updated center point (half of 360)
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
    const center = Offset(180, 180);
    const radius = 140;

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

  @override
  void dispose() {
    _highlightController.dispose();
    _pulseController.dispose();
    _sparkController.dispose();
    super.dispose();
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
