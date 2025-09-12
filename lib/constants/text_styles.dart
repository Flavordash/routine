import 'package:flutter/material.dart';

// Text Style Constants
class AppTextStyles {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );

  // Caption and Labels
  static const TextStyle caption = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.normal,
    height: 1.2,
  );

  static const TextStyle label = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 9.0,
    fontWeight: FontWeight.w500,
    height: 1.1,
  );

  static const TextStyle micro = TextStyle(
    fontSize: 6.0,
    fontWeight: FontWeight.bold,
    height: 1.0,
  );

  // Special Styles
  static const TextStyle button = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  // Template Card Styles (specific to the app)
  static const TextStyle templateTitle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle templateDescription = TextStyle(
    fontSize: 11.0,
    height: 1.2,
  );

  static const TextStyle templateAuthor = TextStyle(
    fontSize: 9.0,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle officialBadge = TextStyle(
    fontSize: 6.0,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle usageCount = TextStyle(
    fontSize: 9.0,
  );

  // Dialog Styles
  static const TextStyle dialogTitle = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle dialogSubtitle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
  );

  // Error and Status Styles
  static const TextStyle error = TextStyle(
    fontSize: 14.0,
    color: Colors.red,
  );

  static const TextStyle success = TextStyle(
    fontSize: 14.0,
    color: Colors.green,
  );

  static const TextStyle warning = TextStyle(
    fontSize: 14.0,
    color: Colors.orange,
  );

  // Helper methods for dynamic colors
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(color: style.color?.withValues(alpha: opacity));
  }
}