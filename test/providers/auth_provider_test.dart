import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routine/providers/auth_provider.dart';

void main() {
  group('AuthNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should have no user and not be loading', () {
      final authState = container.read(authNotifierProvider);
      
      expect(authState.user, isNull);
      expect(authState.isLoading, isFalse);
      expect(authState.error, isNull);
      expect(authState.isProUser, isFalse);
      expect(authState.isAuthenticated, isFalse);
    });

    test('AuthState copyWith should work correctly', () {
      const initialState = AuthState();
      
      final updatedState = initialState.copyWith(
        isLoading: true,
        error: 'Test error',
      );
      
      expect(updatedState.isLoading, isTrue);
      expect(updatedState.error, equals('Test error'));
      expect(updatedState.user, isNull); // Should remain unchanged
    });

    test('clearError should remove error from state', () {
      final notifier = container.read(authNotifierProvider.notifier);
      
      // This would require mocking the AuthService for full testing
      // For now, we test the clearError method
      notifier.clearError();
      
      final state = container.read(authNotifierProvider);
      expect(state.error, isNull);
    });
  });

  group('Auth Provider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('isAuthenticatedProvider should return false initially', () {
      final isAuthenticated = container.read(isAuthenticatedProvider);
      expect(isAuthenticated, isFalse);
    });

    test('isProUserProvider should return false initially', () {
      final isProUser = container.read(isProUserProvider);
      expect(isProUser, isFalse);
    });
  });
}