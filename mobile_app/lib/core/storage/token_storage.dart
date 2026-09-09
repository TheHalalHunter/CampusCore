import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditional import — dart:html on web, stub on mobile
import 'token_storage_mobile.dart'
    if (dart.library.html) 'token_storage_web.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Token storage.
/// - Web: uses localStorage (persists across page refreshes)
/// - Mobile: uses SharedPreferences
class TokenStorage {
  static const _accessKey = 'cc_access_token';
  static const _refreshKey = 'cc_refresh_token';

  Future<void> saveAccessToken(String token) async {
    if (kIsWeb) {
      webSet(_accessKey, token);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessKey, token);
    }
  }

  Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      webSet(_refreshKey, token);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshKey, token);
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) return webGet(_accessKey);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) return webGet(_refreshKey);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  Future<void> clear() async {
    if (kIsWeb) {
      webRemove(_accessKey);
      webRemove(_refreshKey);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessKey);
      await prefs.remove(_refreshKey);
    }
  }
}
