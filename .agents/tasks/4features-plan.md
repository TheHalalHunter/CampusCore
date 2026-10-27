# CampusCore — 4-Feature Implementation Plan

**Features:** Leaderboard · Personal Library · AI Chat History · Homepage Redesign  
**Target apps:** `web_app` (Flutter Web) + `backend` (NestJS)  
**Written by:** Planning step · Workflow `wf_573b68ad9a9c3305`

---

## Codebase findings (read before implementing)

| Finding | Detail |
|---------|--------|
| Shell sidebar | `web_app/lib/app/shell/app_shell.dart` — `_navItems` list drives both the bottom nav (mobile) and sidebar (desktop). New routes need entries here. |
| Router | `web_app/lib/app/router/app_router.dart` — `/leaderboard` already exists but shows `ComingSoonScreen`. No `/library` route exists yet. |
| API constants | `web_app/lib/core/constants/api_constants.dart` — add `leaderboard`, `library`, `libraryRemove` here; never in screen files. |
| `personal_library` table | Already in `database/schema.sql` with `(user_id, resource_id, note, created_at)` — no migration needed. The table just has no backend module yet. |
| No `library` module in backend | `backend/src/modules/` has no library folder — must be created following the connections module pattern. |
| `shared_preferences` available | `pubspec.yaml` already lists `shared_preferences: ^2.2.3` — safe to use for AI chat history without adding a dependency. |
| `uuid` NOT in pubspec | `pubspec.yaml` has no uuid package. Generate conversation IDs using `DateTime.now().millisecondsSinceEpoch.toString()` instead. |
| `intl` available | `pubspec.yaml` has `intl: ^0.19.0` — use `DateFormat` for greeting time-of-day logic in home screen. |
| Resources screen | `ResourcesScreen` renders a list of resource maps. Resource tiles are built inline — "Save to Library" button goes inside the tile builder. |
| Auth user shape | `AppUser` (in `auth_provider.dart`) has `id`, `firstName`, `lastName`, `fullName`, `initials`, `role`, `reputationPoints`, `level`, `departmentId`. |
| Backend response shape | All responses are `{ success, data, message }` via `ResponseInterceptor`. Services return plain objects/arrays; the interceptor wraps them. |
| `@Public()` decorator | Marks a route as accessible without JWT. Import from `../../common/decorators/public.decorator`. |
| Module registration | Every new NestJS module must be imported in `backend/src/app.module.ts`. |
| `UserRole` enum | `backend/src/modules/users/enums/user-role.enum.ts` — use `UserRole.STUDENT`, `UserRole.MODERATOR`, etc. |

---

## Feature 1 — Leaderboard

### Overview
Add a public backend endpoint returning the top 50 users by reputation, then replace the existing `ComingSoonScreen` at `/leaderboard` with a real ranked list.

### Order of operations

- [ ] 1. **Add `getLeaderboard()` to `UsersService`**  
  Query the `users` table ordered by `reputationPoints DESC`, limit 50. Select only `id`, `fullName`, `reputationPoints`, `role`, `academicLevel`, `departmentId` to avoid leaking sensitive fields. Use the TypeORM repository (no raw SQL).  
  **File:** `backend/src/modules/users/users.service.ts`  
  **Verify:** `npm run lint` in `backend/` passes; no TypeScript errors.

- [ ] 2. **Add `GET /users/leaderboard` to `UsersController`**  
  Mark with `@Public()` so no token is needed. Place it *before* the `GET :id/profile` param route to avoid route shadowing (NestJS matches routes top-to-bottom). Import `Public` from `../../common/decorators/public.decorator`.  
  **File:** `backend/src/modules/users/users.controller.ts`  
  **Verify:** `npm run lint` passes. Manual `curl https://campuscore-bfrq.onrender.com/api/v1/users/leaderboard` (after deploy) should return a JSON array under `data`.

- [ ] 3. **Add `leaderboard` constant to `ApiConstants`**  
  ```dart
  static const String leaderboard = '/users/leaderboard';
  ```  
  **File:** `web_app/lib/core/constants/api_constants.dart`  
  **Verify:** `flutter analyze` in `web_app/` passes.

