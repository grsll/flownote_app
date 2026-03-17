import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flownote/core/error/failures.dart';
import 'package:flownote/core/providers/repository_providers.dart';
import 'package:flownote/features/authentication/domain/repositories/auth_repository.dart';
import 'package:flownote/models/user_model.dart';

// ── Auth Status ────────────────────────────────────────────────────────────────
enum AuthStatus { unknown, authenticated, unauthenticated }

// ── Auth State ─────────────────────────────────────────────────────────────────
class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final Failure?   failure;
  final bool       isLoading;

  const AuthState({
    this.status    = AuthStatus.unknown,
    this.user,
    this.failure,
    this.isLoading = false,
  });

  String? get errorMessage => failure?.message;

  AuthState copyWith({
    AuthStatus? status,
    UserModel?  user,
    Failure?    failure,
    bool?       isLoading,
    bool        clearFailure = false,
  }) {
    return AuthState(
      status:    status    ?? this.status,
      user:      user      ?? this.user,
      failure:   clearFailure ? null : (failure ?? this.failure),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ── Auth Notifier ──────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  StreamSubscription<UserModel?>? _authSub;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSub = _repository.authStateChanges.listen((user) {
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final (failure, user) = await _repository.login(email: email, password: password);
    if (failure != null) {
      state = state.copyWith(isLoading: false, failure: failure);
      return false;
    }
    state = AuthState(status: AuthStatus.authenticated, user: user);
    return true;
  }

  // ── Register ───────────────────────────────────────────────────────────────

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final (failure, user) = await _repository.register(
      name:     name,
      email:    email,
      password: password,
    );
    if (failure != null) {
      state = state.copyWith(isLoading: false, failure: failure);
      return false;
    }
    state = AuthState(status: AuthStatus.authenticated, user: user);
    return true;
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final (failure, user) = await _repository.signInWithGoogle();
    if (failure != null) {
      state = state.copyWith(isLoading: false, failure: failure);
      return false;
    }
    if (user == null) {
      // User cancelled — no error, just stop loading
      state = state.copyWith(isLoading: false);
      return false;
    }
    state = AuthState(status: AuthStatus.authenticated, user: user);
    return true;
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  // ── Update Profile ─────────────────────────────────────────────────────────

  Future<bool> updateProfile({
    String? name,
    String? avatarUrl,
    String? currency,
    String? language,
    UserSettings? settings,
  }) async {
    final failure = await _repository.updateProfile(
      name:      name,
      avatarUrl: avatarUrl,
      currency:  currency,
      language:  language,
      settings:  settings,
    );
    if (failure != null) {
      state = state.copyWith(failure: failure);
      return false;
    }
    // Refresh user in state
    if (state.user != null) {
      state = state.copyWith(
        user: state.user!.copyWith(
          name:      name,
          avatarUrl: avatarUrl,
          currency:  currency,
          language:  language,
          settings:  settings,
        ),
        clearFailure: true,
      );
    }
    return true;
  }

  // ── Utils ──────────────────────────────────────────────────────────────────

  void clearError() => state = state.copyWith(clearFailure: true);

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

// ── Providers ──────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

/// Convenience: current signed-in user (or null)
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

/// Convenience: is user authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
});
