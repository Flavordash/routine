import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/routine_slot_service.dart';
import '../../services/subscription_service.dart';
import '../../models/user_model.dart';
import '../../models/routine_slot_model.dart';
import '../../l10n/app_localizations.dart';
import '../../template_service.dart';
import '../template/template_gallery_dialog.dart';

class HamburgerMenuDialog extends StatefulWidget {
  const HamburgerMenuDialog({
    super.key,
    required this.routineSlots,
    required this.activeSlot,
    required this.routineSlotService,
    required this.onSlotsChanged,
    required this.isProUser,
  });

  final List<RoutineSlot> routineSlots;
  final RoutineSlot? activeSlot;
  final RoutineSlotService routineSlotService;
  final Function(List<RoutineSlot>, RoutineSlot?) onSlotsChanged;
  final bool isProUser;

  @override
  State<HamburgerMenuDialog> createState() => _HamburgerMenuDialogState();
}

class _HamburgerMenuDialogState extends State<HamburgerMenuDialog>
    with TickerProviderStateMixin {
  late List<RoutineSlot> routineSlots;
  late RoutineSlot? activeSlot;
  bool isLoggedIn = false;
  String userEmail = '';
  final AuthService _authService = AuthService();
  late AnimationController _editAnimationController;
  late AnimationController _addAnimationController;
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    _editAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _addAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    routineSlots = List.from(widget.routineSlots);
    activeSlot = widget.activeSlot;
    _checkAuthState();
  }

  void _checkAuthState() {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        isLoggedIn = true;
        userEmail = user.email ?? '';
      });
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.getUserData();
    if (userData != null) {
      setState(() {
        // isProUser comes from parent widget
      });
    }
  }

  Future<void> _updateAuthState() async {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        isLoggedIn = true;
        userEmail = user.email ?? '';
      });
      await _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.routineSlots,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Authentication Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: isLoggedIn ? _buildUserProfile() : _buildLoginPrompt(),
            ),
            const SizedBox(height: 16),

            // Pro status indicator
            if (!widget.isProUser)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.freeUsersOneSlot,
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Routine slots list
            Expanded(
              child: ListView.builder(
                itemCount: routineSlots.length,
                itemBuilder: (context, index) {
                  final slot = routineSlots[index];
                  return _buildRoutineSlotCard(slot);
                },
              ),
            ),

            // Browse Templates Button
            const SizedBox(height: 16),
            if (widget.isProUser)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _showTemplateGallery,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books, size: 18),
                      const SizedBox(width: 8),
                      Text('Browse Templates'),
                    ],
                  ),
                ),
              ),

            // Add new slot button
            if (widget.isProUser) const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (widget.isProUser || routineSlots.length < 2)
                    ? () {
                        _addAnimationController.forward().then((_) {
                          _addAnimationController.reverse();
                        });
                        _addNewSlot();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedIcon(
                      icon: AnimatedIcons.add_event,
                      progress: _addAnimationController,
                    ),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.addNewRoutineSlot),
                  ],
                ),
              ),
            ),

            if (!widget.isProUser && routineSlots.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () {
                    // Show upgrade dialog
                    _showUpgradeDialog();
                  },
                  child: Text(
                    AppLocalizations.of(context)!.upgradeToProUnlimited,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineSlotCard(RoutineSlot slot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: slot.isActive
          ? (Theme.of(context).brightness == Brightness.light
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1))
          : null,
      child: ListTile(
        leading: GestureDetector(
          onTap: () => _showColorSettingsDialog(slot),
          child: CircleAvatar(
            backgroundColor: slot.color != null
                ? Color(slot.color!)
                : (slot.isActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey),
            radius: 12,
            child: slot.isActive
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          slot.name == 'Default Routine'
              ? AppLocalizations.of(context)!.defaultRoutine
              : slot.name,
          style: TextStyle(
            fontWeight: slot.isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slot.isActive
                  ? AppLocalizations.of(context)!.currentlyActive
                  : AppLocalizations.of(context)!.tapToActivate,
              style: TextStyle(
                color: slot.isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            if (widget.isProUser && slot.selectedDays.length < 7)
              Text(
                _getDaysText(slot.selectedDays),
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (slot.isPaid)
              const Icon(Icons.star, color: Colors.orange, size: 16),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'rename':
                    _renameSlot(slot);
                    break;
                  case 'duplicate':
                    _duplicateSlot(slot);
                    break;
                  case 'delete':
                    _deleteSlot(slot);
                    break;
                  case 'daySettings':
                    _showDaySettingsDialog(slot);
                    break;
                  case 'colorSettings':
                    _showColorSettingsDialog(slot);
                    break;
                  case 'shareTemplate':
                    _showShareTemplateDialog(slot);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: ListTile(
                    leading: Icon(Icons.edit, size: 16),
                    title: Text('Rename'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'colorSettings',
                  child: ListTile(
                    leading: Icon(Icons.palette, size: 16),
                    title: Text('Color Settings'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (widget.isProUser) ...[
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: Icon(Icons.copy, size: 16),
                      title: Text('Duplicate'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'daySettings',
                    child: ListTile(
                      leading: Icon(Icons.date_range, size: 16),
                      title: Text('Day Settings'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'shareTemplate',
                    child: ListTile(
                      leading: Icon(Icons.share, size: 16),
                      title: Text('Share as Template'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                if (routineSlots.length > 1)
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, size: 16, color: Colors.red),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: () {
          if (!slot.isActive) {
            _activateSlot(slot);
          }
        },
      ),
    );
  }

  void _addNewSlot() {
    if (!widget.isProUser && routineSlots.isNotEmpty) {
      _showUpgradeDialog();
      return;
    }

    // Use the service method for automatic color allocation
    final updatedSlots = widget.routineSlotService.addNewSlot(
      routineSlots,
      'Routine ${routineSlots.length + 1}',
      widget.isProUser,
    );

    setState(() {
      routineSlots = updatedSlots;
    });

    // Save the updated slots
    widget.onSlotsChanged(routineSlots, activeSlot);
  }

  void _activateSlot(RoutineSlot slot) {
    setState(() {
      routineSlots = widget.routineSlotService.activateSlot(
        routineSlots,
        slot.id,
      );
      activeSlot = widget.routineSlotService.getActiveSlot(routineSlots);
    });

    widget.onSlotsChanged(routineSlots, activeSlot);
    Navigator.of(context).pop();
  }

  void _renameSlot(RoutineSlot slot) {
    final controller = TextEditingController(text: slot.name);

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        title: const Text('Rename Routine'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Routine Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                // Find slot by ID instead of object reference to avoid -1 index
                final index = routineSlots.indexWhere((s) => s.id == slot.id);
                
                if (index != -1) {
                  setState(() {
                    routineSlots[index] = slot.copyWith(
                      name: controller.text.trim(),
                    );
                    
                    // Update activeSlot reference if this is the active slot
                    if (slot.isActive) {
                      activeSlot = routineSlots[index];
                    }
                  });
                  
                  // Save changes
                  widget.onSlotsChanged(routineSlots, activeSlot);
                  
                  Navigator.pop(context);
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Routine renamed to "${controller.text.trim()}"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // Handle error case
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: Could not find routine to rename'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _duplicateSlot(RoutineSlot slot) {
    if (!widget.isProUser) {
      _showUpgradeDialog();
      return;
    }

    // Get automatic color allocation for the duplicated slot
    final autoColor = widget.routineSlotService.getNextAvailableColor(routineSlots);

    final duplicatedSlot = RoutineSlot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${slot.name} (Copy)',
      isActive: false,
      isPaid: slot.isPaid,
      color: autoColor, // Use automatic color allocation instead of copying the same color
      selectedDays: List.from(slot.selectedDays),
      timeSlots: slot.timeSlots.map((timeSlot) => timeSlot.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      )).toList(),
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );

    setState(() {
      routineSlots.add(duplicatedSlot);
    });

    // Save the updated slots
    widget.onSlotsChanged(routineSlots, activeSlot);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${AppLocalizations.of(context)!.duplicate} "${slot.name}" successfully',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteSlot(RoutineSlot slot) {
    if (routineSlots.length <= 1) return;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine'),
        content: Text('Are you sure you want to delete "${slot.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                routineSlots.remove(slot);

                // If the deleted slot was active, activate the first remaining slot
                if (slot.isActive && routineSlots.isNotEmpty) {
                  routineSlots[0] = RoutineSlot(
                    id: routineSlots[0].id,
                    name: routineSlots[0].name,
                    isActive: true,
                    isPaid: routineSlots[0].isPaid,
                  );
                }
              });

              // Save the updated routine slots to persistent storage
              await widget.routineSlotService.saveRoutineSlots(routineSlots);

              // Notify the parent component about the changes
              widget.onSlotsChanged(routineSlots, activeSlot);

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getDaysText(List<int> selectedDays) {
    if (selectedDays.length == 7) return 'Every day';
    if (selectedDays.isEmpty) return 'No days selected';

    final dayAbbreviations = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selectedAbbreviations = selectedDays
        .map((dayIndex) => dayAbbreviations[dayIndex - 1])
        .toList();

    return selectedAbbreviations.join(', ');
  }

  void _showDaySettingsDialog(RoutineSlot slot) {
    List<int> selectedDays = List.from(slot.selectedDays);
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Day Settings for ${slot.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select which days this routine should be active:'),
                const SizedBox(height: 16),
                ...dayNames.asMap().entries.map((entry) {
                  final dayIndex = entry.key + 1; // 1-7 for Monday-Sunday
                  final dayName = entry.value;
                  final isSelected = selectedDays.contains(dayIndex);

                  return CheckboxListTile(
                    title: Text(dayName),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          if (!selectedDays.contains(dayIndex)) {
                            selectedDays.add(dayIndex);
                            selectedDays.sort();
                          }
                        } else {
                          selectedDays.remove(dayIndex);
                        }
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    final index = routineSlots.indexWhere(
                      (s) => s.id == slot.id,
                    );
                    if (index != -1) {
                      routineSlots[index] = slot.copyWith(
                        selectedDays: selectedDays,
                      );
                    }
                  });
                  widget.onSlotsChanged(routineSlots, activeSlot);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Day settings updated for ${slot.name}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showColorSettingsDialog(RoutineSlot slot) {
    final colors = [
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

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        title: Text('Choose Color for ${slot.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: colors.length + 1, // +1 for default option
            itemBuilder: (context, index) {
              if (index == 0) {
                // Default color option
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      final slotIndex = routineSlots.indexWhere(
                        (s) => s.id == slot.id,
                      );
                      if (slotIndex != -1) {
                        routineSlots[slotIndex] = slot.copyWith(color: null);
                      }
                    });
                    widget.onSlotsChanged(routineSlots, activeSlot);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Color reset to default for ${slot.name}',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 2),
                      color: Colors.transparent,
                    ),
                    child: const Center(
                      child: Text(
                        'Default',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }

              final colorValue = colors[index - 1];
              final color = Color(colorValue);
              final isSelected = slot.color == colorValue;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    final slotIndex = routineSlots.indexWhere(
                      (s) => s.id == slot.id,
                    );
                    if (slotIndex != -1) {
                      routineSlots[slotIndex] = slot.copyWith(
                        color: colorValue,
                      );
                    }
                  });
                  widget.onSlotsChanged(routineSlots, activeSlot);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Color updated for ${slot.name}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );
  }

  void _showShareTemplateDialog(RoutineSlot slot) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = TemplateService.categories.first;
    String selectedLifestyle = TemplateService.lifestyleTypes.first;

    final categories = TemplateService.categories;
    final lifestyles = TemplateService.lifestyleTypes;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Share as Template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Template Name *',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: 'Enter template name...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Describe this routine...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                const Text(
                  'Lifestyle Type',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedLifestyle,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: lifestyles.map((lifestyle) {
                    return DropdownMenuItem(
                      value: lifestyle,
                      child: Text(lifestyle),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedLifestyle = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentContext = context;
                final templateName = titleController.text.trim();

                if (templateName.isEmpty) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a template name'),
                    ),
                  );
                  return;
                }

                // Show loading dialog
                showDialog(
                  context: currentContext,
                  barrierDismissible: false,
                  barrierColor: Colors.black54,
                  builder: (context) => AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Sharing template...'),
                      ],
                    ),
                  ),
                );

                // Convert routine slot time slots to template format
                final templateTimeSlots = TemplateService.timeSlotsToMap(
                  slot.timeSlots,
                );

                // Save template to Firebase
                final success = await TemplateService.shareTemplate(
                  title: templateName,
                  description: descriptionController.text.trim(),
                  category: selectedCategory,
                  lifestyle: selectedLifestyle,
                  timeSlots: templateTimeSlots,
                );

                // Close loading dialog
                if (currentContext.mounted) {
                  Navigator.pop(currentContext);
                  // Close share dialog
                  Navigator.pop(currentContext);

                  // Show success or error message
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Template "$templateName" shared successfully!'
                            : 'Failed to share template. Please try again.',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Share'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog() {
    // Directly show subscription dialog, removing the intermediate modal
    _showSubscriptionDialog();
  }

  Widget _buildUserProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              radius: 20,
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userEmail.isNotEmpty ? userEmail : 'User',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isProUser ? Colors.amber : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.isProUser
                          ? AppLocalizations.of(context)!.proMember
                          : AppLocalizations.of(context)!.freeUser,
                      style: TextStyle(
                        color: widget.isProUser ? Colors.black : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'upgrade':
                    if (!widget.isProUser) _showUpgradeDialog();
                    break;
                  case 'logout':
                    _logout();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (!widget.isProUser)
                  PopupMenuItem(
                    value: 'upgrade',
                    child: ListTile(
                      leading: const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.upgradeToProButton,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: const Icon(Icons.logout, size: 16),
                    title: Text(AppLocalizations.of(context)!.logout),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (widget.isProUser) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.thanksForSupporting,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_circle_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.signInToSync,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _showSignInDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.signIn,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _showSignUpDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.signUp,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSignInDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.signIn),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Social Login Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setDialogState(() {
                            isLoading = true;
                          });
                          try {
                            await _authService.signInWithGoogle();
                            await _updateAuthState();
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Successfully signed in with Google!',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isLoading = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Google sign in failed: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: Text(AppLocalizations.of(context)!.continueWithGoogle),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppLocalizations.of(context)!.or,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.email,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.password,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() {
                        isLoading = true;
                      });

                      try {
                        await _authService.signInWithEmailAndPassword(
                          emailController.text.trim(),
                          passwordController.text,
                        );

                        await _updateAuthState();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Successfully signed in!'),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isLoading = false;
                        });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sign in failed: ${e.toString()}'),
                            ),
                          );
                        }
                      }
                    },
              child: Text(AppLocalizations.of(context)!.signInWithEmail),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignUpDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.signUp),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Social Login Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setDialogState(() {
                            isLoading = true;
                          });
                          try {
                            await _authService.signInWithGoogle();
                            await _updateAuthState();
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Successfully signed up with Google!',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isLoading = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Google sign up failed: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: Text(AppLocalizations.of(context)!.continueWithGoogle),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppLocalizations.of(context)!.or,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.email,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.password,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.confirmPassword,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (passwordController.text !=
                          confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                          ),
                        );
                        return;
                      }

                      if (passwordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password must be at least 6 characters',
                            ),
                          ),
                        );
                        return;
                      }

                      setDialogState(() {
                        isLoading = true;
                      });

                      try {
                        await _authService.registerWithEmailAndPassword(
                          emailController.text.trim(),
                          passwordController.text,
                        );

                        await _updateAuthState();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account created successfully!'),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isLoading = false;
                        });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Registration failed: ${e.toString()}',
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: Text(AppLocalizations.of(context)!.signUpWithEmail),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    try {
      await _authService.signOut();
      setState(() {
        isLoggedIn = false;
        userEmail = '';
        // isProUser managed by parent
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully signed out')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: ${e.toString()}')),
        );
      }
    }
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
                  context,
                  Icons.block,
                  AppLocalizations.of(context)!.removeAllAdsFull.substring(2),
                ),
                _buildProFeature(
                  context,
                  Icons.all_inclusive,
                  AppLocalizations.of(context)!.unlimitedSlots.substring(2),
                ),
                _buildProFeature(
                  context,
                  Icons.cloud_download,
                  AppLocalizations.of(context)!.browseImportTemplates.substring(2),
                ),
                _buildProFeature(
                  context,
                  Icons.share,
                  AppLocalizations.of(context)!.shareTemplates.substring(2),
                ),
                _buildProFeature(
                  context,
                  Icons.alarm,
                  AppLocalizations.of(context)!.advancedAlarmFeatures.substring(2),
                ),
                _buildProFeature(
                  context,
                  Icons.calendar_today,
                  AppLocalizations.of(context)!.scheduleSpecificDaysFull.substring(2),
                ),
                _buildProFeature(
                  context,
                  Icons.backup,
                  AppLocalizations.of(context)!.cloudSyncBackupFull.substring(2),
                ),
                _buildProFeature(
                  context,
                  Icons.support,
                  AppLocalizations.of(context)!.prioritySupport.substring(2),
                ),
                _buildProFeature(
                  context,
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
                        context,
                        title: 'Monthly Plan',
                        price: '\$3.99/month',
                        savings: null,
                        isPopular: false,
                        onTap: () => _purchaseSubscription(monthly: true),
                      ),

                      const SizedBox(height: 8),

                      // Yearly Plan
                      _buildSubscriptionOption(
                        context,
                        title: 'Yearly Plan',
                        price: '\$7.99/year',
                        savings: 'Save 83%!',
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
                'Restore',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProFeature(BuildContext context, IconData icon, String text) {
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

  Widget _buildSubscriptionOption(
    BuildContext context, {
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
                  'POPULAR',
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
              'Processing purchase...',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );

    // Attempt purchase
    SubscriptionService.instance
        .purchaseSubscription(yearly: !monthly)
        .then((_) {
          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome to Pro! 🎉'),
                backgroundColor: Colors.green,
              ),
            );
          }
        })
        .catchError((error) {
          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Purchase failed: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
  }

  void _restorePurchases() {
    Navigator.of(context).pop();

    SubscriptionService.instance
        .restorePurchases()
        .then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Purchases restored successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        })
        .catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Restore failed: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
  }

  void _showTemplateGallery() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) =>
          TemplateGalleryDialog(onTemplateImport: _importTemplate),
    );
  }

  void _importTemplate(
    String templateName,
    List<Map<String, dynamic>> templateTimeSlots,
  ) async {
    try {
      // Use the RoutineSlotService for safer template import
      final routineSlotService = RoutineSlotService();
      
      final updatedSlots = await routineSlotService.importTemplateAsNewSlot(
        currentSlots: routineSlots,
        templateName: templateName,
        templateTimeSlots: templateTimeSlots,
        isPaid: true, // Templates are a PRO feature
        setAsActive: true,
      );

      // Update local state
      setState(() {
        routineSlots = updatedSlots;
        activeSlot = routineSlotService.getActiveSlot(updatedSlots);
      });

      // Notify parent widget
      widget.onSlotsChanged(routineSlots, activeSlot);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Template "$templateName" imported and activated successfully!',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                // Scroll to show the newly activated routine in the hamburger menu
                // The routine is already active, so it will be visible
              },
            ),
          ),
        );
      }
    } catch (error) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to import template: $error',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _editAnimationController.dispose();
    _addAnimationController.dispose();
    super.dispose();
  }
}