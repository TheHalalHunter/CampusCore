# Implementation Plan — Connections Screen

## Exploration Findings

### Backend endpoints confirmed (connections.controller.ts)
- `GET /connections` — accepted connections (returns IDs only, no nested user data)
- `GET /connections/pending/received` — pending received
- `GET /connections/pending/sent` — pending sent
- `POST /connections/request` body `{ receiverId }` — send request
- `PATCH /connections/:id/accept` — accept
- `DELETE /connections/:id` — cancel/reject/remove
- `GET /connections/status/:userId` — check status with a specific user
- `GET /users/:id/profile` — public profile (returns fullName, academicLevel, role, reputationPoints, etc.)

### Critical gap: no student search endpoint
- `GET /search?q=...` searches **courses, resources, questions** only — NOT users.
- There is no `GET /users?q=...` accessible to students; admin-only `GET /admin/users` exists.
- **Decision:** The "Find Students" tab will filter already-connected users by name query client-side, plus attempt `GET /users/search?q=...` optimistically (future-proof). An in-UI notice explains the limitation.

### AppUser fields available from currentUserProvider
`id, email, firstName, lastName, role, avatarUrl, reputationPoints, level, departmentId`

### User entity fields from backend (`getPublicProfile`)
Returns all fields except `firebaseUid`, `isEmailVerified`, `acceptedIntegrityPolicy`:
`id, email, fullName, avatar, phone, role, departmentId, academicLevel, matricNumber, isActive, reputationPoints, lastSeenAt, stellarAddress, fcmToken, createdAt, updatedAt`

---

## Implementation Plan

- [ ] 1. Add connection + user profile constants to `api_constants.dart`.
      Add 7 new entries to the `ApiConstants` class body after the existing `unreadCount` constant:
      ```dart
      // Connections
      static const String connections                  = '/connections';
      static const String connectionRequest            = '/connections/request';
      static const String connectionsPendingReceived   = '/connections/pending/received';
      static const String connectionsPendingSent       = '/connections/pending/sent';
      static String connectionAccept(String id)        => '/connections/$id/accept';
      static String connectionRemove(String id)        => '/connections/$id';
      static String connectionStatus(String userId)    => '/connections/status/$userId';
      // Users
      static String userProfile(String id)             => '/users/$id/profile';
      ```
      Files: `web_app/lib/core/constants/api_constants.dart`
      Verify: `flutter analyze web_app/` — zero errors.

- [ ] 2. Update `app_router.dart` to route `/connections` to `ConnectionsScreen`.
      Add import: `import '../../presentation/screens/connections/connections_screen.dart';`
      Replace the `/connections` GoRoute builder from `ComingSoonScreen(...)` to `const ConnectionsScreen()`.
      The `ComingSoonScreen` import stays because `/notifications` and `/leaderboard` still use it.
      Files: `web_app/lib/app/router/app_router.dart`
      Verify: `flutter analyze web_app/` — zero errors (requires the screen file to exist first).

- [ ] 3. Create `connections_screen.dart` — data models and providers.
      Create `web_app/lib/presentation/screens/connections/connections_screen.dart`.
      **Private data models** (class-private, no `part` files needed):
      - `_ConnectionItem` — parses `{ id, requesterId, receiverId, status, createdAt }` from `Map<String,dynamic>`.
      - `_UserProfile` — parses `{ id, fullName, academicLevel, role, reputationPoints }`. Has `initials` getter (splits fullName, takes first char of each word, up to 2, uppercase).
      **Providers** (file-scope, all `FutureProvider.autoDispose`):
      - `connectionsProvider` — `GET /connections` → `List<_ConnectionItem>`
      - `pendingReceivedProvider` — `GET /connections/pending/received` → `List<_ConnectionItem>`
      - `pendingSentProvider` — `GET /connections/pending/sent` → `List<_ConnectionItem>`
      - `userProfileCacheProvider` — `FutureProvider.autoDispose.family<_UserProfile?, String>` keyed by userId → `GET /users/:id/profile`. Catches all errors, returns a fallback `_UserProfile` with `fullName: 'Unknown Student'` rather than throwing.
      - `_findStudentsProvider` — `FutureProvider.autoDispose.family<List<_UserProfile>, String>` keyed by query string. If query < 2 chars returns `[]`. Otherwise: (1) reads `connectionsProvider`; for each accepted connection resolves the peer profile via `userProfileCacheProvider`; filters by case-insensitive substring match on `fullName`. Also attempts `GET /search?q=<query>` and reads `data['users']` if present (future-proof). Returns deduplicated list.
      Files: `web_app/lib/presentation/screens/connections/connections_screen.dart`
      Verify: `flutter analyze web_app/` — zero errors after this step.