- [ ] 4. **Create `LeaderboardScreen`**  
  Path: `web_app/lib/presentation/screens/leaderboard/leaderboard_screen.dart`

  - `ConsumerWidget`, uses `FutureProvider.autoDispose<List<Map<String,dynamic>>>` named `leaderboardProvider` that calls `api.get(ApiConstants.leaderboard)`.
  - Renders a `ListView.builder` of rank tiles.
  - Tile layout: rank number (left) → avatar circle with initials → full name + level/role subtitle → reputation points (right, bold). Use `AppUser.initials`-style logic locally (split `fullName` on space).
  - Top 3 tiles get medal icons in place of the rank number: gold (`0xFFFFD700`-ish → use `AppColors.warning`), silver (`AppColors.grey400`), bronze (`AppColors.textHint`). Use `Icons.workspace_premium` or `Icons.emoji_events` for medals.
  - Highlight the current user's row with a `AppColors.primary.withValues(alpha: 0.08)` background and a thin `AppColors.primary` left border.
  - Loading state: `ListView` of 6 skeleton `Card` widgets (same pattern as `_SkeletonCard` in `home_screen.dart`).
  - Error state: centered `Column` with `Icons.leaderboard_outlined`, "Could not load leaderboard", and a `TextButton` retry.
  - Empty state: same layout, "No data yet."

  **File:** `web_app/lib/presentation/screens/leaderboard/leaderboard_screen.dart`  
  **Verify:** `flutter analyze` passes.

- [ ] 5. **Wire the route and import `LeaderboardScreen` in the router**  
  Replace the `ComingSoonScreen` builder at `path: '/leaderboard'` with `const LeaderboardScreen()`. Add the import.  
  **File:** `web_app/lib/app/router/app_router.dart`  
  **Verify:** `flutter analyze` passes.

- [ ] 6. **Add Leaderboard to the sidebar/bottom-nav**  
  In `_navItems` inside `AppShell`, add:
  ```dart
  (label: 'Leaderboard', route: '/leaderboard', icon: Icons.leaderboard_outlined),
  ```
  Insert it between `AI Assist` and `Profile` so it doesn't disrupt existing nav order significantly.  
  **File:** `web_app/lib/app/shell/app_shell.dart`  
  **Verify:** `flutter analyze` passes. Hot-reload shows Leaderboard in sidebar and bottom nav.

---

## Feature 2 — Personal Library

### Overview
The `personal_library` table already exists in the database. We need a NestJS module to expose it, then a Flutter screen and a "Save to Library" action on resource tiles.

### Order of operations

- [ ] 7. **Create `PersonalLibraryItem` entity**  
  Maps to the existing `personal_library` table. Columns: `id` (uuid PK), `userId`, `resourceId`, `note` (nullable text), `createdAt`. Add `@ManyToOne` relations to `User` and `Resource` entities with `eager: false` (load them explicitly only when needed).  
  **File:** `backend/src/modules/library/entities/personal-library.entity.ts`  
  **Verify:** Entity file compiles; `npm run lint` passes.

- [ ] 8. **Create `LibraryService`**  
  Three methods:
  - `getLibrary(userId: string)` — `findMany` where `user_id = userId`, ordered by `created_at DESC`. Join-load the related `Resource` fields needed for display (`title`, `type`, `fileUrl`, `courseId`).
  - `addToLibrary(userId: string, resourceId: string)` — `upsert` / `findOne or insert`. If a row already exists for `(userId, resourceId)`, return it without error (idempotent). If the resource doesn't exist, throw `NotFoundException`.
  - `removeFromLibrary(userId: string, resourceId: string)` — delete row. Throw `NotFoundException` if not found.  
  Use `TypeORM` repository. Import `Resource` entity from `../resources/entities/resource.entity`.  
  **File:** `backend/src/modules/library/library.service.ts`  
  **Verify:** `npm run lint` passes.

- [ ] 9. **Create `LibraryController`**  
  Three routes, all protected (no `@Public()`):
  - `GET /library` — returns current user's saved resources.
  - `POST /library` — body: `{ resourceId: string }`. Returns the saved item.
  - `DELETE /library/:resourceId` — deletes the entry. Returns `{ removed: true }`.  
  Use `@CurrentUser("id")` for all three.  
  **File:** `backend/src/modules/library/library.controller.ts`  
  **Verify:** `npm run lint` passes.

