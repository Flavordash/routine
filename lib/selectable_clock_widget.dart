import 'package:flutter/material.dart';
import 'dart:math' as math;
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
  final bool smartIntervalsEnabled;
  final int smartIntervalMinutes;
  final bool silentIntervals;
  final bool showProgressMessages;

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
    this.smartIntervalsEnabled = false,
    this.smartIntervalMinutes = 0,
    this.silentIntervals = false,
    this.showProgressMessages = true,
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
    this.onShowTemplateGallery,
  });

  final bool isDarkMode;
  final VoidCallback? onBackgroundTap;
  final bool isProUser;
  final List<RoutineTimeSlot> timeSlots;
  final Function(List<RoutineTimeSlot>)? onTimeSlotsChanged;
  final VoidCallback? onShowTemplateGallery;

  @override
  State<SelectableClockWidget> createState() => _SelectableClockWidgetState();
}

class _SelectableClockWidgetState extends State<SelectableClockWidget>
    with TickerProviderStateMixin {
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

  // Dynamic clock size for responsive design
  double _currentClockSize = 300.0;

  // Purchase service
  late PurchaseService _purchaseService;

  // Note: Notification management is now handled by NotificationService in main app

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

  // Note: Notification initialization is now handled by NotificationService in main app

  // Test vibration method
  Future<void> _testVibration() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      // Custom vibration pattern: [wait, vibrate, wait, vibrate]
      Vibration.vibrate(pattern: [0, 1000, 500, 1000]);
    }
  }

  // Note: Notification scheduling is now handled by NotificationService in main app
  // These methods have been removed to prevent duplicate notification scheduling

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;

          // Calculate responsive sizes
          final clockSize = (screenWidth * 0.8).clamp(
            250.0,
            screenHeight * 0.4,
          );
          _currentClockSize = clockSize;

          return Column(
            children: [
              // Top spacing - 3% of screen height
              SizedBox(height: screenHeight * 0.02),

              // Circular clock area - 42% of screen height
              Expanded(
                flex: 8,
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: _handleTap,
                    onPanStart: _handlePanStart,
                    onPanUpdate: _handlePanUpdate,
                    onPanEnd: _handlePanEnd,
                    child: SizedBox(
                      width: clockSize,
                      height: clockSize,
                      child: Stack(
                        children: [
                          // Background circle animation (always show)
                          _buildBackgroundAnimation(),
                          // Overlay for existing time slots
                          CustomPaint(
                            painter: TimeSlotsPainter(timeSlots: timeSlots),
                            size: Size(clockSize, clockSize),
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
                                  selectionColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                ),
                                size: Size(clockSize, clockSize),
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
                                size: Size(clockSize, clockSize),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Time slots section - 25% of screen height
              SizedBox(
                height: 170,
                child: Column(
                  children: [
                      // Header row with title and add button
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                AppLocalizations.of(context)!.yourTimeSlots,
                                style: TextStyle(
                                  fontSize: (screenWidth * 0.045).clamp(
                                    16.0,
                                    20.0,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            // Clear All button (only show when there are time slots)
                            if (timeSlots.isNotEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      setState(() {
                                        timeSlots.clear();
                                        _notifyTimeSlotsChanged();
                                      });
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: (screenWidth * 0.025).clamp(10.0, 16.0),
                                        vertical: (screenHeight * 0.008).clamp(6.0, 10.0),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.clear_all,
                                            size: (screenWidth * 0.035).clamp(14.0, 16.0),
                                            color: Theme.of(context).colorScheme.error,
                                          ),
                                          SizedBox(width: (screenWidth * 0.01).clamp(4.0, 6.0)),
                                          Text(
                                            'Clear All',
                                            style: TextStyle(
                                              fontSize: (screenWidth * 0.030).clamp(11.0, 13.0),
                                              color: Theme.of(context).colorScheme.error,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            // Responsive add button
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(18),
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  size: (screenWidth * 0.05).clamp(18.0, 22.0),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: (screenWidth * 0.08).clamp(
                                    32.0,
                                    40.0,
                                  ),
                                  minHeight: (screenWidth * 0.08).clamp(
                                    32.0,
                                    40.0,
                                  ),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Flexible spacing
                      SizedBox(height: screenHeight * 0.006),

                      // Time slots list - takes remaining space in this section
                      Expanded(
                        child: timeSlots.isNotEmpty
                            ? ListView.builder(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                ),
                                scrollDirection: Axis.horizontal,
                                itemCount: timeSlots.length,
                                itemBuilder: (context, index) {
                                  return _buildTimeSlotCard(
                                    timeSlots[index],
                                    screenWidth,
                                  );
                                },
                              )
                            : Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.1,
                                  ),
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.noTimeSlotsYet,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                      fontSize: (screenWidth * 0.035).clamp(
                                        12.0,
                                        16.0,
                                      ),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 20),
              // PRO banner section - 15% of screen height
              SizedBox(
                height: 111, // ← ADJUST THIS NUMBER (pixels)
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: _buildResponsiveBanner(screenWidth, screenHeight),
                ),
              ),

              // Bottom spacing - 3% of screen height
              SizedBox(height: screenHeight * 0.06),
            ],
          );
        },
      ),
    );
  }

  // Hover functionality removed - not needed for mobile touch interface

  void _handleTap(TapDownDetails details) {
    final center = Offset(_currentClockSize / 2, _currentClockSize / 2);
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

  void _fillFreeTime() {
    // Immediately use current widget data without waiting
    _performFillFreeTime();
  }


  // Get current fill button state information
  Map<String, dynamic> _getFillButtonState() {
    final widgetTimeSlots = widget.timeSlots.map(_routineTimeSlotToTimeSlot).toList();
    final currentTimeSlots = widgetTimeSlots.where((slot) => slot.title != 'Free Time').toList();
    final gaps = _findGaps(currentTimeSlots);

    if (gaps.isEmpty) {
      return {
        'hasGaps': false,
        'buttonText': 'Schedule Full',
        'canFill': false,
        'gapCount': 0,
        'totalGapHours': 0,
      };
    }

    final totalGapMinutes = gaps.fold<int>(0, (sum, gap) => sum + (gap['end']! - gap['start']!));
    final totalGapHours = (totalGapMinutes / 60).round();

    return {
      'hasGaps': true,
      'buttonText': 'Fill Free Time',
      'canFill': true,
      'gapCount': gaps.length,
      'totalGapHours': totalGapHours,
    };
  }

  // Find all gaps in the current schedule
  List<Map<String, int>> _findGaps(List<TimeSlot> slots) {
    if (slots.isEmpty) {
      // If no slots, the entire day is a gap
      return [{'start': 0, 'end': 24 * 60}];
    }

    // Convert all slots to minute ranges and sort them
    List<Map<String, int>> ranges = [];

    for (var slot in slots) {
      if (slot.title == 'Free Time') continue; // Skip existing free time slots

      final startMinutes = slot.startHour * 60 + slot.startMinute;
      final endMinutes = slot.endHour * 60 + slot.endMinute;

      if (endMinutes <= startMinutes) {
        // Overnight slot - split into two ranges
        ranges.add({'start': startMinutes, 'end': 24 * 60}); // Evening part
        ranges.add({'start': 0, 'end': endMinutes}); // Morning part
      } else {
        // Regular slot
        ranges.add({'start': startMinutes, 'end': endMinutes});
      }
    }

    if (ranges.isEmpty) {
      return [{'start': 0, 'end': 24 * 60}];
    }

    // Sort ranges by start time
    ranges.sort((a, b) => a['start']!.compareTo(b['start']!));

    // Merge overlapping and adjacent ranges
    List<Map<String, int>> merged = [];
    for (var range in ranges) {
      if (merged.isEmpty || merged.last['end']! < range['start']!) {
        merged.add(range);
      } else {
        merged.last['end'] = math.max(merged.last['end']!, range['end']!);
      }
    }

    // Find gaps between merged ranges
    List<Map<String, int>> gaps = [];

    // Gap at the beginning of the day
    if (merged.first['start']! > 0) {
      gaps.add({'start': 0, 'end': merged.first['start']!});
    }

    // Gaps between ranges
    for (int i = 0; i < merged.length - 1; i++) {
      final currentEnd = merged[i]['end']!;
      final nextStart = merged[i + 1]['start']!;
      if (nextStart > currentEnd) {
        gaps.add({'start': currentEnd, 'end': nextStart});
      }
    }

    // Gap at the end of the day
    if (merged.last['end']! < 24 * 60) {
      gaps.add({'start': merged.last['end']!, 'end': 24 * 60});
    }

    return gaps;
  }

  void _performFillFreeTime() {
    // Always use widget data as the source of truth for the most current state
    final widgetTimeSlots = widget.timeSlots.map(_routineTimeSlotToTimeSlot).toList();

    // Remove any existing "Free Time" slots to get clean user data
    final currentTimeSlots = widgetTimeSlots.where((slot) => slot.title != 'Free Time').toList();

    // Find all gaps in the current schedule
    final gaps = _findGaps(currentTimeSlots);

    if (gaps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noFreeTimeGaps),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    List<TimeSlot> newFreeTimeSlots = [];

    // Create free time slots for each gap
    for (int i = 0; i < gaps.length; i++) {
      final gap = gaps[i];
      final startMinutes = gap['start']!;
      final endMinutes = gap['end']!;

      final startHour = startMinutes ~/ 60;
      final startMinute = startMinutes % 60;
      final endHour = (endMinutes - 1) ~/ 60; // -1 to handle 24:00 -> 23:59
      final endMinute = (endMinutes - 1) % 60;

      final freeSlot = TimeSlot(
        id: (DateTime.now().millisecondsSinceEpoch + i).toString(),
        startHour: startHour,
        startMinute: startMinute,
        endHour: endHour,
        endMinute: endMinute,
        title: 'Free Time',
        description: 'Available free time',
        color: const Color(0xFF9E9E9E),
        notificationEnabled: false,
        hasAlarm: false,
        hasPreAlarm: false,
        preAlarmMinutes: 15,
        smartIntervalsEnabled: false,
        smartIntervalMinutes: 0,
        silentIntervals: false,
        showProgressMessages: true,
      );
      newFreeTimeSlots.add(freeSlot);
    }

    final updatedSlots = List<TimeSlot>.from(currentTimeSlots)..addAll(newFreeTimeSlots);
    final routineTimeSlots = updatedSlots.map((slot) => _timeSlotToRoutineTimeSlot(slot)).toList();
    widget.onTimeSlotsChanged?.call(routineTimeSlots);

    // Update internal state to match
    setState(() {
      timeSlots = updatedSlots;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${newFreeTimeSlots.length} Free Time slot${newFreeTimeSlots.length > 1 ? 's' : ''}!',
        ),
        backgroundColor: Colors.green,
      ),
    );
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
        existingSlot?.notificationEnabled ?? true; // Default to enabled

    // Pro alarm settings
    bool hasAlarm = existingSlot?.hasAlarm ?? widget.isProUser;
    bool hasPreAlarm = existingSlot?.hasPreAlarm ?? false;
    int preAlarmMinutes = existingSlot?.preAlarmMinutes ?? 15;
    bool smartIntervalsEnabled = existingSlot?.smartIntervalsEnabled ?? false;
    int smartIntervalMinutes = existingSlot?.smartIntervalMinutes ?? 0;
    bool silentIntervals = existingSlot?.silentIntervals ?? false;
    bool showProgressMessages = existingSlot?.showProgressMessages ?? true;

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
      barrierColor: Colors.black54,
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
                existingSlot != null
                    ? AppLocalizations.of(context)!.editTimeSlot
                    : AppLocalizations.of(context)!.createTimeSlot,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
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
                          hintText: AppLocalizations.of(
                            context,
                          )!.descriptionHint,
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                    items:
                                        [
                                              0,
                                              5,
                                              10,
                                              15,
                                              20,
                                              25,
                                              30,
                                              35,
                                              40,
                                              45,
                                              50,
                                              55,
                                            ]
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                    items:
                                        [
                                              0,
                                              5,
                                              10,
                                              15,
                                              20,
                                              25,
                                              30,
                                              35,
                                              40,
                                              45,
                                              50,
                                              55,
                                            ]
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
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.preAlarm,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
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
                                            AppLocalizations.of(context)!.preAlarmTime,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ),
                                        DropdownButton<int>(
                                          value: preAlarmMinutes,
                                          underline: Container(),
                                          items: [5, 10, 15, 20, 30].map((
                                            minutes,
                                          ) {
                                            return DropdownMenuItem(
                                              value: minutes,
                                              child: Text(
                                                AppLocalizations.of(context)!.minutesShort(minutes),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
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

                                // Smart Intervals Settings
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.smartIntervals,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Switch(
                                      value: smartIntervalsEnabled,
                                      onChanged: (value) {
                                        setModalState(() {
                                          smartIntervalsEnabled = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),

                                if (smartIntervalsEnabled) ...[
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 26),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                AppLocalizations.of(context)!.intervalDuration,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                            DropdownButton<int>(
                                              value: smartIntervalMinutes,
                                              underline: Container(),
                                              items: [0, 5, 10, 15, 30].map((
                                                minutes,
                                              ) {
                                                return DropdownMenuItem(
                                                  value: minutes,
                                                  child: Text(
                                                    minutes == 0 ? 'None' : '$minutes min',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                setModalState(() {
                                                  smartIntervalMinutes = value!;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.vibration,
                                              color: Theme.of(context).colorScheme.onSurface,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                AppLocalizations.of(context)!.silentIntervals,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                            Switch(
                                              value: silentIntervals,
                                              onChanged: (value) {
                                                setModalState(() {
                                                  silentIntervals = value;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.message,
                                              color: Theme.of(context).colorScheme.onSurface,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                AppLocalizations.of(context)!.progressMessages,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                            Switch(
                                              value: showProgressMessages,
                                              onChanged: (value) {
                                                setModalState(() {
                                                  showProgressMessages = value;
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
                                      AppLocalizations.of(context)!.advancedAlarmPromoText,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
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
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
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
                ),
              ),
              actions: [
                if (existingSlot != null)
                  TextButton(
                    onPressed: () {
                      timeSlots.remove(existingSlot);
                      // Note: Notification cancellation is now handled by the main app
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
                      smartIntervalsEnabled: smartIntervalsEnabled,
                      smartIntervalMinutes: smartIntervalMinutes,
                      silentIntervals: silentIntervals,
                      showProgressMessages: showProgressMessages,
                    );

                    if (existingSlot != null) {
                      final index = timeSlots.indexWhere((slot) => slot.id == existingSlot.id);
                      if (index != -1) {
                        timeSlots[index] = newSlot;
                        // Note: Notification management is handled by main app
                      } else {
                        // If not found, treat as new slot
                        timeSlots.add(newSlot);
                        _triggerSparkAnimation(selectedColor);
                      }
                    } else {
                      timeSlots.add(newSlot);
                      // Trigger spark animation for new slots
                      _triggerSparkAnimation(selectedColor);
                    }
                    _notifyTimeSlotsChanged();

                    // Note: Notification scheduling is now handled by the main app
                    // through the NotificationService when time slots change

                    Navigator.of(context).pop();
                    _clearSelection();
                    setState(() {});
                  },
                  child: Text(
                    existingSlot != null
                        ? AppLocalizations.of(context)!.update
                        : AppLocalizations.of(context)!.create,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot, double screenWidth) {
    return Container(
      width: (screenWidth * 0.32).clamp(110.0, 140.0),
      height: (screenWidth * 0.25).clamp(85.0, 110.0),
      margin: EdgeInsets.only(right: (screenWidth * 0.02).clamp(5.0, 10.0)),
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
            padding: EdgeInsets.all((screenWidth * 0.015).clamp(4.0, 8.0)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                    SizedBox(width: (screenWidth * 0.015).clamp(4.0, 8.0)),
                    Expanded(
                      child: Text(
                        slot.title,
                        style: TextStyle(
                          fontSize: (screenWidth * 0.032).clamp(11.0, 14.0),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          final index = timeSlots.indexWhere((s) => s.id == slot.id);
                          if (index != -1) {
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

                            // Note: Notification scheduling is now handled by the main app
                            // through the NotificationService when time slots change
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
                SizedBox(height: (screenWidth * 0.015).clamp(4.0, 8.0)),
                // Description (if not empty)
                if (slot.description.isNotEmpty) ...[
                  Text(
                    slot.description,
                    style: TextStyle(
                      fontSize: (screenWidth * 0.028).clamp(10.0, 12.0),
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: (screenWidth * 0.008).clamp(2.0, 4.0)),
                ],
                Text(
                  '${_formatTimeWithMinutes(slot.startHour, slot.startMinute)} - ${_formatTimeWithMinutes(slot.endHour, slot.endMinute)}',
                  style: TextStyle(
                    fontSize: (screenWidth * 0.028).clamp(10.0, 12.0),
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '${_calculateDurationWithMinutes(slot.startHour, slot.startMinute, slot.endHour, slot.endMinute)} duration',
                  style: TextStyle(
                    fontSize: (screenWidth * 0.025).clamp(9.0, 11.0),
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
    final center = Offset(_currentClockSize / 2, _currentClockSize / 2);
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
      return '${hours}${AppLocalizations.of(context)!.hoursShort}';
    }
    return '${hours}${AppLocalizations.of(context)!.hoursShort} ${minutes}${AppLocalizations.of(context)!.minutesShortFormat}';
  }

  void _triggerSparkAnimation(Color color) {
    _sparks.clear();

    // Generate sparks around the circle
    final center = Offset(_currentClockSize / 2, _currentClockSize / 2);
    final radius = _currentClockSize * 0.4;

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
    // Directly show subscription dialog, removing the intermediate modal
    _showSubscriptionDialog();
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
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
              Icon(Icons.star, color: Colors.amber, size: 24),
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
                _buildProFeature(
                  Icons.block,
                  AppLocalizations.of(context)!.removeAllAds,
                ),
                _buildProFeature(
                  Icons.all_inclusive,
                  AppLocalizations.of(context)!.unlimitedSlots.substring(2),
                ),
                _buildProFeature(
                  Icons.cloud_download,
                  AppLocalizations.of(context)!.browseImportTemplates.substring(2),
                ),
                _buildProFeature(
                  Icons.share,
                  AppLocalizations.of(context)!.shareTemplates.substring(2),
                ),
                _buildProFeature(
                  Icons.alarm,
                  AppLocalizations.of(context)!.advancedAlarmFeatures.substring(2),
                ),
                _buildProFeature(
                  Icons.calendar_today,
                  AppLocalizations.of(context)!.scheduleSpecificDaysFull.substring(2),
                ),
                _buildProFeature(
                  Icons.backup,
                  AppLocalizations.of(context)!.cloudSyncBackupFull.substring(2),
                ),
                _buildProFeature(
                  Icons.support,
                  AppLocalizations.of(context)!.prioritySupport.substring(2),
                ),
                _buildProFeature(
                  Icons.tune,
                  AppLocalizations.of(context)!.advancedCustomization.substring(2),
                ),

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
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
          Icon(icon, size: 20, color: Colors.green),
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
      barrierColor: Colors.black54,
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
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
            content: Text(AppLocalizations.of(context)!.purchaseSuccessful),
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
            content: Text(AppLocalizations.of(context)!.purchaseFailed(error)),
            backgroundColor: Colors.red,
          ),
        );
      }
    };

    _purchaseService.onRestoreSuccess = () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.purchasesRestored),
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
            content: Text(AppLocalizations.of(context)!.restoreFailed(error)),
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

  Widget _buildResponsiveBanner(double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all((screenWidth * 0.03).clamp(8.0, 16.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isProUser
              ? [Colors.amber.shade300, Colors.amber.shade600]
              : [Colors.blue.shade300, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          (screenWidth * 0.03).clamp(8.0, 16.0),
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.isProUser ? Colors.amber : Colors.blue).withValues(
              alpha: 0.3,
            ),
            blurRadius: (screenWidth * 0.02).clamp(4.0, 12.0),
            offset: Offset(0, (screenWidth * 0.01).clamp(2.0, 6.0)),
          ),
        ],
      ),
      child: widget.isProUser
          ? _buildResponsiveProBanner(screenWidth, screenHeight)
          : _buildResponsiveAdBanner(screenWidth, screenHeight),
    );
  }

  Widget _buildResponsiveProBanner(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with star and PRO MEMBER text
        Row(
          children: [
            Container(
              padding: EdgeInsets.all((screenWidth * 0.015).clamp(4.0, 8.0)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(
                  (screenWidth * 0.02).clamp(6.0, 10.0),
                ),
              ),
              child: Icon(
                Icons.star,
                color: Colors.white,
                size: (screenWidth * 0.05).clamp(16.0, 22.0),
              ),
            ),
            SizedBox(width: (screenWidth * 0.02).clamp(6.0, 10.0)),
            Flexible(
              child: Text(
                AppLocalizations.of(context)!.proMember,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: (screenWidth * 0.038).clamp(13.0, 17.0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: (screenHeight * 0.003).clamp(2.0, 4.0)),
        // Buttons row
        Row(
          children: [
            // Fill the free time button (50% width)
            Expanded(
              child: Builder(
                builder: (context) {
                  final buttonState = _getFillButtonState();
                  final canFill = buttonState['canFill'] as bool;
                  final buttonText = buttonState['buttonText'] as String;
                  final hasGaps = buttonState['hasGaps'] as bool;

                  return ElevatedButton(
                    onPressed: canFill ? () {
                      _fillFreeTime();
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canFill ? Colors.white : Colors.grey[300],
                      foregroundColor: canFill ? Colors.amber[700] : Colors.grey[600],
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[600],
                      padding: EdgeInsets.symmetric(
                        horizontal: (screenWidth * 0.015).clamp(4.0, 8.0),
                        vertical: (screenHeight * 0.004).clamp(3.0, 6.0),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          (screenWidth * 0.02).clamp(6.0, 10.0),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasGaps ? Icons.auto_fix_high : Icons.check_circle,
                          size: (screenWidth * 0.03).clamp(10.0, 16.0),
                        ),
                        SizedBox(width: (screenWidth * 0.01).clamp(2.0, 6.0)),
                        Flexible(
                          child: Text(
                            buttonText,
                            style: TextStyle(
                              fontSize: (screenWidth * 0.025).clamp(9.0, 12.0),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              ),
            ),
            SizedBox(width: (screenWidth * 0.015).clamp(4.0, 8.0)),
            // Browse Templates button (50% width)
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onShowTemplateGallery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.amber[700],
                  padding: EdgeInsets.symmetric(
                    horizontal: (screenWidth * 0.015).clamp(4.0, 8.0),
                    vertical: (screenHeight * 0.004).clamp(3.0, 6.0),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      (screenWidth * 0.02).clamp(6.0, 10.0),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.library_books,
                      size: (screenWidth * 0.03).clamp(10.0, 16.0),
                    ),
                    SizedBox(width: (screenWidth * 0.01).clamp(2.0, 6.0)),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context)!.browseTemplates,
                        style: TextStyle(
                          fontSize: (screenWidth * 0.025).clamp(9.0, 12.0),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResponsiveAdBanner(double screenWidth, double screenHeight) {
    // Initialize banner ad if not already done
    if (AdService.instance.bannerAd == null) {
      AdService.instance.createBannerAd();
    }

    return Column(
      children: [
        // Real AdMob Banner Ad - responsive sizing
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(
                (screenWidth * 0.02).clamp(6.0, 12.0),
              ),
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
                          size: (screenWidth * 0.045).clamp(16.0, 24.0),
                        ),
                        SizedBox(
                          height: (screenHeight * 0.003).clamp(2.0, 4.0),
                        ),
                        Text(
                          'Loading Ad...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: (screenWidth * 0.025).clamp(9.0, 12.0),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        SizedBox(height: (screenHeight * 0.008).clamp(4.0, 10.0)),
        // Upgrade message - responsive text
        Flexible(
          child: Text(
            AppLocalizations.of(context)!.upgradeToProAd,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: (screenWidth * 0.028).clamp(9.0, 13.0),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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
      notificationEnabled: routineTimeSlot.hasAlarm, // Map hasAlarm to notificationEnabled
      hasAlarm: routineTimeSlot.hasAlarm,
      hasPreAlarm: routineTimeSlot.hasPreAlarm,
      preAlarmMinutes: routineTimeSlot.preAlarmMinutes,
      smartIntervalsEnabled: routineTimeSlot.smartIntervalsEnabled,
      smartIntervalMinutes: routineTimeSlot.smartIntervalMinutes,
      silentIntervals: routineTimeSlot.silentIntervals,
      showProgressMessages: routineTimeSlot.showProgressMessages,
    );
  }

  RoutineTimeSlot _timeSlotToRoutineTimeSlot(TimeSlot timeSlot) {
    return RoutineTimeSlot(
      id: timeSlot.id,
      startAngle: _hourToAngle(timeSlot.startHour, timeSlot.startMinute),
      endAngle: _hourToAngle(timeSlot.endHour, timeSlot.endMinute),
      startTime:
          '${timeSlot.startHour.toString().padLeft(2, '0')}:${timeSlot.startMinute.toString().padLeft(2, '0')}',
      endTime:
          '${timeSlot.endHour.toString().padLeft(2, '0')}:${timeSlot.endMinute.toString().padLeft(2, '0')}',
      label: timeSlot.title,
      description: timeSlot.description,
      color: timeSlot.color.toARGB32(),
      hasAlarm: timeSlot.notificationEnabled, // Map notificationEnabled to hasAlarm
      hasPreAlarm: timeSlot.hasPreAlarm,
      preAlarmMinutes: timeSlot.preAlarmMinutes,
      smartIntervalsEnabled: timeSlot.smartIntervalsEnabled,
      smartIntervalMinutes: timeSlot.smartIntervalMinutes,
      silentIntervals: timeSlot.silentIntervals,
      showProgressMessages: timeSlot.showProgressMessages,
      createdAt: DateTime.now(),
    );
  }

  double _hourToAngle(int hour, int minute) {
    final totalMinutes = (hour % 24) * 60 + minute;
    return (totalMinutes / (24 * 60)) * 360;
  }

  void _notifyTimeSlotsChanged() {
    if (widget.onTimeSlotsChanged != null) {
      final routineTimeSlots = timeSlots
          .map(_timeSlotToRoutineTimeSlot)
          .toList();
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