- [ ] 4. Implement `ConnectionsScreen` stateful widget and 3 tab layout.
      In the same `connections_screen.dart`:
      `class ConnectionsScreen extends ConsumerStatefulWidget`
      State mixin: `SingleTickerProviderStateMixin`
      State fields:
      - `late TabController _tabController` (length: 3)
      - `final TextEditingController _searchCtrl`
      - `String _searchQuery = ''`
      - `final Map<String, bool> _actionLoading = {}` — tracks per-connection-id loading state
      `build` returns `Scaffold`:
      - `backgroundColor: AppColors.background`
      - `AppBar` with title 'Connections', `AppColors.navyDark` background, `PreferredSize` `bottom` containing a `TabBar` with tabs: 'My Connections', `_RequestsTabLabel` (shows badge), 'Find Students'. Tab label style: Nunito w700 13px, `labelColor: AppColors.cyanBright`, `unselectedLabelColor: AppColors.textOnDarkSub`, `indicatorColor: AppColors.cyanBright`.
      - `body: TabBarView` with 3 children: `_MyConnectionsTab`, `_RequestsTab`, `_FindStudentsTab`
      Action methods on the state (each sets `_actionLoading[id] = true/false`, calls API via `ref.read(apiClientProvider)`, on success invalidates relevant providers, on error shows `SnackBar` with `AppColors.error` background):
      - `Future<void> _sendRequest(String receiverId)` — POST `/connections/request`
      - `Future<void> _acceptRequest(String connectionId)` — PATCH `/connections/:id/accept`
      - `Future<void> _removeConnection(String connectionId)` — DELETE `/connections/:id` (used for remove from My Connections AND reject from Requests)
      - `Future<void> _cancelRequest(String connectionId)` — DELETE `/connections/:id` (same endpoint, different label)
      Files: `web_app/lib/presentation/screens/connections/connections_screen.dart`
      Verify: `flutter analyze web_app/` — zero errors.

