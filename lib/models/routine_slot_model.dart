class RoutineSlot {
  final String id;
  final String name;
  final bool isActive;
  final bool isPaid;
  final List<RoutineTimeSlot> timeSlots;
  final DateTime? createdAt;
  final DateTime? lastModified;

  RoutineSlot({
    required this.id,
    required this.name,
    required this.isActive,
    required this.isPaid,
    this.timeSlots = const [],
    this.createdAt,
    this.lastModified,
  });

  RoutineSlot copyWith({
    String? id,
    String? name,
    bool? isActive,
    bool? isPaid,
    List<RoutineTimeSlot>? timeSlots,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return RoutineSlot(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      isPaid: isPaid ?? this.isPaid,
      timeSlots: timeSlots ?? this.timeSlots,
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
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : null,
    );
  }
}