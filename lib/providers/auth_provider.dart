import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

// Provider for the AuthService instance
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider for the current user stream
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Provider for the current user (null if not authenticated)
final currentUserProvider = Provider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

// Provider for user authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Provider for user data
final userDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) return null;
  
  return await authService.getUserData();
});

// Provider for Pro status
final isProUserProvider = Provider<bool>((ref) {
  final userData = ref.watch(userDataProvider);
  return userData.when(
    data: (data) => data?['isPro'] ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Enhanced state management for auth operations
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? userData;
  final bool isProUser;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.userData,
    this.isProUser = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? userData,
    bool? isProUser,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userData: userData ?? this.userData,
      isProUser: isProUser ?? this.isProUser,
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _initializeAuth();
  }

  void _initializeAuth() {
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        state = state.copyWith(user: user, isLoading: true, error: null);
        try {
          final userData = await _authService.getUserData();
          state = state.copyWith(
            userData: userData,
            isProUser: userData?['isPro'] ?? false,
            isLoading: false,
          );
        } catch (error) {
          state = state.copyWith(
            error: error.toString(),
            isLoading: false,
          );
        }
      } else {
        state = const AuthState();
      }
    });
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      return true;
    } catch (error) {
      state = state.copyWith(
        error: error.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.registerWithEmailAndPassword(email, password);
      return true;
    } catch (error) {
      state = state.copyWith(
        error: error.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signOut();
      return true;
    } catch (error) {
      state = state.copyWith(
        error: error.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signInWithGoogle();
      return true;
    } catch (error) {
      state = state.copyWith(
        error: error.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> updateProStatus(bool isPro) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.updateUserProStatus(isPro);
      state = state.copyWith(
        isProUser: isPro,
        isLoading: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        error: error.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});