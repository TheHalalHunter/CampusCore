import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/resource_model.dart';
import '../../core/network/api_client.dart';

// ─── Personal Library (saved resources) ──────────────────────────────────────

final personalLibraryProvider =
    FutureProvider<List<ResourceModel>>((ref) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get('/personal-library');
    final data = response.data['data'] ?? response.data;
    return (data as List).map((r) => ResourceModel.fromJson(r)).toList();
  } catch (_) {
    return [];
  }
});

// ─── Bookmarks (local + synced) ───────────────────────────────────────────────

final bookmarkedIdsProvider = StateProvider<Set<String>>((ref) => {});

final bookmarkProvider =
    NotifierProvider<BookmarkNotifier, Set<String>>(BookmarkNotifier.new);

class BookmarkNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String resourceId) {
    final current = Set<String>.from(state);
    if (current.contains(resourceId)) {
      current.remove(resourceId);
    } else {
      current.add(resourceId);
    }
    state = current;
    _sync(resourceId, current.contains(resourceId));
  }

  bool isBookmarked(String resourceId) => state.contains(resourceId);

  Future<void> _sync(String resourceId, bool add) async {
    try {
      final api = ref.read(apiClientProvider);
      if (add) {
        await api.post('/personal-library', data: {'resourceId': resourceId});
      } else {
        await api.delete('/personal-library/$resourceId');
      }
    } catch (_) {
      // Sync failed — local state is still updated
    }
  }
}
