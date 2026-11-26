import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ConversationStorage {
  static const String _key = 'ai_conversations';
  static const String _lastKey = 'ai_last_conversation_id';

  static Future<List<Map<String, dynamic>>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<Map<String, dynamic>> conversations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(conversations));
    } catch (_) {}
  }

  static Future<void> saveConversation(Map<String, dynamic> conv) async {
    final all = await loadAll();
    final idx = all.indexWhere((c) => c['id'] == conv['id']);
    if (idx >= 0) {
      all[idx] = conv;
    } else {
      all.add(conv);
    }
    all.sort((a, b) {
      final at = DateTime.tryParse(a['updatedAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = DateTime.tryParse(b['updatedAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    await saveAll(all);
  }

  static Future<void> deleteConversation(String id) async {
    final all = await loadAll();
    all.removeWhere((c) => c['id'] == id);
    await saveAll(all);
  }

  static Future<void> saveLastId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastKey, id);
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> loadLast() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getString(_lastKey);
      if (lastId == null) return null;
      final all = await loadAll();
      final found = all.where((c) => c['id'] == lastId);
      return found.isNotEmpty ? found.first : (all.isNotEmpty ? all.first : null);
    } catch (_) {
      return null;
    }
  }
}
