class UserModel {
  final String uid;
  final String email;
  final bool isPro;
  final List<RoutineSlotModel> routineSlots;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.isPro,
    required this.routineSlots,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      isPro: map['isPro'] ?? false,
      routineSlots: (map['routineSlots'] as List<dynamic>?)
          ?.map((slot) => RoutineSlotModel.fromMap(slot))
          .toList() ?? [],
      createdAt: map['createdAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'isPro': isPro,
      'routineSlots': routineSlots.map((slot) => slot.toMap()).toList(),
      'createdAt': createdAt,
    };
  }
}

class RoutineSlotModel {
  final String id;
  final String name;
  final bool isActive;
  final bool isPaid;
  final List<TimeSlotModel> timeSlots;

  RoutineSlotModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.isPaid,
    required this.timeSlots,
  });

  factory RoutineSlotModel.fromMap(Map<String, dynamic> map) {
    return RoutineSlotModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      isActive: map['isActive'] ?? false,
      isPaid: map['isPaid'] ?? false,
      timeSlots: (map['timeSlots'] as List<dynamic>?)
          ?.map((slot) => TimeSlotModel.fromMap(slot))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
      'isPaid': isPaid,
      'timeSlots': timeSlots.map((slot) => slot.toMap()).toList(),
    };
  }
}

class TimeSlotModel {
  final String id;
  final double startHour;
  final double endHour;
  final String activity;
  final String color;

  TimeSlotModel({
    required this.id,
    required this.startHour,
    required this.endHour,
    required this.activity,
    required this.color,
  });

  factory TimeSlotModel.fromMap(Map<String, dynamic> map) {
    return TimeSlotModel(
      id: map['id'] ?? '',
      startHour: (map['startHour'] ?? 0).toDouble(),
      endHour: (map['endHour'] ?? 0).toDouble(),
      activity: map['activity'] ?? '',
      color: map['color'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startHour': startHour,
      'endHour': endHour,
      'activity': activity,
      'color': color,
    };
  }
}