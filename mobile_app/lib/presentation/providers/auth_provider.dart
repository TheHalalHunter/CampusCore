import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../core/constants/api_constants.dart';

// Expose the current Firebase user state
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// AuthNotifier manages sign-in, sign-up, sign-out
final authProvider = NotifierProvider<AuthNotifier, AsyncValue<User?>>(AuthNotifier.new);

class AuthNotifier extends Notifier<AsyncValue<User?>> {
  @override
  AsyncValue<User?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      // Step 1: Sign in with Firebase
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Step 2: Exchange Firebase token for platform JWT (best effort)
      await _exchangeFirebaseToken(credential.user!);

      state = AsyncValue.data(credential.user);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Try again later.';
          break;
        default:
          message = e.message ?? 'Sign in failed. Please try again.';
      }
      state = AsyncValue.error(message, StackTrace.current);
      rethrow;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // On web — use popup instead of redirect
        final provider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        // On mobile — use google_sign_in package
        // ignore: depend_on_referenced_packages
        final googleSignIn = await _mobileGoogleSignIn();
        if (googleSignIn == null) {
          state = const AsyncValue.data(null);
          return;
        }
        userCredential = googleSignIn;
      }

      await _exchangeFirebaseToken(userCredential.user!);
      state = AsyncValue.data(userCredential.user);
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      rethrow;
    }
  }

  Future<UserCredential?> _mobileGoogleSignIn() async {
    try {
      // Dynamic import to avoid web compilation issues
      final googleSignIn = await FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider());
      return googleSignIn;
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    ref.read(tokenStorageProvider).clear();
    state = const AsyncValue.data(null);
  }

  /// Exchanges Firebase ID token for platform JWT.
  /// Fails silently if backend is unavailable — Firebase auth still works.
  Future<void> _exchangeFirebaseToken(User firebaseUser) async {
    try {
      final idToken = await firebaseUser.getIdToken();
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        ApiConstants.login,
        data: {'idToken': idToken},
      );
      final tokenStorage = ref.read(tokenStorageProvider);
      await tokenStorage.saveAccessToken(response.data['data']['accessToken']);
      await tokenStorage.saveRefreshToken(response.data['data']['refreshToken']);
    } catch (e) {
      // Backend unavailable — Firebase auth succeeded but platform JWT not stored
      // App will work in limited mode until backend is reachable
      print('Backend token exchange failed: $e');
    }
  }
}
