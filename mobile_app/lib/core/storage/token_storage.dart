import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

class TokenStorage {
  static const _accessKey = 'cc_access_token';
  static const _refreshKey = 'cc_refresh_token';

  // ─── Write ─────────────────────────────────────────────────────────────────

  Future<void> saveAccessToken(String token) async {
    if (kIsWeb) {
      html.window.localStorage[_accessKey] = token;
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessKey, token);
    }
  }

  Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      html.window.localStorage[_refreshKey] = token;
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshKey, token);
    }
  }

  // ─── Read ───────────────────────────────────────────────────────────────────

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      return html.window.localStorage[_accessKey];
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      return html.window.localStorage[_refreshKey];
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  // ─── Clear ──────────────────────────────────────────────────────────────────

  Future<void> clear() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_accessKey);
      html.window.localStorage.remove(_refreshKey);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessKey);
      await prefs.remove(_refreshKey);
    }
  }
}