- [ ] 10. **Create `LibraryModule` and register it**  
  - `LibraryModule` imports `TypeOrmModule.forFeature([PersonalLibraryItem])` and imports `ResourcesModule` (to access `Resource` entity or its repo). Export `LibraryService`.  
  - Add `LibraryModule` import to `AppModule`.  
  **Files:**  
  - `backend/src/modules/library/library.module.ts`  
  - `backend/src/app.module.ts`  
  **Verify:** `npm run lint` passes. Backend starts without errors (`npm run start:dev` in terminal).

- [ ] 11. **Add library API constants**  
  ```dart
  static const String library = '/library';
  static String libraryRemove(String resourceId) => '/library/$resourceId';
  ```  
  **File:** `web_app/lib/core/constants/api_constants.dart`  
  **Verify:** `flutter analyze` passes.

- [ ] 12. **Create `LibraryScreen`**  
  Path: `web_app/lib/presentation/screens/library/library_screen.dart`

  - `ConsumerWidget`, `libraryProvider = FutureProvider.autoDispose<List<Map<String,dynamic>>>` calls `api.get(ApiConstants.library)`.
  - Renders resource cards in a `ListView`. Each card shows: resource title (bold), type badge (chip), course name if available, a download `IconButton` (opens `fileUrl` with `url_launcher`), and a remove `IconButton` (calls `DELETE /library/:resourceId`, then `ref.invalidate(libraryProvider)`).
  - Loading: 4 skeleton cards.
  - Empty state: `Icons.bookmark_border_outlined`, "Your library is empty. Save resources while browsing to find them here."
  - Error state: retry button.
  - AppBar title: "My Library".

  **File:** `web_app/lib/presentation/screens/library/library_screen.dart`  
  **Verify:** `flutter analyze` passes.

- [ ] 13. **Add "Save to Library" button to resource tiles in `ResourcesScreen`**  
  In `resources_screen.dart`, find the resource tile builder. Add a `IconButton(icon: Icon(Icons.bookmark_add_outlined))` to each tile's trailing area. On tap, call `api.post(ApiConstants.library, data: {'resourceId': resource['id']})` and show a `SnackBar` with "Saved to library" (`AppColors.success`) or an error message. Do not need to touch `libraryProvider` from here — just a fire-and-forget POST with feedback.  
  **File:** `web_app/lib/presentation/screens/resources/resources_screen.dart`  
  **Verify:** `flutter analyze` passes. Tapping the bookmark icon produces a snackbar.

- [ ] 14. **Wire the `/library` route and add sidebar entry**  
  - In `app_router.dart`: add `GoRoute(path: '/library', name: 'library', builder: (_, __) => const LibraryScreen())` inside the `ShellRoute`. Add import.  
  - In `app_shell.dart` `_navItems`: add `(label: 'Library', route: '/library', icon: Icons.bookmark_outline)`. Insert before `Profile`.  
  **Files:**  
  - `web_app/lib/app/router/app_router.dart`  
  - `web_app/lib/app/shell/app_shell.dart`  
  **Verify:** `flutter analyze` passes. Library tab appears and navigates to the screen.

---

## Feature 3 — AI Chat History

### Overview
Store conversations client-side using `shared_preferences` (already in `pubspec.yaml`). No backend changes. Wrap the existing AI chat content in a sidebar (desktop) / drawer (mobile) that lists saved conversations. The existing AI modes (Explain, Summarize, Quiz, Flashcards, Predict Topics) and all message rendering must remain intact.

### Design decisions
- Conversations are stored as a JSON list in SharedPreferences under key `ai_conversations`.
- Conversation shape: `{ id, title, messages: [{text, type, toolLabel}], createdAt, updatedAt }`.
- `id` = `DateTime.now().millisecondsSinceEpoch.toString()` (no uuid package needed).
- `title` = first 40 chars of the first user message; defaults to "New Conversation" until a user message is sent.
- On screen load: restore the most recently updated conversation. If none exists, start fresh with the welcome message.
- A new conversation is created when the user taps "New Chat".
- Rename: tap the title in the app bar → inline `TextField` replaces the title `Text`.
- Delete: swipe-to-dismiss or a trailing delete icon in the conversation list.

