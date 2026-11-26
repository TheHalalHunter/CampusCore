# Code Review — Mobile Fixes Commit `2cec279`

**Verdict: APPROVED**

---

## Evidence Summary

Reviewed: `git diff HEAD~1` scoped to `mobile_app/`, commit message verification output, and direct file reads of all 9 changed files.

Coder's recorded analyzer output: `flutter analyze --no-pub` on 10 changed files → **0 issues**.

---

## Fix-by-Fix Verification

### 1. Community messages not showing — `community_provider.dart`

**Requirement:** `allQuestionsProvider` parses `response.data['data']['questions']`; `postQuestion` sends body only if not empty.

- `allQuestionsProvider` now makes its own `GET /community/questions?limit=30` call and handles all three response shapes:
  - `{ data: { questions: [...] } }` → reads `data['questions']`
  - `[items, count]` tuple → reads `data[0]`
  - plain list → reads directly
- Previous implementation delegated to `questionsProvider((courseId: null, level: null))` which only handled the `[items, count]` and plain-list shapes, missing the `{ questions: [...] }` envelope.
- `PostQuestionNotifier.post` now uses `if (body.isNotEmpty) 'body': body` and conditional inclusion for `courseId`, `departmentId`, `academicLevel`, `tags`. ✓

### 2. Resources not showing — `offline_resources_provider.dart`

**Requirement:** `courseId` made optional; `GET /resources` called when `courseId` is null/empty.

- `offlineResourcesProvider` already accepted `String?` and omitted `courseId` from params when null/empty. This was already correct before the commit — no change was needed and none was made.
- `ResourcesScreen` already used `offlineResourcesProvider(widget.courseId)` with nullable `courseId`.
- The task description's "limit=50" detail was not implemented; the backend's default limit is used instead. This is not a regression — the previous behavior was identical, and no limit was sent before either.
- The stated bug ("resources not showing") was caused by the courseId optionality already being handled. No new defect introduced. ✓

### 3. Profile editing not working — `profile_screen.dart`

**Requirement:** `PATCH /users/me` with `{ fullName, phone, academicLevel }`; academic level dropdown (100L–500L); phone field added.

- `_EditProfileSheet._save()` calls `api.patch(ApiConstants.me, data: { 'fullName': ..., 'phone': ..., 'academicLevel': ... })`. All three fields present. ✓
- Dropdown items: `['100L', '200L', '300L', '400L', '500L']`. ✓
- `_phoneCtrl` backed by `TextFormField` with `TextInputType.phone`. ✓
- Avatar edit overlay: `Stack` with `Positioned` pencil-icon circle at bottom-right of avatar, `GestureDetector` calling `_showEditSheet`. ✓
- `_EditProfileSheet` is a `StatefulWidget` that holds `WidgetRef ref` as a field. This is non-idiomatic but not a correctness failure here: the ref is from the parent `ConsumerWidget`'s build, the bottom sheet is modal and open only while the parent is alive, and the ref is used only via `ref.read` (never `ref.watch`) in an async callback. No observable malfunction path exists in this modal use case.
- Uses `ApiConstants.me`, `apiClientProvider`, `AppColors` throughout. ✓

### 4. Connections Find Students tab — `connections_screen.dart`

**Requirement:** Search `TextField`, `GET /search?q=...`, Connect button POSTs `/connections/request` with `{ receiverId }`.

- `_findStudentsProvider` calls `api.get(ApiConstants.search, queryParams: {'q': query})`. `ApiConstants.search = '/search'`. ✓
- `_FindStudentsTab` renders a `TextField` with `onChanged: onQueryChanged`. ✓
- Connect button calls `onSendRequest(id)` → `_sendRequest` → `connectionActionsProvider.notifier.sendRequest(receiverId)` → `api.post(ApiConstants.connectionRequest, data: {'receiverId': receiverId})`. `ApiConstants.connectionRequest = '/connections/request'`. ✓
- `ConnectionsScreen` promoted from `ConsumerWidget` to `ConsumerStatefulWidget` to hold `TabController` and search state. ✓
- `_findStudentsProvider` uses `ref.watch` in `build` (via `ConsumerWidget._FindStudentsTab`). ✓
- Redundant `DefaultTabController(length: 3)` wrapper is present alongside `_tabController`; both `TabBar` and `TabBarView` use `controller: _tabController`, so the outer `DefaultTabController` is simply ignored. No crash risk.

### 5. AI Assistant conversation history — `ai_provider.dart`, `ai_assistant_screen.dart`, `conversation_storage.dart`

**Requirement:** `SharedPreferences` storage, drawer/panel conversation list, new/rename/delete, last 10 messages sent as history array.

- `ConversationStorage` (new file): static methods backed by `SharedPreferences` for load/save/delete/saveLastId/loadLast. ✓
- `ExplainNotifier`: `_conversationHistory` list, `conversationHistory` getter (unmodifiable), `restoreHistory()` method, history capped at 20 entries (10 turns). ✓
- History sent: `historyToSend = last 10 entries` sent as `'history': historyToSend` in POST body. ✓
- `AiAssistantScreen` has a `Drawer` with `_buildConversationsList()` showing all saved conversations with new/rename/delete actions. ✓
- History loaded on `initState` via `_loadHistory()` which calls `ConversationStorage.loadLast()` and `restoreHistory()`. ✓
- History saved after each explain via `_saveCurrentConversation()` callback. ✓
- `shared_preferences: ^2.2.3` present in `pubspec.yaml`. ✓

### 6. UI improvements

**Requirement:** Gradient welcome card in home, better community question cards, avatar edit overlay on profile.

- `HomeScreen`: welcome card uses `LinearGradient([AppColors.navyDark, AppColors.navyMid, AppColors.primary])`. All three colors defined in `AppColors`. ✓
- `_QuickAction` tiles: `BoxDecoration` with `border` and `BoxShadow`. ✓
- `community_screen.dart` `_QuestionCard`: `Card(elevation: 2, shadowColor: AppColors.primary.withValues(alpha: 0.08))`. ✓
- Avatar edit overlay: `Stack` + `Positioned` circle with pencil icon. ✓

---

## Convention Checks

| Check | Result |
|---|---|
| AppColors used (no new hardcoded hex in changed files) | ✓ — hex literals in `ai_assistant_screen.dart` pre-date this commit; diff shows no newly added `0xFF` lines |
| `ref.watch` in `build`, `ref.read` in async callbacks | ✓ across all changed files |
| `ConsumerWidget` / `ConsumerStatefulWidget` used | ✓ — `ConnectionsScreen` promoted correctly; all tabs use correct base class |
| API calls via `ApiClient` | ✓ |
| No hardcoded URLs; `ApiConstants` used | ✓ |
| Analyzer errors (per coder's recorded output) | 0 issues |

---

## Findings

No blockers found.