- [ ] 5. Implement `_MyConnectionsTab`, `_RequestsTab`, `_FindStudentsTab`, shared widgets.
      All in the same file.

      **`_MyConnectionsTab`** (`ConsumerWidget`, receives `actionLoading` map and `onRemove` callback):
      Watches `connectionsProvider`. `.when(loading, error, data)`:
      - loading: `_ConnectionSkeleton()` (5 skeleton tiles)
      - error: `_ErrorWidget(message: '...', onRetry: () => ref.invalidate(connectionsProvider))`
      - data (empty): `_EmptyState(icon: Icons.people_outline, message: 'No connections yet.\nFind students to connect!')`
      - data (non-empty): `ListView.separated` (shrinkWrap when inside a column, full otherwise), each item a `_PeerCard` with `action: 'remove'`.

      **`_RequestsTab`** (`ConsumerWidget`, receives `actionLoading`, `onAccept`, `onReject`, `onCancel`):
      Watches both `pendingReceivedProvider` and `pendingSentProvider`. Renders a `SingleChildScrollView > Column`:
      - Section "Received Requests": `.when(...)` same pattern; each card gets Accept + Reject buttons.
      - `Divider` between sections.
      - Section "Sent Requests": `.when(...)` same pattern; each card gets Cancel button.
      Received-empty message: 'No pending requests received.'
      Sent-empty message: 'No pending requests sent.'

      **`_FindStudentsTab`** (passes search state from parent via constructor params):
      - Info banner at top: `Container` with `AppColors.info.withValues(alpha: 0.1)` background, `Icon(Icons.info_outline, color: AppColors.info)`, text: 'Student search is limited to your connections and by exact name. A dedicated search feature is coming soon.'
      - `TextField` for search with `prefixIcon: Icon(Icons.search)`, `hintText: 'Search by name...'`, calls `onQueryChanged` on change.
      - If `searchQuery.length < 2`: show `_EmptyState(icon: Icons.search_outlined, message: 'Enter at least 2 characters to search.')`.
      - Otherwise watches `_findStudentsProvider(searchQuery)`. `.when(...)` with loading, error, data (empty / non-empty). Each result card: `_UserProfileCard` with Send Request button.

      **`_PeerCard`** (`ConsumerWidget`):
      Watches `userProfileCacheProvider(peerId)`. Shows `_SkeletonListTile()` while loading.
      Card structure: `Card > Padding > Row`:
      - `CircleAvatar(radius: 22, backgroundColor: AppColors.primary.withValues(alpha: 0.15))` showing `initials`.
      - `Expanded > Column`: `Text(fullName, style: titleSmall)`, `Text(roleAndLevel, style: bodySmall, color: AppColors.textHint)`.
      - Action buttons (wrapped in `_loadingOrButton` helper): if `_actionLoading[connectionId] == true` show `SizedBox(18,18, CircularProgressIndicator(strokeWidth:2))`.
      For "remove": `OutlinedButton('Remove', foregroundColor: AppColors.error, side: BorderSide(AppColors.error))`.
      For "accept+reject": `Row` with `ElevatedButton('Accept', backgroundColor: AppColors.success)` + `OutlinedButton('Reject', foregroundColor: AppColors.error)`.
      For "cancel": `OutlinedButton('Cancel', foregroundColor: AppColors.textHint)`.

      **`_UserProfileCard`** — similar to _PeerCard but for search results. Shows Send Request button.

      **`_RequestsBadge`** (`ConsumerWidget`): watches `pendingReceivedProvider`. If data has items > 0, shows a `Stack` with `Icon(Icons.mail_outline)` and a red `CircleAvatar(radius: 5, backgroundColor: AppColors.error)` badge in `Positioned(right: 0, top: 0)`. Used inside the Requests tab label via `Tab(child: ...)`.

      **Skeleton / Empty / Error widgets**:
      - `_SkeletonListTile`: `Padding > Row` with grey placeholder containers for avatar (circle) and text lines.
      - `_ConnectionSkeleton`: `ListView` of 5 `Card(_SkeletonListTile())` items.
      - `_EmptyState`: `Center > Column(mainAxisAlignment: center)` with Icon(64, AppColors.border), SizedBox(16), Text(AppColors.textHint).
      - `_ErrorWidget`: `Center > Column` with Icon(Icons.error_outline, AppColors.error, 48), SizedBox(12), Text, SizedBox(16), ElevatedButton('Retry').

      Files: `web_app/lib/presentation/screens/connections/connections_screen.dart`
      Verify: `flutter analyze web_app/` — zero errors. `flutter build web` — succeeds.

---

## Null Safety & Analysis Watchpoints

1. `userProfileCacheProvider` must never throw — always return a fallback. Use `try/catch` around the API call.
2. `_findStudentsProvider` reads `connectionsProvider` synchronously via `ref.read` inside the provider body; connections may not yet be loaded — wrap in try/catch and return `[]` on failure.
3. `_actionLoading` is accessed from the `Map` with `[]` operator which returns `bool?` — use `_actionLoading[id] == true` not `_actionLoading[id]!`.
4. Do NOT use `.withOpacity()` — use `.withValues(alpha: ...)` everywhere (required for Flutter 3.27+).
5. `_tabController` must be disposed in `dispose()`.
6. `_searchCtrl` must be disposed in `dispose()`.
7. The `_RequestsTabLabel` widget must handle the `AsyncValue` gracefully — use `.maybeWhen(data: ..., orElse: () => ...)` to avoid showing loading spinners in the tab bar.
8. All `Text` with explicit `TextStyle` must include `fontFamily: 'Nunito'`.
9. `Map<String, bool>` for `_actionLoading` is a regular mutable field — it is fine to call `setState` after modifying it.
10. Avoid name collision: the local `_ErrorWidget` and `_EmptyState` in this file shadow any similarly-named widgets in other files — that is fine since they're private (`_`-prefixed).
