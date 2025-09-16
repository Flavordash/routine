import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/routine_slot_service.dart';
import '../models/routine_slot_model.dart';

// Provider for the RoutineSlotService instance
final routineSlotServiceProvider = Provider<RoutineSlotService>((ref) {
  return RoutineSlotService();
});

// StateNotifier for managing routine slots state
class RoutineSlotsNotifier extends StateNotifier<AsyncValue<List<RoutineSlot>>> {
  RoutineSlotsNotifier(this._routineSlotService) : super(const AsyncValue.loading()) {
    _loadRoutineSlots();
  }

  final RoutineSlotService _routineSlotService;

  // Load routine slots from storage
  Future<void> _loadRoutineSlots() async {
    try {
      final slots = await _routineSlotService.getRoutineSlots();
      state = AsyncValue.data(slots);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Refresh routine slots
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadRoutineSlots();
  }

  // Add a new routine slot
  Future<void> addRoutineSlot(RoutineSlot slot) async {
    final currentSlots = state.value ?? [];
    final updatedSlots = [...currentSlots, slot];
    
    try {
      await _routineSlotService.saveRoutineSlots(updatedSlots);
      state = AsyncValue.data(updatedSlots);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Update a routine slot
  Future<void> updateRoutineSlot(RoutineSlot updatedSlot) async {
    final currentSlots = state.value ?? [];
    final updatedSlots = currentSlots.map((slot) {
      return slot.id == updatedSlot.id ? updatedSlot : slot;
    }).toList();

    try {
      await _routineSlotService.saveRoutineSlots(updatedSlots);
      state = AsyncValue.data(updatedSlots);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Delete a routine slot
  Future<void> deleteRoutineSlot(String slotId) async {
    final currentSlots = state.value ?? [];
    final updatedSlots = currentSlots.where((slot) => slot.id != slotId).toList();

    try {
      await _routineSlotService.saveRoutineSlots(updatedSlots);
      state = AsyncValue.data(updatedSlots);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Activate a specific routine slot
  Future<void> activateRoutineSlot(String slotId) async {
    final currentSlots = state.value ?? [];
    final updatedSlots = _routineSlotService.activateSlot(currentSlots, slotId);

    try {
      await _routineSlotService.saveRoutineSlots(updatedSlots);
      state = AsyncValue.data(updatedSlots);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Update time slots for a specific routine slot
  Future<void> updateTimeSlots(String slotId, List<RoutineTimeSlot> timeSlots) async {
    final currentSlots = state.value ?? [];
    final updatedSlots = _routineSlotService.updateTimeSlots(currentSlots, slotId, timeSlots);

    try {
      await _routineSlotService.saveRoutineSlots(updatedSlots);
      state = AsyncValue.data(updatedSlots);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Import template as new routine slot using safer method
  Future<void> importTemplate({
    required String templateName,
    required List<Map<String, dynamic>> templateTimeSlots,
    required bool isPaid,
    bool setAsActive = true,
  }) async {
    final currentSlots = state.value ?? [];
    
    try {
      final updatedSlots = await _routineSlotService.importTemplateAsNewSlot(
        currentSlots: currentSlots,
        templateName: templateName,
        templateTimeSlots: templateTimeSlots,
        isPaid: isPaid,
        setAsActive: setAsActive,
      );
      
      state = AsyncValue.data(updatedSlots);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Provider for routine slots state management
final routineSlotsProvider = StateNotifierProvider<RoutineSlotsNotifier, AsyncValue<List<RoutineSlot>>>((ref) {
  final routineSlotService = ref.watch(routineSlotServiceProvider);
  return RoutineSlotsNotifier(routineSlotService);
});

// Provider for the currently active routine slot
final activeRoutineSlotProvider = Provider<RoutineSlot?>((ref) {
  final routineSlots = ref.watch(routineSlotsProvider);
  return routineSlots.when(
    data: (slots) => ref.read(routineSlotServiceProvider).getActiveSlot(slots),
    loading: () => null,
    error: (_, __) => null,
  );
});

// Provider to check if there are any routine slots
final hasRoutineSlotsProvider = Provider<bool>((ref) {
  final routineSlots = ref.watch(routineSlotsProvider);
  return routineSlots.when(
    data: (slots) => slots.isNotEmpty,
    loading: () => false,
    error: (_, __) => false,
  );
});