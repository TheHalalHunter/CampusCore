import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Thin wrapper around Hive for offline caching of API responses.
///
/// Usage:
///   await OfflineCache.init();
///   await OfflineCache.put('resources_course_123', jsonList);
///   final data = OfflineCache.get<List>('resources_course_123');
class OfflineCache {
  static const String _boxName = 'campuscore_cache';
  static const String _metaBoxName = 'campuscore_cache_meta';

  /// Must be called once at app startup before any cache reads/writes.
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_boxName);
    await Hive.openBox<String>(_metaBoxName);
  }

  static Box<String> get _box => Hive.box<String>(_boxName);
  static Box<String> get _meta => Hive.box<String>(_metaBoxName);

  /// Cache [value] under [key]. Stores as JSON string.
  static Future<void> put(String key, dynamic value) async {
    await _box.put(key, jsonEncode(value));
    await _meta.put(key, DateTime.now().toIso8601String());
  }

  /// Retrieve cached value for [key].
  /// Returns null if not cached.
  static T? get<T>(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    return jsonDecode(raw) as T?;
  }

  /// Returns when the key was last cached, or null if not cached.
  static DateTime? cachedAt(String key) {
    final ts = _meta.get(key);
    if (ts == null) return null;
    return DateTime.tryParse(ts);
  }

  /// True if the cache entry exists and is fresher than [maxAge].
  static bool isFresh(String key, {Duration maxAge = const Duration(hours: 24)}) {
    final ts = cachedAt(key);
    if (ts == null) return false;
    return DateTime.now().difference(ts) < maxAge;
  }

  /// Remove a single entry.
  static Future<void> remove(String key) async {
    await _box.delete(key);
    await _meta.delete(key);
  }

  /// Clear all cached data.
  static Future<void> clear() async {
    await _box.clear();
    await _meta.clear();
  }
}
