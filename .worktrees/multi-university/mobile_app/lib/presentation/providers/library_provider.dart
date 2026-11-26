import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/resource_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

// ─── Personal Library (server-side) ──────────────────────────────────────────

/// Fetches the logged-in user's saved resources from the backend.
final personalLibraryProvider = FutureProvider<List<ResourceModel>>((ref) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get(ApiConstants.library);
    final data = response.data['data'] ?? response.data;
    return (data as List)
        .map((r) => ResourceModel.fromJson(r as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});

// ─── Library actions ──────────────────────────────────────────────────────────

final libraryActionsProvider =
    NotifierProvider<LibraryActionsNotifier, void>(LibraryActionsNotifier.new);

class LibraryActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<bool> save(String resourceId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiConstants.library, data: {'resourceId': resourceId});
      ref.invalidate(personalLibraryProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remove(String resourceId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.delete(ApiConstants.libraryRemove(resourceId));
      ref.invalidate(personalLibraryProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ─── Bookmark (local in-memory toggle) ───────────────────────────────────────
// Also syncs with the server-side library when toggled.

final bookmarkProvider =
    NotifierProvider<BookmarkNotifier, Set<String>>(BookmarkNotifier.new);

class BookmarkNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String resourceId) {
    final current = Set<String>.from(state);
    if (current.contains(resourceId)) {
      current.remove(resourceId);
      // Remove from server-side library (best effort)
      ref.read(libraryActionsProvider.notifier).remove(resourceId);
    } else {
      current.add(resourceId);
      // Save to server-side library (best effort)
      ref.read(libraryActionsProvider.notifier).save(resourceId);
    }
    state = current;
  }

  bool isBookmarked(String resourceId) => state.contains(resourceId);
}
