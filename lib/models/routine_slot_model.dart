class RoutineSlot {
  final String id;
  final String name;
  final bool isActive;
  final bool isPaid;
  final List<RoutineTimeSlot> timeSlots;
  final List<int> selectedDays; // 1=Monday, 2=Tuesday, ..., 7=Sunday
  final int? color; // Color value for the circle indicator
  final DateTime? createdAt;
  final DateTime? lastModified;

  RoutineSlot({
    required this.id,
    required this.name,
    required this.isActive,
    required this.isPaid,
    this.timeSlots = const [],
    this.selectedDays = const [1, 2, 3, 4, 5, 6, 7], // Default: all days
    this.color,
    this.createdAt,
    this.lastModified,
  });

  RoutineSlot copyWith({
    String? id,
    String? name,
    bool? isActive,
    bool? isPaid,
    List<RoutineTimeSlot>? timeSlots,
    List<int>? selectedDays,
    int? color,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return RoutineSlot(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      isPaid: isPaid ?? this.isPaid,
      timeSlots: timeSlots ?? this.timeSlots,
      selectedDays: selectedDays ?? this.selectedDays,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
      'isPaid': isPaid,
      'timeSlots': timeSlots.map((slot) => slot.toJson()).toList(),
      'selectedDays': selectedDays,
      'color': color,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'lastModified': lastModified?.millisecondsSinceEpoch,
    };
  }

  factory RoutineSlot.fromJson(Map<String, dynamic> json) {
    return RoutineSlot(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      isActive: json['isActive'] ?? false,
      isPaid: json['isPaid'] ?? false,
      timeSlots: (json['timeSlots'] as List<dynamic>?)
              ?.map((item) => RoutineTimeSlot.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      selectedDays: (json['selectedDays'] as List<dynamic>?)?.cast<int>() ?? 
          [1, 2, 3, 4, 5, 6, 7], // Default: all days
      color: json['color'],
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : null,
      lastModified: json['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastModified'])
          : null,
    );
  }
}

class RoutineTimeSlot {
  final String id;
  final double startAngle;
  final double endAngle;
  final String startTime;
  final String endTime;
  final String? label;
  final String? description;
  final int? color;
  final bool hasAlarm;
  final bool hasPreAlarm;
  final int preAlarmMinutes; // Minutes before main alarm
  final bool smartIntervalsEnabled;
  final int smartIntervalMinutes; // Interval duration in minutes (0=None, 5, 10, 15, 30)
  final bool silentIntervals; // Vibration only
  final bool showProgressMessages; // Show progress in notifications
  final DateTime? createdAt;

  RoutineTimeSlot({
    required this.id,
    required this.startAngle,
    required this.endAngle,
    required this.startTime,
    required this.endTime,
    this.label,
    this.description,
    this.color,
    this.hasAlarm = false,
    this.hasPreAlarm = false,
    this.preAlarmMinutes = 15,
    this.smartIntervalsEnabled = false,
    this.smartIntervalMinutes = 0, // 0 = None (default)
    this.silentIntervals = false,
    this.showProgressMessages = true,
    this.createdAt,
  });

  RoutineTimeSlot copyWith({
    String? id,
    double? startAngle,
    double? endAngle,
    String? startTime,
    String? endTime,
    String? label,
    String? description,
    int? color,
    bool? hasAlarm,
    bool? hasPreAlarm,
    int? preAlarmMinutes,
    bool? smartIntervalsEnabled,
    int? smartIntervalMinutes,
    bool? silentIntervals,
    bool? showProgressMessages,
    DateTime? createdAt,
  }) {
    return RoutineTimeSlot(
      id: id ?? this.id,
      startAngle: startAngle ?? this.startAngle,
      endAngle: endAngle ?? this.endAngle,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      label: label ?? this.label,
      description: description ?? this.description,
      color: color ?? this.color,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      hasPreAlarm: hasPreAlarm ?? this.hasPreAlarm,
      preAlarmMinutes: preAlarmMinutes ?? this.preAlarmMinutes,
      smartIntervalsEnabled: smartIntervalsEnabled ?? this.smartIntervalsEnabled,
      smartIntervalMinutes: smartIntervalMinutes ?? this.smartIntervalMinutes,
      silentIntervals: silentIntervals ?? this.silentIntervals,
      showProgressMessages: showProgressMessages ?? this.showProgressMessages,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startAngle': startAngle,
      'endAngle': endAngle,
      'startTime': startTime,
      'endTime': endTime,
      'label': label,
      'description': description,
      'color': color,
      'hasAlarm': hasAlarm,
      'hasPreAlarm': hasPreAlarm,
      'preAlarmMinutes': preAlarmMinutes,
      'smartIntervalsEnabled': smartIntervalsEnabled,
      'smartIntervalMinutes': smartIntervalMinutes,
      'silentIntervals': silentIntervals,
      'showProgressMessages': showProgressMessages,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory RoutineTimeSlot.fromJson(Map<String, dynamic> json) {
    return RoutineTimeSlot(
      id: json['id'] ?? '',
      startAngle: (json['startAngle'] as num?)?.toDouble() ?? 0.0,
      endAngle: (json['endAngle'] as num?)?.toDouble() ?? 0.0,
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      label: json['label'],
      description: json['description'],
      color: json['color'],
      hasAlarm: json['hasAlarm'] ?? false,
      hasPreAlarm: json['hasPreAlarm'] ?? false,
      preAlarmMinutes: json['preAlarmMinutes'] ?? 15,
      smartIntervalsEnabled: json['smartIntervalsEnabled'] ?? false,
      smartIntervalMinutes: json['smartIntervalMinutes'] ?? 0,
      silentIntervals: json['silentIntervals'] ?? false,
      showProgressMessages: json['showProgressMessages'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : null,
    );
  }
}