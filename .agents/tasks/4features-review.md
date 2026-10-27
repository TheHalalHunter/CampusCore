# Leaderboard, Personal Library, AI Chat History, Homepage Redesign

Four features shipped in a single commit (d47b8ac): a leaderboard screen, a personal library for saved resources, AI conversation history, and a redesigned homepage dashboard. All four have working backend and Flutter counterparts. The core architecture — TypeORM repositories, `@Public()` / `@CurrentUser()` decorators, `FutureProvider.autoDispose`, `ConsumerWidget` — is consistent throughout. Two issues need fixing before shipping: hardcoded medal colors in the leaderboard that violate project conventions, and a `createdAt` timestamp overwrite in AI conversation storage that corrupts conversation age every time the user sends a message.

**Watch for:**
- Two hardcoded hex colors (`Color(0xFFFFD700)`, `Color(0xFFCD7F32)`) in `leaderboard_screen.dart` — confirmed AppColors has no gold/bronze constants (confirmed).
- `_saveCurrentConversation` always writes `createdAt: DateTime.now()`, overwriting the original creation time on every save (confirmed).

**Verdict**: NEEDS_CHANGES

## High-level view

The leaderboard backend is a single `@Public()` endpoint added to `UsersController`, ordered before the `:id/profile` param route so NestJS resolves it correctly. The Flutter screen uses `FutureProvider.autoDispose`, shows medals for ranks 1–3, and highlights the current user by comparing against `currentUserProvider`. Silver correctly uses `AppColors.grey400`; gold and bronze use raw hex literals that violate the `AppColors`-only rule.

The personal library backend is a standalone module with a `PersonalLibraryItem` entity that maps to the `personal_library` table already present in `schema.sql`. `saveResource` is idempotent — a duplicate save returns the existing item rather than throwing. The Flutter side converts `_ResourceRow` from `StatelessWidget` to `ConsumerWidget` to access `apiClientProvider` for the save call, and `LibraryScreen` handles empty state, loading skeletons, download, and confirmed remove.

AI conversation history is stored in `SharedPreferences` via a static `ConversationStorage` helper. The screen becomes `ConsumerStatefulWidget` with a 260px fixed sidebar on desktop (≥900px) and a `Drawer` on mobile. Conversations are auto-titled from the first user message, sortable by `updatedAt`, and restored on page load. The `_saveCurrentConversation` method always stamps `createdAt` as the current time rather than preserving the original, so every update overwrites the creation date — the conversation list displays `updatedAt` (via `DateFormat('MMM d')`) so the visual impact is low, but the data model is wrong and will mislead any future feature that uses `createdAt`.

The homepage provider now fetches four endpoints in parallel: courses, resources, the three most recent questions, and CGPA. The stats row was converted from a grid to a horizontal `Row` of four tappable `_StatCard` widgets showing Courses, Resources, Reputation, and CGPA — replacing the previous Role card. Quick actions, recent questions, and department courses sections each have proper loading skeletons and empty states.

<details>
<summary>Issues (2)</summary>

1. **Hardcoded medal colors** — `Color(0xFFFFD700)` (gold) and `Color(0xFFCD7F32)` (bronze) in `leaderboard_screen.dart` violate the AppColors-only rule. Add `AppColors.gold` and `AppColors.bronze` constants or use the closest existing semantic colors, then replace the literals.

2. **createdAt overwrite in AI storage** — `_saveCurrentConversation` writes `'createdAt': DateTime.now().toIso8601String()` on every call. Preserve the original by loading it from `_conversations` before writing: find the existing entry by `_currentConvId` and carry its `createdAt` forward; only fall back to `DateTime.now()` when no prior entry exists.

</details>

<details>
<summary>Details</summary>

### Hardcoded medal colors in leaderboard

`_rankWidget()` in `leaderboard_screen.dart` (lines ~304–312) uses:

```dart
color: Color(0xFFFFD700), size: 28   // gold
color: Color(0xFFCD7F32), size: 28   // bronze
```

