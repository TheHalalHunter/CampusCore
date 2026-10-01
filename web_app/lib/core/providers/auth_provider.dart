import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';
import '../constants/api_constants.dart';

// ── User model ────────────────────────────────────────────────────────────────
class AppUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? avatarUrl;
  final int? reputationPoints;
  final String? level;
  final String? departmentId;

  const AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.avatarUrl,
    this.reputationPoints,
    this.level,
    this.departmentId,
  });

  String get fullName => '$firstName $lastName';
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty  ? lastName[0].toUpperCase()  : '';
    return '$f$l';
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id:               json['id']?.toString()        ?? '',
      email:            json['email']?.toString()      ?? '',
      firstName:        json['firstName']?.toString()  ?? '',
      lastName:         json['lastName']?.toString()   ?? '',
      role:             json['role']?.toString()        ?? 'student',
      avatarUrl:        json['avatarUrl']?.toString(),
      reputationPoints: json['reputationPoints'] as int?,
      level:            json['level']?.toString(),
      departmentId:     json['departmentId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'email': email, 'firstName': firstName,
    'lastName': lastName, 'role': role, 'avatarUrl': avatarUrl,
    'reputationPoints': reputationPoints, 'level': level,
    'departmentId': departmentId,
  };
}

// ── Auth state ────────────────────────────────────────────────────────────────
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;
  final bool initialized;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.initialized = false,
  });

  bool get isAuthenticated => user != null && initialized;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    bool? initialized,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user:        clearUser  ? null  : (user        ?? this.user),
      isLoading:   isLoading  ?? this.isLoading,
      error:       clearError ? null  : (error       ?? this.error),
      initialized: initialized ?? this.initialized,
    );
  }
}

// ── Auth notifier ─────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;

  AuthNotifier(this._api) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    // Try restoring from storage
    try {
      final token    = await TokenStorage.getAccessToken();
      final userJson = await TokenStorage.getUser();

      if (token != null && token.isNotEmpty && userJson != null) {
        final user = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        state = AuthState(user: user, initialized: true);

        // Refresh user data from API in background
        _refreshUser();
        return;
      }
    } catch (_) {}

    state = state.copyWith(initialized: true, clearUser: true);
  }

  Future<void> _refreshUser() async {
    try {
      final resp = await _api.get(ApiConstants.me);
      final data = resp.data['data'] as Map<String, dynamic>;
      final user = AppUser.fromJson(data);
      await TokenStorage.saveUser(jsonEncode(user.toJson()));
      state = state.copyWith(user: user);
    } catch (_) {
      // Silent fail — cached user is still valid
    }
  }

  Future<String?> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // 1. Firebase sign-in
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final firebaseToken = await credential.user?.getIdToken();

      if (firebaseToken == null) {
        state = state.copyWith(isLoading: false, error: 'Firebase token error');
        return 'Firebase token error';
      }

      // 2. Backend token exchange
      final resp = await _api.post(ApiConstants.login, data: {
        'idToken': firebaseToken,
      });

      final body = resp.data as Map<String, dynamic>;
      if (body['success'] != true) {
        state = state.copyWith(isLoading: false, error: body['message']?.toString() ?? 'Login failed');
        return body['message']?.toString() ?? 'Login failed';
      }

      final tokenData = body['data'] as Map<String, dynamic>;
      final accessToken  = tokenData['accessToken']?.toString()  ?? '';
      final refreshToken = tokenData['refreshToken']?.toString();
      final userData     = tokenData['user'] as Map<String, dynamic>? ?? {};

      // 3. Persist tokens + user
      await TokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      final user = AppUser.fromJson(userData);
      await TokenStorage.saveUser(jsonEncode(user.toJson()));

      state = AuthState(user: user, initialized: true);
      return null; // success
    } on FirebaseAuthException catch (e) {
      final msg = _firebaseMsg(e.code);
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    } catch (e) {
      final msg = 'Login failed. Please try again.';
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  /// Called by sign-up flow after it handles token exchange itself.
  void setUserDirectly(AppUser user) {
    state = AuthState(user: user, initialized: true);
  }

  Future<String?> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Web-specific Google sign-in
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final credential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      final firebaseToken = await credential.user?.getIdToken();

      if (firebaseToken == null) {
        state = state.copyWith(isLoading: false, error: 'Google sign-in failed. Try again.');
        return 'Google sign-in failed.';
      }

      final resp = await _api.post(ApiConstants.login, data: {
        'idToken':  firebaseToken,
        'fullName': credential.user?.displayName ?? '',
      });

      final body = resp.data as Map<String, dynamic>;
      if (body['success'] != true) {
        state = state.copyWith(isLoading: false, error: body['message']?.toString() ?? 'Login failed');
        return body['message']?.toString() ?? 'Login failed';
      }

      final tokenData    = body['data'] as Map<String, dynamic>;
      final accessToken  = tokenData['accessToken']?.toString()  ?? '';
      final refreshToken = tokenData['refreshToken']?.toString();
      final userData     = tokenData['user'] as Map<String, dynamic>? ?? {};

      await TokenStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      final user = AppUser.fromJson(userData);
      await TokenStorage.saveUser(jsonEncode(user.toJson()));

      state = AuthState(user: user, initialized: true);
      return null;
    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'popup-closed-by-user'
          ? null // user cancelled — not an error
          : 'Google sign-in failed: ${e.message}';
      state = state.copyWith(isLoading: false, error: msg, clearError: msg == null);
      return msg;
    } catch (e) {
      final msg = e.toString().contains('ServiceUnavailable') || e.toString().contains('503')
          ? 'Auth service temporarily unavailable. Please try again in a minute.'
          : 'Google sign-in failed. Please try again.';
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<String?> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await _api.patch(ApiConstants.updateProfile, data: {
        'fullName': '$firstName $lastName',
      });
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] != true) {
        state = state.copyWith(isLoading: false, error: body['message']?.toString() ?? 'Update failed');
        return body['message']?.toString() ?? 'Update failed';
      }
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final updated = AppUser.fromJson({...state.user!.toJson(), ...data});
      await TokenStorage.saveUser(jsonEncode(updated.toJson()));
      state = state.copyWith(user: updated, isLoading: false);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Update failed. Please try again.');
      return 'Update failed. Please try again.';
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await TokenStorage.clear();
    state = AuthState(initialized: true);
  }

  String _firebaseMsg(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'Your account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Login failed ($code). Please try again.';
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  return AuthNotifier(api);
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});
