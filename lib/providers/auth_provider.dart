/// ============================================================
/// auth_provider.dart  (نسخة Supabase)
/// يستبدل SecureStorage + DioToken بـ Supabase Auth تلقائياً
/// ============================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb hide Provider;

import '../core/supabase/supabase_service.dart';
import '../models/user.dart';

// ────────────────────────────────────────────────────────────
// Auth State
// ────────────────────────────────────────────────────────────
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final User?     user;
  final String?   error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User?       user,
    String?     error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user:   user   ?? this.user,
      error:  error,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading        => status == AuthStatus.loading;
}

// ────────────────────────────────────────────────────────────
// Auth Notifier
// ────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService _service;

  AuthNotifier(this._service) : super(const AuthState()) {
    _init();
  }

  // ---- تحقق من وجود جلسة نشطة عند فتح التطبيق ----
  Future<void> _init() async {
    state = state.copyWith(status: AuthStatus.loading);

    final session = sb.Supabase.instance.client.auth.currentSession;
    try {
      final test = await sb.Supabase.instance.client
          .from('profiles')
          .select()
          .limit(1);

      print("DB TEST SUCCESS: $test");
    } catch (e) {
      print("DB ERROR: $e");
    }
    if (session != null) {
      try {
        final profile = await _service.getCurrentUserProfile();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user:   profile,
        );
        return;
      } catch (_) {}
    }
    state = state.copyWith(status: AuthStatus.unauthenticated);

    // ---- مراقبة تغييرات الجلسة في الوقت الحقيقي ----
    sb.Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event   = data.event;
      final session = data.session;

      if (event == sb.AuthChangeEvent.signedIn && session != null) {
        final profile = await _service.getCurrentUserProfile();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user:   profile,
        );
      } else if (event == sb.AuthChangeEvent.signedOut ||
                 event == sb.AuthChangeEvent.tokenRefreshed && session == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  // ---- تسجيل الدخول ----
  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      await _service.login(email, password);
      final profile = await _service.getCurrentUserProfile();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user:   profile,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error:  e.toString(),
      );
      return false;
    }
  }

  // ---- إنشاء حساب ----
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String userType,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      await _service.register(
        email:    email,
        password: password,
        name:     name,
        userType: userType,
      );
      final profile = await _service.getCurrentUserProfile();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user:   profile,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error:  e.toString(),
      );
      return false;
    }
  }

  // ---- تسجيل الخروج ----
  Future<void> logout() async {
    await _service.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  // ---- تحديث البروفايل ----
  Future<void> refreshProfile() async {
    final profile = await _service.getCurrentUserProfile();
    if (profile != null) {
      state = state.copyWith(user: profile);
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

// ────────────────────────────────────────────────────────────
// Providers
// ────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return AuthNotifier(service);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final userTypeProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).user?.userType;
});