### Order of operations

- [ ] 15. **Create `ConversationStorage` helper class**  
  New file: `web_app/lib/core/storage/conversation_storage.dart`  
  - Static methods: `loadAll()`, `saveAll(List)`, `loadLast()`, `saveConversation(conv)`, `deleteConversation(id)`.  
  - Serializes/deserializes list of conversation maps to/from JSON string in SharedPreferences.  
  - Key: `'ai_conversations'`.  
  - Import: `package:shared_preferences/shared_preferences.dart`.  
  **File:** `web_app/lib/core/storage/conversation_storage.dart`  
  **Verify:** `flutter analyze` passes.

- [ ] 16. **Rewrite `ai_screen.dart` with conversation management**  
  **File:** `web_app/lib/presentation/screens/ai/ai_screen.dart`

  Key structural changes:
  1. Convert `_AiNotifier` / `_aiProvider` to accept an initial messages list (for restore). On first load, call `ConversationStorage.loadLast()` — if found, restore that conversation's messages and id; otherwise use the default welcome message.
  2. Add state to `_AiScreenState`: `_currentConvId`, `_currentTitle`, `_conversations` (list loaded from storage), `_showHistorySidebar` (desktop), `_historyDrawerKey` (mobile).
  3. After every `_send()` that succeeds: update `_currentTitle` from first user message (truncated to 40 chars, only on the first user message), save the updated conversation to `ConversationStorage`.
  4. **Conversation sidebar (desktop, `width >= 900`)**: a fixed-width `Container` (240 px) to the left of the chat column. Header row: "Conversations" text + "＋" `IconButton` (new chat). Body: `ListView` of conversation tiles — title, date (`DateFormat('MMM d')` from `intl`), delete icon. Tapping a tile loads that conversation (set messages in notifier, update `_currentConvId`, `_currentTitle`). Selected tile highlighted with `AppColors.primary.withValues(alpha: 0.1)`.
  5. **Mobile**: the same list is a `Drawer` opened by an `IconButton` in the AppBar.
  6. **Rename**: in the AppBar, replace the static "AI Study Assistant" `Text` with a `GestureDetector`. Tapping it shows an `AlertDialog` with a `TextField` pre-filled with `_currentTitle`. On confirm, update `_currentTitle` and re-save the conversation.
  7. **New Chat button**: existing "New Chat" `TextButton.icon` in AppBar actions calls `_newConversation()` which resets provider, generates a new id, sets title to "New Conversation", adds the conversation to storage.
  8. **Keep all existing functionality unchanged**: modes selector, message bubble rendering, typing indicator, disclaimer, input bar, `_AiNotifier` API call logic.

  **Verify:** `flutter analyze` passes. Conversations persist across page refreshes.

---

## Feature 4 — Homepage Redesign

### Overview
Rewrite `home_screen.dart` to show a time-aware greeting, richer stats (courses, resources, questions asked, reputation points), quick actions, a "Recent Questions" row, and a "Your Courses" row. All data is fetched in a single provider with `Future.wait`.

### Order of operations

