import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only record of recently viewed resources and questions.
///
/// Data is persisted in [SharedPreferences] as JSON lists and surfaced on the
/// home screen so students can jump back to what they were reading. Nothing
/// here is sent to the backend.
class ActivityStorage {
  static const String _resourcesKey = 'recent_resources';
  static const String _questionsKey = 'recent_questions';

  /// Max entries kept per category before older ones are dropped.
  static const int _maxPerList = 20;

  /// Max combined items returned by [getRecentActivity].
  static const int _maxActivity = 8;

  /// Prepend a viewed resource to the recent-resources list.
  static Future<void> addResourceView({
    required String id,
    required String title,
    required String type,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _readList(prefs, _resourcesKey);
    list.insert(0, {
      'id': id,
      'title': title,
      'type': type,
      'itemType': 'resource',
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (list.length > _maxPerList) {
      list.removeRange(_maxPerList, list.length);
    }
    await _saveList(prefs, _resourcesKey, list);
  }

  /// Prepend a viewed question to the recent-questions list.
  static Future<void> addQuestionView({
    required String id,
    required String title,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _readList(prefs, _questionsKey);
    list.insert(0, {
      'id': id,
      'title': title,
      'itemType': 'question',
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (list.length > _maxPerList) {
      list.removeRange(_maxPerList, list.length);
    }
    await _saveList(prefs, _questionsKey, list);
  }

  /// Merge both lists, newest first, capped at [_maxActivity] items.
  static Future<List<Map<String, dynamic>>> getRecentActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final merged = <Map<String, dynamic>>[
      ..._readList(prefs, _resourcesKey),
      ..._readList(prefs, _questionsKey),
    ];
    merged.sort((a, b) {
      final at = DateTime.tryParse(a['timestamp']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bt = DateTime.tryParse(b['timestamp']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at); // descending
    });
    return merged.take(_maxActivity).toList();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> _readList(
    SharedPreferences prefs,
    String key,
  ) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveList(
    SharedPreferences prefs,
    String key,
    List list,
  ) async {
    await prefs.setString(key, jsonEncode(list));
  }
}
