import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/resource_model.dart';

// ─── Bookmarks (local state only) ────────────────────────────────────────────
// The personal library is kept in memory as a set of bookmarked resource IDs.
// Full server-side persistence will be wired up once the /personal-library
// backend endpoint is implemented.

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
  }

  bool isBookmarked(String resourceId) => state.contains(resourceId);
}

// ─── Personal Library (bookmarked resources) ─────────────────────────────────
// Derives the list of saved resources from the resources cache + bookmark IDs.
// Kept as a separate provider so the UI can consume it independently.

final personalLibraryProvider =
    Provider<List<ResourceModel>>((ref) {
  // The library screen should pass the full resource list from
  // resourcesByCourseProvider and filter by bookmarked IDs here.
  // Until the screen wires in the resource list, this returns empty.
  return const [];
});
