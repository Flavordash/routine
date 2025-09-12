import 'package:flutter/material.dart';

// App Constants
class AppConstants {
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusS = 6.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusRound = 50.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Elevations
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;

  // Icon Sizes
  static const double iconXS = 12.0;
  static const double iconS = 16.0;
  static const double iconM = 20.0;
  static const double iconL = 24.0;
  static const double iconXL = 32.0;

  // Default Colors (commonly used in the app)
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color primaryRed = Color(0xFFF44336);
  static const Color primaryPurple = Color(0xFF9C27B0);
  static const Color amber = Colors.amber;

  // Routine Slot Colors (based on the codebase)
  static const List<Color> routineColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFFF44336), // Red
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFF8BC34A), // Light Green
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFE91E63), // Pink
    Color(0xFF795548), // Brown
  ];

  // Template Categories (from TemplateService)
  static const List<String> templateCategories = [
    'Productivity',
    'Health & Fitness',
    'Work & Career',
    'Education',
    'Lifestyle',
    'Self Care',
    'Family & Social',
    'Entertainment',
  ];

  // Lifestyle Types (from TemplateService)
  static const List<String> lifestyleTypes = [
    'Morning Person',
    'Night Owl',
    'Balanced',
  ];

  // App Version and Build Info
  static const String appVersion = '1.0.0';
  static const String appName = 'Routine 24';

  // Default Alarm Settings
  static const int defaultPreAlarmMinutes = 15;
  static const int defaultSnoozeDuration = 10;
  static const int defaultMaxSnoozeCount = 3;

  // Dialog Constraints
  static const double dialogMaxWidth = 500.0;
  static const double dialogMaxHeight = 700.0;
  static const double dialogMinWidth = 300.0;
  static const double dialogMinHeight = 400.0;

  // Grid Settings
  static const int templateGridCrossAxisCount = 2;
  static const double templateGridAspectRatio = 1.2;
  static const double templateGridSpacing = 4.0;
  static const double templateGridMainSpacing = 6.0;
}