import 'package:flutter/material.dart';

class ValidationUtils {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Display name validation
  static String? validateDisplayName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Display name is required';
    }
    
    if (value.length < 2) {
      return 'Display name must be at least 2 characters long';
    }
    
    if (value.length > 50) {
      return 'Display name must be less than 50 characters';
    }
    
    // Only allow letters, numbers, spaces, and common special characters
    if (!RegExp(r'^[a-zA-Z0-9\s\-_.]+$').hasMatch(value)) {
      return 'Display name contains invalid characters';
    }
    
    return null;
  }

  // Routine name validation
  static String? validateRoutineName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Routine name is required';
    }
    
    if (value.isEmpty) {
      return 'Routine name cannot be empty';
    }
    
    if (value.length > 30) {
      return 'Routine name must be less than 30 characters';
    }
    
    // Remove leading/trailing whitespace for validation
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Routine name cannot be only whitespace';
    }
    
    return null;
  }

  // Time slot label validation
  static String? validateTimeSlotLabel(String? value) {
    if (value == null || value.isEmpty) {
      return 'Label is required';
    }
    
    if (value.length > 25) {
      return 'Label must be less than 25 characters';
    }
    
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Label cannot be only whitespace';
    }
    
    return null;
  }

  // Time slot description validation
  static String? validateTimeSlotDescription(String? value) {
    // Description is optional, so null/empty is valid
    if (value == null || value.isEmpty) {
      return null;
    }
    
    if (value.length > 100) {
      return 'Description must be less than 100 characters';
    }
    
    return null;
  }

  // Time validation (ensures proper time format)
  static String? validateTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Time is required';
    }
    
    // Check for HH:MM format
    if (!RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value)) {
      return 'Enter a valid time (HH:MM)';
    }
    
    return null;
  }

  // Number validation (for duration, snooze count, etc.)
  static String? validatePositiveNumber(String? value, String fieldName, {int? min, int? max}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    final number = int.tryParse(value);
    if (number == null) {
      return 'Enter a valid number for $fieldName';
    }
    
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    
    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }
    
    if (max != null && number > max) {
      return '$fieldName must be at most $max';
    }
    
    return null;
  }

  // Validate time range (start time should be before end time)
  static String? validateTimeRange(String? startTime, String? endTime) {
    if (startTime == null || endTime == null) {
      return null; // Individual time validation will handle null values
    }
    
    // Parse times
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    
    if (startParts.length != 2 || endParts.length != 2) {
      return null; // Individual time validation will handle format issues
    }
    
    final startHour = int.tryParse(startParts[0]);
    final startMinute = int.tryParse(startParts[1]);
    final endHour = int.tryParse(endParts[0]);
    final endMinute = int.tryParse(endParts[1]);
    
    if (startHour == null || startMinute == null || endHour == null || endMinute == null) {
      return null; // Individual time validation will handle parsing issues
    }
    
    final startTotalMinutes = startHour * 60 + startMinute;
    final endTotalMinutes = endHour * 60 + endMinute;
    
    if (startTotalMinutes >= endTotalMinutes) {
      return 'Start time must be before end time';
    }
    
    return null;
  }

  // Generic required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '$fieldName cannot be only whitespace';
    }
    
    return null;
  }

  // Validate search query (optional but with length limit)
  static String? validateSearchQuery(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Search is optional
    }
    
    if (value.length > 100) {
      return 'Search query must be less than 100 characters';
    }
    
    return null;
  }

  // Phone number validation (optional, international format)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone number is often optional
    }
    
    // Remove all non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length < 10) {
      return 'Phone number must have at least 10 digits';
    }
    
    if (digitsOnly.length > 15) {
      return 'Phone number must have at most 15 digits';
    }
    
    return null;
  }

  // Validate form with multiple fields
  static bool validateForm(GlobalKey<FormState> formKey) {
    return formKey.currentState?.validate() ?? false;
  }

  // Helper method to combine multiple validators
  static String? Function(String?) combineValidators(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }
}

// Form field validation mixin for consistent validation across widgets
mixin FormValidationMixin {
  String? validateEmail(String? value) => ValidationUtils.validateEmail(value);
  String? validatePassword(String? value) => ValidationUtils.validatePassword(value);
  String? validateDisplayName(String? value) => ValidationUtils.validateDisplayName(value);
  String? validateRoutineName(String? value) => ValidationUtils.validateRoutineName(value);
  String? validateTimeSlotLabel(String? value) => ValidationUtils.validateTimeSlotLabel(value);
  String? validateRequired(String? value, String fieldName) => ValidationUtils.validateRequired(value, fieldName);
  bool validateForm(GlobalKey<FormState> formKey) => ValidationUtils.validateForm(formKey);
}