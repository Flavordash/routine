import 'package:flutter/material.dart';
import '../../template_service.dart';
import 'template_card.dart';

class TemplateGalleryDialog extends StatefulWidget {
  final Function(
    String templateName,
    List<Map<String, dynamic>> templateTimeSlots,
  ) onTemplateImport;

  const TemplateGalleryDialog({super.key, required this.onTemplateImport});

  @override
  State<TemplateGalleryDialog> createState() => _TemplateGalleryDialogState();
}

class _TemplateGalleryDialogState extends State<TemplateGalleryDialog> {
  String selectedCategory = 'All';
  String selectedLifestyle = 'All';
  String searchQuery = '';
  bool isLoading = true;
  List<Template> templates = [];
  List<Template> filteredTemplates = [];
  final TextEditingController _searchController = TextEditingController();
  final Set<String> likedTemplates = <String>{}; // Track liked template IDs

  final categories = ['All', ...TemplateService.categories];
  final lifestyles = ['All', ...TemplateService.lifestyleTypes];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text;
      _filterTemplates();
    });
  }

  Future<void> _loadTemplates() async {
    setState(() {
      isLoading = true;
    });

    try {
      final firebaseTemplates = await TemplateService.getTemplates();
      final mockTemplatesConverted = _convertMockTemplatesToFirebase();

      setState(() {
        // Combine Firebase templates with converted mock templates (mock templates first for priority)
        templates = [...mockTemplatesConverted, ...firebaseTemplates];
        _filterTemplates();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        // If Firebase fails, still show mock templates
        templates = _convertMockTemplatesToFirebase();
        _filterTemplates();
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load some templates: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _filterTemplates() {
    filteredTemplates = templates.where((template) {
      // Category filter
      final categoryMatch =
          selectedCategory == 'All' || template.category == selectedCategory;

      // Lifestyle filter
      final lifestyleMatch =
          selectedLifestyle == 'All' || template.lifestyle == selectedLifestyle;

      // Search filter
      final searchMatch =
          searchQuery.isEmpty ||
          template.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          template.description.toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          template.authorName.toLowerCase().contains(searchQuery.toLowerCase());

      return categoryMatch && lifestyleMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        constraints: const BoxConstraints(
          minWidth: 300,
          minHeight: 400,
          maxWidth: 500,
          maxHeight: 700,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Browse Templates',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search templates, authors...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filters
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        hint: const Text('Category'),
                        isExpanded: true,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(
                              category,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                            _filterTemplates();
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedLifestyle,
                        hint: const Text('Lifestyle'),
                        isExpanded: true,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                        items: lifestyles.map((lifestyle) {
                          return DropdownMenuItem(
                            value: lifestyle,
                            child: Text(
                              lifestyle,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedLifestyle = value!;
                            _filterTemplates();
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Templates Grid
            Expanded(child: _buildTemplatesGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesGrid() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading templates...'),
          ],
        ),
      );
    }

    if (filteredTemplates.isEmpty && templates.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No templates found'),
            if (searchQuery.isNotEmpty ||
                selectedCategory != 'All' ||
                selectedLifestyle != 'All')
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    selectedCategory = 'All';
                    selectedLifestyle = 'All';
                    searchQuery = '';
                    _filterTemplates();
                  });
                },
                child: Text('Clear filters'),
              ),
          ],
        ),
      );
    }

    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No templates available'),
            TextButton(onPressed: _loadTemplates, child: Text('Retry')),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 6,
      ),
      itemCount: filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = filteredTemplates[index];
        return TemplateCard(
          template: template,
          onImport: () => _importFirebaseTemplate(template),
          onLike: () => _likeTemplate(template),
          isLiked: likedTemplates.contains(template.id),
        );
      },
    );
  }

  void _importFirebaseTemplate(Template template) {
    // Convert Firebase template to widget format
    widget.onTemplateImport(template.title, template.timeSlots);
  }

  void _likeTemplate(Template template) async {
    final isCurrentlyLiked = likedTemplates.contains(template.id);

    // Toggle like status
    if (isCurrentlyLiked) {
      // Unlike the template
      final success = await TemplateService.unlikeTemplate(template.id);
      if (success) {
        setState(() {
          // Remove from liked templates set
          likedTemplates.remove(template.id);

          // Update the template in our local list
          final index = templates.indexWhere((t) => t.id == template.id);
          if (index != -1) {
            templates[index] = Template(
              id: template.id,
              title: template.title,
              description: template.description,
              category: template.category,
              lifestyle: template.lifestyle,
              authorId: template.authorId,
              authorName: template.authorName,
              timeSlots: template.timeSlots,
              likes: template.likes - 1, // Decrease like count
              usageCount: template.usageCount,
              isOfficial: template.isOfficial,
              createdAt: template.createdAt,
            );
            _filterTemplates();
          }
        });
      }
    } else {
      // Like the template
      final success = await TemplateService.likeTemplate(template.id);
      if (success) {
        setState(() {
          // Add to liked templates set
          likedTemplates.add(template.id);

          // Update the template in our local list
          final index = templates.indexWhere((t) => t.id == template.id);
          if (index != -1) {
            templates[index] = Template(
              id: template.id,
              title: template.title,
              description: template.description,
              category: template.category,
              lifestyle: template.lifestyle,
              authorId: template.authorId,
              authorName: template.authorName,
              timeSlots: template.timeSlots,
              likes: template.likes + 1, // Increase like count
              usageCount: template.usageCount,
              isOfficial: template.isOfficial,
              createdAt: template.createdAt,
            );
            _filterTemplates();
          }
        });
      }
    }
  }

  List<RoutineTemplate> _getMockTemplates() {
    return [
      RoutineTemplate(
        id: '1',
        name: 'Student Life',
        category: 'Student',
        description: 'Perfect schedule for students',
        author: 'Routine 24',
        likes: 245,
        isOfficial: true,
        timeSlots: [
          {
            'startTime': '07:00',
            'endTime': '08:00',
            'label': 'Morning Routine',
            'description': 'Get ready for the day',
            'color': 0xFF2196F3,
            'startAngle': 105.0,
            'endAngle': 120.0,
          },
          {
            'startTime': '09:00',
            'endTime': '12:00',
            'label': 'Study Session',
            'description': 'Focused learning time',
            'color': 0xFF4CAF50,
            'startAngle': 135.0,
            'endAngle': 180.0,
          },
        ],
      ),
      RoutineTemplate(
        id: '2',
        name: 'Office Worker',
        category: 'Office Worker',
        description: 'Standard office schedule',
        author: 'Routine 24',
        likes: 189,
        isOfficial: true,
        timeSlots: [
          {
            'startTime': '09:00',
            'endTime': '17:00',
            'label': 'Work Hours',
            'description': 'Professional work time',
            'color': 0xFFFF9800,
            'startAngle': 135.0,
            'endAngle': 255.0,
          },
        ],
      ),
      RoutineTemplate(
        id: '3',
        name: 'Fitness Focus',
        category: 'Fitness',
        description: 'Health and fitness routine',
        author: 'FitLife',
        likes: 324,
        timeSlots: [
          {
            'startTime': '06:00',
            'endTime': '07:00',
            'label': 'Morning Workout',
            'description': 'Start the day strong',
            'color': 0xFFF44336,
            'startAngle': 90.0,
            'endAngle': 105.0,
          },
          {
            'startTime': '18:00',
            'endTime': '19:00',
            'label': 'Evening Exercise',
            'description': 'End of day fitness',
            'color': 0xFF9C27B0,
            'startAngle': 270.0,
            'endAngle': 285.0,
          },
        ],
      ),
    ];
  }

  List<Template> _convertMockTemplatesToFirebase() {
    final mockTemplates = _getMockTemplates();

    return mockTemplates.map((mockTemplate) {
      // Convert timeSlots to the format expected by Firebase Template
      final convertedTimeSlots = mockTemplate.timeSlots.map((slot) {
        return {
          'id': slot['id'] ?? '',
          'startAngle': slot['startAngle'] ?? 0.0,
          'endAngle': slot['endAngle'] ?? 0.0,
          'startTime': slot['startTime'] ?? '',
          'endTime': slot['endTime'] ?? '',
          'label': slot['label'] ?? '',
          'description': slot['description'] ?? '',
          'color': slot['color'] ?? 0xFF2196F3,
          'hasAlarm': slot['hasAlarm'] ?? false,
          'hasPreAlarm': slot['hasPreAlarm'] ?? false,
          'preAlarmMinutes': slot['preAlarmMinutes'] ?? 15,
          'snoozeEnabled': slot['snoozeEnabled'] ?? true,
          'snoozeDuration': slot['snoozeDuration'] ?? 10,
          'maxSnoozeCount': slot['maxSnoozeCount'] ?? 3,
          'createdAt': DateTime.now().toIso8601String(),
        };
      }).toList();

      return Template(
        id: 'app_${mockTemplate.id}', // Prefix to identify app-provided templates
        title: mockTemplate.name,
        description: mockTemplate.description,
        category: mockTemplate.category,
        lifestyle: 'Balanced', // Default lifestyle for app templates
        authorId: 'routine24_official',
        authorName: 'Routine 24',
        timeSlots: convertedTimeSlots,
        likes: mockTemplate.likes,
        usageCount: 150 + (mockTemplate.likes * 2), // Mock usage count based on likes
        isOfficial: true, // Mark as official/app-provided
        createdAt: DateTime.now(),
      );
    }).toList();
  }

}

class RoutineTemplate {
  final String id;
  final String name;
  final String category;
  final String description;
  final String author;
  final int likes;
  final List<Map<String, dynamic>> timeSlots;
  final bool isOfficial;
  final bool isLiked;

  RoutineTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.author,
    required this.likes,
    required this.timeSlots,
    this.isOfficial = false,
    this.isLiked = false,
  });

  RoutineTemplate copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? author,
    int? likes,
    List<Map<String, dynamic>>? timeSlots,
    bool? isOfficial,
    bool? isLiked,
  }) {
    return RoutineTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      author: author ?? this.author,
      likes: likes ?? this.likes,
      timeSlots: timeSlots ?? this.timeSlots,
      isOfficial: isOfficial ?? this.isOfficial,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}