import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Custom Exception Classes
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException(String message) : super(message, code: 'network_error');
}

class AuthenticationException extends AppException {
  const AuthenticationException(String message, {String? code})
      : super(message, code: code);
}

class ValidationException extends AppException {
  const ValidationException(String message) : super(message, code: 'validation_error');
}

// Error Handler Utility
class ErrorHandler {
  // Convert Firebase Auth errors to user-friendly messages
  static String handleFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No user found for that email address.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return error.message ?? 'An authentication error occurred.';
    }
  }

  // Convert Firestore errors to user-friendly messages
  static String handleFirestoreError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'unavailable':
        return 'The service is currently unavailable. Please try again later.';
      case 'deadline-exceeded':
        return 'The operation timed out. Please try again.';
      case 'not-found':
        return 'The requested document was not found.';
      case 'already-exists':
        return 'The document already exists.';
      case 'resource-exhausted':
        return 'Quota exceeded. Please try again later.';
      case 'failed-precondition':
        return 'The operation was rejected because of a conflict.';
      case 'aborted':
        return 'The operation was aborted due to a conflict.';
      case 'out-of-range':
        return 'The operation was attempted past the valid range.';
      case 'unimplemented':
        return 'The operation is not implemented or supported.';
      case 'internal':
        return 'Internal error. Please try again later.';
      case 'data-loss':
        return 'Unrecoverable data loss or corruption.';
      case 'unauthenticated':
        return 'You must be authenticated to perform this action.';
      default:
        return error.message ?? 'A database error occurred.';
    }
  }

  // Generic error handler
  static String handleGenericError(dynamic error) {
    if (error is FirebaseAuthException) {
      return handleFirebaseAuthError(error);
    } else if (error is FirebaseException) {
      return handleFirestoreError(error);
    } else if (error is AppException) {
      return error.message;
    } else {
      return error.toString();
    }
  }

  // Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Show warning snackbar
  static void showWarningSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Safe async operation wrapper
  static Future<T?> safeAsyncCall<T>({
    required Future<T> Function() operation,
    String? errorMessage,
    Function(dynamic error)? onError,
  }) async {
    try {
      return await operation();
    } catch (error) {
      final message = errorMessage ?? handleGenericError(error);
      onError?.call(error);
      
      // Log error for debugging (can be replaced with proper logging)
      debugPrint('Safe async call error: $message');
      debugPrint('Original error: $error');
      
      return null;
    }
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email);
  }

  // Validate password strength
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Validate routine slot name
  static String? validateRoutineName(String name) {
    if (name.isEmpty) {
      return 'Routine name is required';
    }
    if (name.length > 50) {
      return 'Routine name must be less than 50 characters';
    }
    return null;
  }
}