- [ ] 17. **Rewrite `HomeScreen` in `home_screen.dart`**  
  **File:** `web_app/lib/presentation/screens/home/home_screen.dart`

  **Provider** — replace `homeDashboardProvider` with:
  ```dart
  final homeDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
    final api  = ref.read(apiClientProvider);
    final user = ref.read(currentUserProvider);
    final results = await Future.wait([
      api.get(ApiConstants.courses, params: user?.departmentId != null
          ? {'departmentId': user!.departmentId} : null),
      api.get(ApiConstants.resources),
      api.get(ApiConstants.questions, params: {'limit': 3}),
      api.get(ApiConstants.gpaCgpa),           // already in ApiConstants
    ]);
    final courses   = (results[0].data['data'] as List?) ?? [];
    final resources = (results[1].data['data'] as List?) ?? [];
    final questions = (results[2].data['data'] as List?) ?? [];
    final cgpaData  = results[3].data['data'];
    final reputation = user?.reputationPoints ?? 0;
    return {
      'courses':    courses,
      'resources':  resources,
      'questions':  questions,
      'cgpa':       (cgpaData?['cgpa'] ?? 0.0).toStringAsFixed(2),
      'reputation': reputation,
    };
  });
  ```
  Wrap in a `try/catch` that returns empty lists and zero values on error.

  **Screen layout** (top-to-bottom, inside `SingleChildScrollView`):

  1. **Welcome banner** — full-width gradient `Container` using `AppColors.heroGradient`. Shows:
     - Greeting: `_greeting(hour)` helper returns "Good morning", "Good afternoon", or "Good evening" based on `DateTime.now().hour` (<12, <18, else). Format: `"Good morning, ${user?.firstName ?? 'Student'}! 👋"`.
     - Sub-line: current date formatted as `DateFormat('EEEE, MMMM d').format(DateTime.now())` using `intl`.
  2. **Stats row** — horizontal `Row` with 4 `Expanded` stat tiles (not a `GridView` — easier to control height in the redesign). Tiles: Courses (count), Resources (count), Reputation Points (`user?.reputationPoints`), CGPA. Each tile: icon in a colored circle, value, label. Colors: `AppColors.primary`, `AppColors.cyan`, `AppColors.warning`, `AppColors.success`.
  3. **Quick actions** — keep the same `Wrap` of `_QuickAction` chips. Update the 4 actions: "Ask Question" (`/community`), "Upload Resource" (`/resources`), "AI Assistant" (`/ai`), "Browse Courses" (`/courses`).
  4. **Recent Questions section** — titled "Recent Questions" with a "View all →" `TextButton` linking to `/community`. Show up to 3 question cards (from `questions` list). Each card: question title, answer count badge, author name if available, tappable `InkWell` (navigates to `/community`). If empty: "No questions yet. Be the first to ask!"
  5. **Department Courses section** — titled "Your Courses" with a "View all →" `TextButton` linking to `/courses`. Show the first 4 courses from the `courses` list. Each course tile: course code (bold), course title, academic level chip. Tappable, navigates to `/courses/${course['id']}`.

  **Loading state**: replace stat tiles with 4 skeleton cards, replace question cards with 3 skeleton list tiles, replace course tiles with 4 skeleton cards.

  **Keep**: `_StatCard`, `_SkeletonCard`, `_QuickAction` helper widgets (refactor `_StatCard` if its column-based layout needs to change for the Row approach — it may need `mainAxisSize: MainAxisSize.min`).

  **Verify:** `flutter analyze` passes. Screen shows greeting, stats, recent questions, and courses.

---

## Cross-cutting notes

### Import checklist for router (`app_router.dart`)
After all features are added, the router needs these imports:
```dart
import '../../presentation/screens/leaderboard/leaderboard_screen.dart';
import '../../presentation/screens/library/library_screen.dart';
```
Remove the `ComingSoonScreen` builder for `/leaderboard`; it can stay imported if other routes still use it, otherwise remove the import too.

### `app_shell.dart` final nav order
After Features 1 and 2:
```
Home, Courses, Resources, Community, Notifications, Progress, AI Assist, Leaderboard, Library, Profile
```
The bottom nav on mobile will have 10 items — Flutter's `BottomNavigationBar` supports up to ~8 cleanly. If the product owner wants to trim it, remove `Notifications` from the bottom nav (it's accessible via the AppBar bell icon) and/or `Leaderboard`. For now keep all items; `flutter analyze` will not flag this.

### Backend deployment note
The library module uses the existing `personal_library` table — no SQL migration needed. The leaderboard endpoint is a read-only query. Deploy the backend after steps 1–10.

### Verification commands (run in order)
```bash
# Backend
cd backend && npm run lint

# Flutter web
cd web_app && flutter analyze
cd web_app && flutter build web --no-tree-shake-icons   # confirms no compile errors
```
There are no automated tests to run (`users.service.spec.ts` exists but tests the existing service only). Lint + analyze + build is the verification gate for this task.
