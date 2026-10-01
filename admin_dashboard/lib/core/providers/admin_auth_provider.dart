import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_client.dart';

class AdminAuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AdminAuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  AdminAuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AdminAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  AdminAuthNotifier() : super(const AdminAuthState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('admin_token');
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(isAuthenticated: true);
    }
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // 1. Firebase sign-in
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      final firebaseToken = await credential.user?.getIdToken();
      if (firebaseToken == null) {
        state = state.copyWith(isLoading: false, error: 'Firebase token error.');
        return 'Firebase token error.';
      }

      // 2. Backend token exchange
      final resp = await adminApi.post('/auth/login', data: {'idToken': firebaseToken});
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] != true) {
        final msg = body['message']?.toString() ?? 'Login failed.';
        state = state.copyWith(isLoading: false, error: msg);
        return msg;
      }

      final tokenData = body['data'] as Map<String, dynamic>;
      final user = tokenData['user'] as Map<String, dynamic>? ?? {};
      final role = user['role']?.toString() ?? '';

      // 3. Role check
      if (role != 'admin') {
        await FirebaseAuth.instance.signOut();
        const msg = 'Access denied. Admin accounts only.';
        state = state.copyWith(isLoading: false, error: msg);
        return msg;
      }

      // 4. Persist token
      final accessToken = tokenData['accessToken']?.toString() ?? '';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_token', accessToken);

      state = state.copyWith(isAuthenticated: true, isLoading: false);
      return null; // success
    } on FirebaseAuthException catch (e) {
      final msg = _firebaseMsg(e.code);
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    } catch (e) {
      const msg = 'Sign in failed. Please try again.';
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
    state = const AdminAuthState();
  }

  String _firebaseMsg(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'Account disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return 'Sign in failed ($code).';
    }
  }
}

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>(
  (_) => AdminAuthNotifier(),
);
