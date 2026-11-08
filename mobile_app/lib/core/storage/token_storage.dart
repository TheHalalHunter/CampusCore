import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Conditional import — dart:html on web, stub on mobile
import 'token_storage_mobile.dart'
    if (dart.library.html) 'token_storage_web.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Token storage.
/// - Web: uses localStorage (persists across page refreshes)
/// - Mobile: uses flutter_secure_storage (Android Keystore / iOS Keychain)
///   Tokens are encrypted at rest — not accessible even on rooted devices
///   without the device PIN/biometric.
class TokenStorage {
  static const _accessKey  = 'cc_access_token';
  static const _refreshKey = 'cc_refresh_token';
  static const _userKey    = 'cc_user';

  // Android options: use EncryptedSharedPreferences backed by Android Keystore
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<void> saveAccessToken(String token) async {
    if (kIsWeb) {
      webSet(_accessKey, token);
    } else {
      await _secureStorage.write(key: _accessKey, value: token);
    }
  }

  Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      webSet(_refreshKey, token);
    } else {
      await _secureStorage.write(key: _refreshKey, value: token);
    }
  }

  Future<void> saveUser(String userJson) async {
    if (kIsWeb) {
      webSet(_userKey, userJson);
    } else {
      await _secureStorage.write(key: _userKey, value: userJson);
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) return webGet(_accessKey);
    return _secureStorage.read(key: _accessKey);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) return webGet(_refreshKey);
    return _secureStorage.read(key: _refreshKey);
  }

  Future<String?> getUser() async {
    if (kIsWeb) return webGet(_userKey);
    return _secureStorage.read(key: _userKey);
  }

  Future<void> clear() async {
    if (kIsWeb) {
      webRemove(_accessKey);
      webRemove(_refreshKey);
      webRemove(_userKey);
    } else {
      await _secureStorage.deleteAll();
    }
  }
}
