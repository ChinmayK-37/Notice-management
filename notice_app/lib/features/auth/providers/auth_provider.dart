import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notice_app/core/services/api_service.dart';
import 'package:notice_app/core/services/token_service.dart';
import 'package:notice_app/features/auth/data/auth_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final tokenServiceProvider = Provider<TokenService>((ref) => TokenService());

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    apiService: ref.read(apiServiceProvider),
    tokenService: ref.read(tokenServiceProvider),
  ),
);

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.isAdmin = false,
    this.error,
  });

  final bool isLoading;
  final bool isLoggedIn;
  final bool isAdmin;
  final String? error;

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    bool? isAdmin,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isAdmin: isAdmin ?? this.isAdmin,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService) : super(const AuthState());

  final AuthService _authService;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authService.login(email, password);
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        isAdmin: email.toLowerCase().contains('admin'),
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authService.register(email: email, password: password);
      state = state.copyWith(
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _authService.logout();
    state = state.copyWith(
      isLoading: false,
      isLoggedIn: false,
      isAdmin: false,
      clearError: true,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);
