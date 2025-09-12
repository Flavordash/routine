import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/routine_slot_model.dart';
import '../utils/logger.dart';

class RoutineSlotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

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

  // Save routine slots to Firestore
  Future<void> saveRoutineSlots(List<RoutineSlot> slots) async {
    try {
      if (currentUser == null) {
        Logger.instance.warning('No user logged in, cannot save slots');
        return;
      }

      final slotsData = slots.map((slot) => slot.toJson()).toList();

      await _firestore.collection('users').doc(currentUser!.uid).update({
        'routineSlots': slotsData,
        'lastModified': FieldValue.serverTimestamp(),
      });

      Logger.instance.info('Routine slots saved successfully');
    } catch (error) {
      Logger.instance.error('Error saving routine slots: $error');
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

  // Add a new slot
  List<RoutineSlot> addNewSlot(List<RoutineSlot> slots, String name, bool isPaid) {
    final newSlot = RoutineSlot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      isActive: false,
      isPaid: isPaid,
      timeSlots: [],
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
}