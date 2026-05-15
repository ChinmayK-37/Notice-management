import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notice_app/core/services/api_service.dart';
import 'package:notice_app/core/services/token_service.dart';
import 'package:notice_app/core/utils/jwt_claims.dart';
import 'package:notice_app/features/auth/data/auth_service.dart';
import 'package:notice_app/features/auth/data/profile_service.dart';

final apiServiceProvider = Provider<ApiService>(
  (ref) => ApiService(tokenService: ref.watch(tokenServiceProvider)),
);

final tokenServiceProvider = Provider<TokenService>((ref) => TokenService());

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    apiService: ref.read(apiServiceProvider),
    tokenService: ref.read(tokenServiceProvider),
  ),
);

final profileServiceProvider = Provider<ProfileService>(
  (ref) => ProfileService(apiService: ref.read(apiServiceProvider)),
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
  AuthNotifier(this._authService, this._tokenService)
    : super(const AuthState(isLoading: true)) {
    unawaited(restoreSession());
  }

  final AuthService _authService;
  final TokenService _tokenService;

  Future<void> restoreSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final String? token = await _tokenService.getAccessToken();
      if (token == null || token.trim().isEmpty) {
        state = const AuthState(isLoading: false);
        return;
      }
      if (!JwtClaims.isValidAccessToken(token)) {
        await _tokenService.clearToken();
        state = const AuthState(isLoading: false);
        return;
      }
      state = AuthState(
        isLoading: false,
        isLoggedIn: true,
        isAdmin: JwtClaims.isAdmin(token),
      );
    } on Object {
      await _tokenService.clearToken();
      state = const AuthState(
        isLoading: false,
        error: 'Session could not be restored.',
      );
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authService.login(email, password);
      final String? token = await _tokenService.getAccessToken();
      if (token != null && JwtClaims.isValidAccessToken(token)) {
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          isAdmin: JwtClaims.isAdmin(token),
          clearError: true,
        );
      } else {
        await _tokenService.clearToken();
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: false,
          isAdmin: false,
          error: 'Login succeeded but the token was invalid.',
        );
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        isAdmin: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String department,
    required int year,
    required String? division,
    required String? batch,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
        department: department,
        year: year,
        division: division,
        batch: batch,
      );
      final String? token = await _tokenService.getAccessToken();
      if (token != null && JwtClaims.isValidAccessToken(token)) {
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          isAdmin: JwtClaims.isAdmin(token),
          clearError: true,
        );
      } else {
        await _tokenService.clearToken();
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: false,
          isAdmin: false,
          error: 'Registration succeeded but the token was invalid.',
        );
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        isAdmin: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.logout();
    } finally {
      state = const AuthState(
        isLoading: false,
        isLoggedIn: false,
        isAdmin: false,
      );
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(tokenServiceProvider),
  ),
);
