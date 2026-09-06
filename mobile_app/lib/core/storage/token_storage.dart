import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Token storage that uses SharedPreferences on mobile and an in-memory
/// fallback on web (real localStorage via dart:html is web-only and breaks
/// the Android build, so we use a simple in-memory map for web in the APK).
class TokenStorage {
  static const _accessKey = 'cc_access_token';
  static const _refreshKey = 'cc_refresh_token';

  // In-memory fallback for web (not persisted across page reloads in this APK)
  static final Map<String, String> _memoryStore = {};

  Future<void> saveAccessToken(String token) async {
    if (kIsWeb) {
      _memoryStore[_accessKey] = token;
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessKey, token);
    }
  }

  Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      _memoryStore[_refreshKey] = token;
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshKey, token);
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) return _memoryStore[_accessKey];
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) return _memoryStore[_refreshKey];
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  Future<void> clear() async {
    if (kIsWeb) {
      _memoryStore.remove(_accessKey);
      _memoryStore.remove(_refreshKey);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessKey);
      await prefs.remove(_refreshKey);
    }
  }
}