`AppColors` defines no gold or bronze constants. Silver correctly uses `AppColors.grey400`. The fix is either to add `static const Color gold = Color(0xFFFFD700)` and `static const Color bronze = Color(0xFFCD7F32)` to `app_theme.dart`, or to map to existing semantic colors (e.g. `AppColors.warning` for gold, `AppColors.textHint` for bronze). Either path removes the convention violation.

### createdAt overwrite in AI conversation storage

`_saveCurrentConversation` constructs the persisted map as:

```dart
final conv = {
  'id':        _currentConvId,
  'title':     _currentTitle,
  'messages':  messages.map((m) => m.toJson()).toList(),
  'createdAt': DateTime.now().toIso8601String(),  // ← always overwrites
  'updatedAt': DateTime.now().toIso8601String(),
};
```

The sorted conversation list in `ConversationStorage.saveConversation` uses `updatedAt` for ordering, so the display is unaffected today. But `createdAt` loses its semantic meaning on the first save after restore, making it impossible to later build features like "conversations from this week" or to correctly display creation dates in the UI. The fix: look up the existing `createdAt` from `_conversations` before constructing the map.

### Leaderboard — no department scope

The backend returns top-50 globally (no `departmentId` filter). The spec says "top 50" without specifying scope, and Phase 1 targets a single department, so this is acceptable for now. The Flutter screen receives `departmentId` per row if client-side filtering is added later.

### Personal library — save does not refresh resource list

`_saveToLibrary` in `resources_screen.dart` calls the API but does not call `ref.invalidate(libraryProvider)`. This is by design — the library screen is a separate page. When the user navigates to it, `autoDispose` ensures a fresh fetch. No action needed.

### Test coverage

No new tests were added for any of the four features. The library service's idempotent-save logic (returning an existing item rather than throwing `ConflictException`) and the `removeResource` not-found path are the most critical untested paths. The AI conversation serialization round-trip (message → JSON → `_Message.fromJson`) is another gap. These are not blocking for the current sprint but should be tracked.

</details>

## File map

<details>
<summary>Changed files</summary>

| File | Change |
|------|--------|
| `backend/src/app.module.ts` | Registers `LibraryModule` |
| `backend/src/modules/users/users.controller.ts` | Adds `GET /users/leaderboard` with `@Public()` |
| `backend/src/modules/users/users.service.ts` | Adds `getLeaderboard()` — top 50 by reputation |
| `backend/src/modules/library/entities/personal-library.entity.ts` | New entity mapping `personal_library` table |
| `backend/src/modules/library/dto/save-resource.dto.ts` | DTO with `@IsUUID()` validation |
| `backend/src/modules/library/library.service.ts` | CRUD with idempotent save and existence checks |
| `backend/src/modules/library/library.controller.ts` | GET / POST / DELETE `library` endpoints guarded by JWT + `@CurrentUser()` |
| `backend/src/modules/library/library.module.ts` | NestJS module wiring |
| `web_app/lib/core/constants/api_constants.dart` | Adds `leaderboard`, `library`, `libraryRemove` constants |
| `web_app/lib/app/router/app_router.dart` | `/leaderboard` now points to `LeaderboardScreen`; `/library` added |
| `web_app/lib/app/shell/app_shell.dart` | Leaderboard and Library nav items added |
| `web_app/lib/core/storage/conversation_storage.dart` | New SharedPreferences helper for AI history |
| `web_app/lib/presentation/screens/leaderboard/leaderboard_screen.dart` | New screen — top-50 list with medals and current-user highlight |
| `web_app/lib/presentation/screens/library/library_screen.dart` | New screen — saved resources with download and remove |
| `web_app/lib/presentation/screens/ai/ai_screen.dart` | Rewritten with conversation sidebar/drawer, persist/restore, rename/delete |
| `web_app/lib/presentation/screens/home/home_screen.dart` | Redesigned with time greeting, stats row, quick actions, questions, courses |
| `web_app/lib/presentation/screens/resources/resources_screen.dart` | `_ResourceRow` upgraded to `ConsumerWidget`; bookmark-add button to save to library |

Full diff: `git show d47b8ac`

</details>
