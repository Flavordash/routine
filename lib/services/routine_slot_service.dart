import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/routine_slot_model.dart';
import '../utils/logger.dart';

// Custom exceptions for better error handling
class RoutineSlotException implements Exception {
  final String message;
  final String? code;
  
  RoutineSlotException(this.message, {this.code});
  
  @override
  String toString() => 'RoutineSlotException: $message';
}

class AuthenticationException extends RoutineSlotException {
  AuthenticationException(String message) : super(message, code: 'auth_error');
}

class ValidationException extends RoutineSlotException {
  ValidationException(String message) : super(message, code: 'validation_error');
}

class DataIntegrityException extends RoutineSlotException {
  DataIntegrityException(String message) : super(message, code: 'data_integrity_error');
}

class RoutineSlotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Available colors for routine slots (matching hamburger menu dialog)
  static const List<int> _availableColors = [
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFFF44336, // Red
    0xFF9C27B0, // Purple
    0xFFFF9800, // Orange
    0xFF009688, // Teal
    0xFFE91E63, // Pink
    0xFF3F51B5, // Indigo
    0xFFFFC107, // Amber
    0xFFFF5722, // Deep Orange
    0xFF03A9F4, // Light Blue
    0xFFCDDC39, // Lime
  ];

  // Automatically allocate a color for a new routine slot
  int _getNextAvailableColor(List<RoutineSlot> existingSlots) {
    // Get all colors currently in use
    final usedColors = existingSlots
        .where((slot) => slot.color != null)
        .map((slot) => slot.color!)
        .toSet();

    // Find first available color that's not in use
    for (final color in _availableColors) {
      if (!usedColors.contains(color)) {
        return color;
      }
    }

    // If all colors are used, cycle through them again
    // Use modulo to wrap around the color list
    final colorIndex = existingSlots.length % _availableColors.length;
    return _availableColors[colorIndex];
  }

  // Public method to get next available color (for external use)
  int getNextAvailableColor(List<RoutineSlot> existingSlots) {
    return _getNextAvailableColor(existingSlots);
  }

  // Get all available colors
  static List<int> get availableColors => List.unmodifiable(_availableColors);

  // Get all routine slots for current user
  Future<List<RoutineSlot>> getRoutineSlots() async {
    try {
      if (currentUser == null) {
        return _getDefaultSlots();
      }

      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!doc.exists) {
        return _getDefaultSlots();
      }

      final data = doc.data() as Map<String, dynamic>?;
      final slotsData = data?['routineSlots'] as List<dynamic>?;

      if (slotsData == null || slotsData.isEmpty) {
        return _getDefaultSlots();
      }

      return slotsData
          .map((item) => RoutineSlot.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      Logger.instance.error('Error loading routine slots: $error');
      return _getDefaultSlots();
    }
  }

  // Save routine slots to Firestore with better error handling and validation
  Future<void> saveRoutineSlots(List<RoutineSlot> slots) async {
    try {
      if (currentUser == null) {
        Logger.instance.warning('No user logged in, cannot save slots');
        throw AuthenticationException('User not authenticated');
      }

      // Validate slots data
      if (slots.isEmpty) {
        Logger.instance.warning('Attempting to save empty routine slots');
      }

      // Ensure each slot has a unique ID
      final slotIds = slots.map((slot) => slot.id).toSet();
      if (slotIds.length != slots.length) {
        Logger.instance.error('Duplicate slot IDs detected');
        throw DataIntegrityException('Duplicate routine slot IDs found');
      }

      final slotsData = slots.map((slot) => slot.toJson()).toList();

      // Use set instead of update to ensure document exists
      await _firestore.collection('users').doc(currentUser!.uid).set({
        'routineSlots': slotsData,
        'lastModified': FieldValue.serverTimestamp(),
        'email': currentUser!.email,
        'displayName': currentUser!.displayName,
        'photoURL': currentUser!.photoURL,
      }, SetOptions(merge: true));

      Logger.instance.info('Routine slots saved successfully for user ${currentUser!.uid}');
    } catch (error) {
      Logger.instance.error('Error saving routine slots: $error');
      rethrow;
    }
  }

  // Get the currently active slot
  RoutineSlot? getActiveSlot(List<RoutineSlot> slots) {
    try {
      return slots.firstWhere((slot) => slot.isActive);
    } catch (error) {
      return slots.isNotEmpty ? slots.first : null;
    }
  }

  // Activate a specific slot
  List<RoutineSlot> activateSlot(List<RoutineSlot> slots, String slotId) {
    return slots.map((slot) {
      return slot.copyWith(isActive: slot.id == slotId);
    }).toList();
  }

  // Add a new slot with automatic color allocation
  List<RoutineSlot> addNewSlot(List<RoutineSlot> slots, String name, bool isPaid) {
    final autoColor = _getNextAvailableColor(slots);
    
    final newSlot = RoutineSlot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      isActive: false,
      isPaid: isPaid,
      timeSlots: [],
      color: autoColor, // Automatically assign color
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );

    return [...slots, newSlot];
  }

  // Update a slot
  List<RoutineSlot> updateSlot(List<RoutineSlot> slots, RoutineSlot updatedSlot) {
    return slots.map((slot) {
      if (slot.id == updatedSlot.id) {
        return updatedSlot.copyWith(lastModified: DateTime.now());
      }
      return slot;
    }).toList();
  }

  // Delete a slot
  List<RoutineSlot> deleteSlot(List<RoutineSlot> slots, String slotId) {
    final filteredSlots = slots.where((slot) => slot.id != slotId).toList();
    
    // If the deleted slot was active, activate the first remaining slot
    final deletedSlot = slots.firstWhere((slot) => slot.id == slotId);
    if (deletedSlot.isActive && filteredSlots.isNotEmpty) {
      filteredSlots[0] = filteredSlots[0].copyWith(isActive: true);
    }

    return filteredSlots;
  }

  // Update time slots for a specific routine slot
  List<RoutineSlot> updateTimeSlots(
      List<RoutineSlot> slots, String slotId, List<RoutineTimeSlot> timeSlots) {
    return slots.map((slot) {
      if (slot.id == slotId) {
        return slot.copyWith(
          timeSlots: timeSlots,
          lastModified: DateTime.now(),
        );
      }
      return slot;
    }).toList();
  }

  // Default slots for new users
  List<RoutineSlot> _getDefaultSlots() {
    if (currentUser == null) {
      return [];
    }
    return [
      RoutineSlot(
        id: '1',
        name: 'Default Routine',
        isActive: true,
        isPaid: false,
        timeSlots: [],
        color: _availableColors.first, // Use first color (blue) for default
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
      ),
    ];
  }

  // Create time slot from clock interaction
  RoutineTimeSlot createTimeSlot({
    required double startAngle,
    required double endAngle,
    required String startTime,
    required String endTime,
    String? label,
    String? description,
    int? color,
  }) {
    return RoutineTimeSlot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startAngle: startAngle,
      endAngle: endAngle,
      startTime: startTime,
      endTime: endTime,
      label: label,
      description: description,
      color: color,
      createdAt: DateTime.now(),
    );
  }

  // Safely import template as new routine slot without affecting existing data
  Future<List<RoutineSlot>> importTemplateAsNewSlot({
    required List<RoutineSlot> currentSlots,
    required String templateName,
    required List<Map<String, dynamic>> templateTimeSlots,
    required bool isPaid,
    bool setAsActive = true,
  }) async {
    try {
      if (currentUser == null) {
        throw AuthenticationException('User not authenticated');
      }

      // Validate template name
      if (templateName.trim().isEmpty) {
        throw ValidationException('Template name cannot be empty');
      }

      // Check for duplicate template names
      final existingNames = currentSlots.map((slot) => slot.name.toLowerCase()).toSet();
      String finalName = templateName;
      int counter = 1;
      while (existingNames.contains(finalName.toLowerCase())) {
        finalName = '$templateName ($counter)';
        counter++;
      }

      // Generate unique ID
      final newSlotId = 'template_${DateTime.now().millisecondsSinceEpoch}';
      
      // Get automatic color allocation
      final autoColor = _getNextAvailableColor(currentSlots);
      
      // Convert template time slots to RoutineTimeSlot objects
      final newTimeSlots = templateTimeSlots.asMap().entries.map((entry) {
        final index = entry.key;
        final slotData = entry.value;
        
        return RoutineTimeSlot(
          id: '${newSlotId}_timeslot_$index',
          startAngle: (slotData['startAngle'] as num?)?.toDouble() ?? 0.0,
          endAngle: (slotData['endAngle'] as num?)?.toDouble() ?? 0.0,
          startTime: slotData['startTime']?.toString() ?? '09:00',
          endTime: slotData['endTime']?.toString() ?? '10:00',
          label: slotData['label']?.toString() ?? 'Activity',
          description: slotData['description']?.toString() ?? '',
          color: (slotData['color'] as int?) ?? 0xFF2196F3,
          hasAlarm: (slotData['hasAlarm'] as bool?) ?? false,
          hasPreAlarm: (slotData['hasPreAlarm'] as bool?) ?? false,
          preAlarmMinutes: (slotData['preAlarmMinutes'] as int?) ?? 15,
          smartIntervalsEnabled: (slotData['smartIntervalsEnabled'] as bool?) ?? false,
          smartIntervalMinutes: (slotData['smartIntervalMinutes'] as int?) ?? 0,
          silentIntervals: (slotData['silentIntervals'] as bool?) ?? false,
          showProgressMessages: (slotData['showProgressMessages'] as bool?) ?? true,
          createdAt: DateTime.now(),
        );
      }).toList();

      // Create a copy of current slots and deactivate all if needed
      final updatedSlots = setAsActive 
          ? currentSlots.map((slot) => slot.copyWith(isActive: false)).toList()
          : List<RoutineSlot>.from(currentSlots);

      // Create new routine slot
      final newSlot = RoutineSlot(
        id: newSlotId,
        name: finalName,
        isActive: setAsActive,
        isPaid: isPaid,
        timeSlots: newTimeSlots,
        selectedDays: [1, 2, 3, 4, 5, 6, 7], // All days by default
        color: autoColor, // Automatically assign color
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
      );

      // Add new slot to the list
      final finalSlots = [...updatedSlots, newSlot];

      // Save to Firestore
      await saveRoutineSlots(finalSlots);

      Logger.instance.info('Template "$finalName" imported successfully as new routine slot');
      return finalSlots;
    } catch (error) {
      Logger.instance.error('Error importing template: $error');
      rethrow;
    }
  }
}