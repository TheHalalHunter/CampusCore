import 'package:shared_preferences/shared_preferences.dart';

/// Token storage using SharedPreferences (works on Flutter Web via localStorage).
class TokenStorage {
  static const _accessKey  = 'campuscore_access_token';
  static const _refreshKey = 'campuscore_refresh_token';
  static const _userKey    = 'campuscore_user';

  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, accessToken);
    if (refreshToken != null) {
      await prefs.setString(_refreshKey, refreshToken);
    }
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  static Future<void> saveUser(String userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, userJson);
  }

  static Future<String?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userKey);
  }

  static Future<bool> get hasToken async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessKey) ?? '';
    return token.isNotEmpty;
  }
}
