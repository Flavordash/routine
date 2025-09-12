import 'package:flutter_test/flutter_test.dart';
import 'package:routine/utils/validation_utils.dart';

void main() {
  group('ValidationUtils Email Tests', () {
    test('should return null for valid email', () {
      expect(ValidationUtils.validateEmail('test@example.com'), isNull);
      expect(ValidationUtils.validateEmail('user.name+tag@domain.co.uk'), isNull);
    });

    test('should return error for invalid email', () {
      expect(ValidationUtils.validateEmail(''), isNotNull);
      expect(ValidationUtils.validateEmail('invalid-email'), isNotNull);
      expect(ValidationUtils.validateEmail('test@'), isNotNull);
      expect(ValidationUtils.validateEmail('@domain.com'), isNotNull);
    });

    test('should return error for null email', () {
      expect(ValidationUtils.validateEmail(null), isNotNull);
    });
  });

  group('ValidationUtils Password Tests', () {
    test('should return null for valid password', () {
      expect(ValidationUtils.validatePassword('Password123'), isNull);
      expect(ValidationUtils.validatePassword('MySecurePass1'), isNull);
    });

    test('should return error for password too short', () {
      expect(ValidationUtils.validatePassword('Pass1'), isNotNull);
    });

    test('should return error for password without uppercase', () {
      expect(ValidationUtils.validatePassword('password123'), isNotNull);
    });

    test('should return error for password without lowercase', () {
      expect(ValidationUtils.validatePassword('PASSWORD123'), isNotNull);
    });

    test('should return error for password without numbers', () {
      expect(ValidationUtils.validatePassword('Password'), isNotNull);
    });

    test('should return error for empty/null password', () {
      expect(ValidationUtils.validatePassword(''), isNotNull);
      expect(ValidationUtils.validatePassword(null), isNotNull);
    });
  });

  group('ValidationUtils Routine Name Tests', () {
    test('should return null for valid routine name', () {
      expect(ValidationUtils.validateRoutineName('Morning Routine'), isNull);
      expect(ValidationUtils.validateRoutineName('Work'), isNull);
    });

    test('should return error for empty routine name', () {
      expect(ValidationUtils.validateRoutineName(''), isNotNull);
      expect(ValidationUtils.validateRoutineName(null), isNotNull);
      expect(ValidationUtils.validateRoutineName('   '), isNotNull);
    });

    test('should return error for routine name too long', () {
      expect(ValidationUtils.validateRoutineName('A' * 31), isNotNull);
    });
  });

  group('ValidationUtils Time Tests', () {
    test('should return null for valid time format', () {
      expect(ValidationUtils.validateTime('09:30'), isNull);
      expect(ValidationUtils.validateTime('23:59'), isNull);
      expect(ValidationUtils.validateTime('00:00'), isNull);
    });

    test('should return error for invalid time format', () {
      expect(ValidationUtils.validateTime('25:00'), isNotNull);
      expect(ValidationUtils.validateTime('12:60'), isNotNull);
      expect(ValidationUtils.validateTime('9:30'), isNotNull); // Should be 09:30
      expect(ValidationUtils.validateTime('invalid'), isNotNull);
    });
  });

  group('ValidationUtils Time Range Tests', () {
    test('should return null for valid time range', () {
      expect(ValidationUtils.validateTimeRange('09:00', '17:00'), isNull);
      expect(ValidationUtils.validateTimeRange('23:30', '23:59'), isNull);
    });

    test('should return error when start time equals or after end time', () {
      expect(ValidationUtils.validateTimeRange('17:00', '09:00'), isNotNull);
      expect(ValidationUtils.validateTimeRange('12:00', '12:00'), isNotNull);
    });

    test('should return null for null times (handled by individual validators)', () {
      expect(ValidationUtils.validateTimeRange(null, null), isNull);
      expect(ValidationUtils.validateTimeRange('09:00', null), isNull);
    });
  });

  group('ValidationUtils Number Tests', () {
    test('should return null for valid positive numbers', () {
      expect(ValidationUtils.validatePositiveNumber('5', 'Duration'), isNull);
      expect(ValidationUtils.validatePositiveNumber('100', 'Count'), isNull);
    });

    test('should return error for invalid numbers', () {
      expect(ValidationUtils.validatePositiveNumber('0', 'Duration'), isNotNull);
      expect(ValidationUtils.validatePositiveNumber('-5', 'Duration'), isNotNull);
      expect(ValidationUtils.validatePositiveNumber('abc', 'Duration'), isNotNull);
      expect(ValidationUtils.validatePositiveNumber('', 'Duration'), isNotNull);
    });

    test('should respect min/max constraints', () {
      expect(ValidationUtils.validatePositiveNumber('5', 'Duration', min: 10), isNotNull);
      expect(ValidationUtils.validatePositiveNumber('15', 'Duration', max: 10), isNotNull);
      expect(ValidationUtils.validatePositiveNumber('10', 'Duration', min: 5, max: 15), isNull);
    });
  });
}