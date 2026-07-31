import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
    return const AsyncValue.loading();
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _exchangeFirebaseToken(credential.user!);
      state = AsyncValue.data(credential.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        state = const AsyncValue.data(null);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      await _exchangeFirebaseToken(userCredential.user!);
      state = AsyncValue.data(userCredential.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    ref.read(tokenStorageProvider).clear();
    state = const AsyncValue.data(null);
  }

  /// Sends the Firebase ID token to the backend and stores the platform JWT.
  Future<void> _exchangeFirebaseToken(User firebaseUser) async {
    final idToken = await firebaseUser.getIdToken();
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.post(ApiConstants.login, data: {'idToken': idToken});
    final tokenStorage = ref.read(tokenStorageProvider);
    await tokenStorage.saveAccessToken(response.data['data']['accessToken']);
    await tokenStorage.saveRefreshToken(response.data['data']['refreshToken']);
  }
}
