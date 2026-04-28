import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/models/user_model.dart';
import '../repositories/auth_repository.dart';

// Single Supabase client provider — used by all feature repositories
final apiClientProvider = Provider<sb.SupabaseClient>((ref) => sb.Supabase.instance.client);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(apiClientProvider)),
);

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    bool? isLoading,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final sb.SupabaseClient _supabase;
  StreamSubscription? _sub;

  AuthNotifier(this._supabase) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _loadUser(session.user.id);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
    _sub = _supabase.auth.onAuthStateChange.listen((event) async {
      if (event.session != null) {
        await _loadUser(event.session!.user.id);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  Future<void> _loadUser(String userId) async {
    try {
      final data = await _supabase.from('users').select().eq('id', userId).single();
      final approvalStatus = data['approval_status'] as String?;
      final isActive = data['is_active'] as bool? ?? false;

      if (approvalStatus == 'PENDING' || !isActive) {
        // Not approved yet — sign out silently
        await _supabase.auth.signOut();
        return;
      }
      state = AuthState(
        status: AuthStatus.authenticated,
        user: UserModel.fromJson(data as Map<String, dynamic>),
      );
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      // onAuthStateChange triggers _loadUser which sets authenticated state
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.unauthenticated,
        error: _parseError(e),
      );
    }
  }

  Future<void> logout() async {
    state = const AuthState(status: AuthStatus.unauthenticated);
    await _supabase.auth.signOut();
  }

  String _parseError(dynamic e) {
    if (e is sb.AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login')) return 'Invalid email or password.';
      if (msg.contains('email not confirmed')) return 'Please confirm your email first.';
      return e.message;
    }
    return e.toString();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(apiClientProvider)),
);
