import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/logger.dart';

// Template data model
class Template {
  final String id;
  final String title;
  final String description;
  final String category;
  final String lifestyle;
  final String authorId;
  final String authorName;
  final List<Map<String, dynamic>> timeSlots;
  final int likes;
  final int usageCount; // Number of times this template has been used/imported
  final bool isOfficial;
  final DateTime createdAt;

  Template({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.lifestyle,
    required this.authorId,
    required this.authorName,
    required this.timeSlots,
    required this.likes,
    this.usageCount = 0,
    required this.isOfficial,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'lifestyle': lifestyle,
      'authorId': authorId,
      'authorName': authorName,
      'timeSlots': timeSlots,
      'likes': likes,
      'usageCount': usageCount,
      'isOfficial': isOfficial,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Template.fromMap(Map<String, dynamic> map) {
    return Template(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      lifestyle: map['lifestyle'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      timeSlots: List<Map<String, dynamic>>.from(map['timeSlots'] ?? []),
      likes: map['likes'] ?? 0,
      usageCount: map['usageCount'] ?? 0,
      isOfficial: map['isOfficial'] ?? false,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class TemplateService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  static final CollectionReference _templatesCollection = 
      _firestore.collection('templates');

  // Upload a template to Firestore with validation
  static Future<bool> shareTemplate({
    required String title,
    required String description,
    required String category,
    required String lifestyle,
    required List<Map<String, dynamic>> timeSlots,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate input
      if (title.trim().isEmpty) {
        throw Exception('Template title cannot be empty');
      }
      
      if (description.trim().isEmpty) {
        throw Exception('Template description cannot be empty');
      }
      
      if (!categories.contains(category)) {
        throw Exception('Invalid category: $category');
      }
      
      if (!lifestyleTypes.contains(lifestyle)) {
        throw Exception('Invalid lifestyle type: $lifestyle');
      }
      
      if (timeSlots.isEmpty) {
        throw Exception('Template must have at least one time slot');
      }

      // Validate time slots
      for (int i = 0; i < timeSlots.length; i++) {
        final slot = timeSlots[i];
        if (slot['startTime'] == null || slot['endTime'] == null) {
          throw Exception('Time slot ${i + 1} is missing start or end time');
        }
        if (slot['label'] == null || slot['label'].toString().trim().isEmpty) {
          throw Exception('Time slot ${i + 1} must have a label');
        }
      }

      // Generate unique ID
      final docRef = _templatesCollection.doc();
      
      final template = Template(
        id: docRef.id,
        title: title,
        description: description,
        category: category,
        lifestyle: lifestyle,
        authorId: user.uid,
        authorName: user.displayName ?? user.email ?? 'Anonymous',
        timeSlots: timeSlots,
        likes: 0,
        isOfficial: false,
        createdAt: DateTime.now(),
      );

      await docRef.set(template.toMap());
      return true;
    } catch (e) {
      Logger.instance.error('Error sharing template: $e');
      return false;
    }
  }

  // Fetch templates from Firestore with optional filters
  static Future<List<Template>> getTemplates({
    String? category,
    String? lifestyle,
    String? searchQuery,
    int limit = 20,
  }) async {
    try {
      Query query = _templatesCollection
          .orderBy('createdAt', descending: true)
          .limit(limit);

      // Apply category filter if provided
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      // Apply lifestyle filter if provided
      if (lifestyle != null && lifestyle.isNotEmpty) {
        query = query.where('lifestyle', isEqualTo: lifestyle);
      }

      final querySnapshot = await query.get();
      List<Template> templates = querySnapshot.docs
          .map((doc) => Template.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Apply search filter locally (Firestore doesn't support complex text search)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        templates = templates.where((template) {
          return template.title.toLowerCase().contains(searchLower) ||
                 template.description.toLowerCase().contains(searchLower) ||
                 template.authorName.toLowerCase().contains(searchLower);
        }).toList();
      }

      return templates;
    } catch (e) {
      Logger.instance.error('Error fetching templates: $e');
      return [];
    }
  }

  // Get featured/official templates
  static Future<List<Template>> getFeaturedTemplates({int limit = 10}) async {
    try {
      final querySnapshot = await _templatesCollection
          .where('isOfficial', isEqualTo: true)
          .orderBy('likes', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Template.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Logger.instance.error('Error fetching featured templates: $e');
      return [];
    }
  }

  // Like a template
  static Future<bool> likeTemplate(String templateId) async {
    try {
      await _templatesCollection.doc(templateId).update({
        'likes': FieldValue.increment(1),
      });
      return true;
    } catch (e) {
      Logger.instance.error('Error liking template: $e');
      return false;
    }
  }

  // Unlike a template
  static Future<bool> unlikeTemplate(String templateId) async {
    try {
      await _templatesCollection.doc(templateId).update({
        'likes': FieldValue.increment(-1),
      });
      return true;
    } catch (e) {
      Logger.instance.error('Error unliking template: $e');
      return false;
    }
  }

  // Convert RoutineTimeSlot objects to Firestore-compatible map
  static List<Map<String, dynamic>> timeSlotsToMap(List<dynamic> timeSlots) {
    return timeSlots.map((slot) {
      return {
        'id': slot.id ?? '',
        'startAngle': slot.startAngle ?? 0.0,
        'endAngle': slot.endAngle ?? 0.0,
        'startTime': slot.startTime ?? '',
        'endTime': slot.endTime ?? '',
        'label': slot.label ?? '',
        'description': slot.description ?? '',
        'color': slot.color ?? 0xFF2196F3,
        'hasAlarm': slot.hasAlarm ?? false,
        'hasPreAlarm': slot.hasPreAlarm ?? false,
        'preAlarmMinutes': slot.preAlarmMinutes ?? 15,
        'snoozeEnabled': slot.snoozeEnabled ?? true,
        'snoozeDuration': slot.snoozeDuration ?? 10,
        'maxSnoozeCount': slot.maxSnoozeCount ?? 3,
        'createdAt': slot.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };
    }).toList();
  }

  // Get available categories for filtering
  static const List<String> categories = [
    'Productivity',
    'Health & Fitness',
    'Work & Career',
    'Education',
    'Lifestyle',
    'Self Care',
    'Family & Social',
    'Entertainment',
    'Custom',
  ];

  // Get available lifestyle types
  static const List<String> lifestyleTypes = [
    'Morning Person',
    'Night Owl',
    'Balanced',
  ];
}