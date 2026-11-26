# Mobile App P0/P1/P2 Fixes — Code Review

**Commit:** d23ff2d  
**Date:** 2026-10-31  
**Reviewer:** Kiro automated review

---

## Evidence Gathered

- Full diff read via `git diff HEAD~1 -- mobile_app/`
- Current file state read directly for all changed files
- `supabase_flutter-2.18.3` package source inspected to confirm `publishableKey` parameter is valid
- No `flutter analyze` output is attached to the commit; environment has documented history of `flutter analyze` hanging (see `fix-verification.txt`)

---

## P0 Items

### P0-1 · API base URL (`api_constants.dart`)
**PASS.** `defaultValue` is `'https://campuscore-bfrq.onrender.com/api/v1'` (line 6). Previous `localhost:3000` removed.

### P0-2 · Supabase init in `main.dart`
**PASS.** `Supabase.initialize()` is called with:
- `url: 'https://oflxgcsaxzauivbywmwl.supabase.co'`
- `publishableKey: 'eyJhbGci...'` (anon JWT)

`publishableKey` is confirmed valid in supabase_flutter 2.18.3 (package source inspected; `anonKey` is deprecated but still accepted — `publishableKey` is the correct current name).

### P0-3 · `upload_provider.dart` uses Supabase Storage
**PASS.** Imports `supabase_storage.dart`; upload method calls `SupabaseStorageService.uploadFile(bytes, path, mimeType)`. No `firebase_storage` import remains anywhere in `mobile_app/lib/` (only `storageBucket` config string in `firebase_options.dart`, which is harmless). `firebase_storage: ^12.4.0` removed from `pubspec.yaml`; `supabase_flutter: ^2.5.2` added (resolves to 2.18.3 per lock file).

### P0-4 · Keep-alive ping in `main.dart`
**PASS.** `Timer.periodic(const Duration(minutes: 10), ...)` added after `runApp()`, pinging `https://campuscore-bfrq.onrender.com/api/v1/departments` with a dedicated Dio instance (10s connect/receive timeouts, errors swallowed).

---

## P1 Items

### P1-5 · AI history in `ai_provider.dart`
**PASS.** `ExplainNotifier` maintains `_conversationHistory` list (capped at 20 entries / 10 turns). `explain()` builds `historyToSend` from the last 10 entries and includes `'history': historyToSend` in the POST `/ai/explain` payload when non-empty. History is updated after each response. `clearHistory()` resets both state and history.

### P1-6 · Library wired to backend
**PASS.** `personalLibraryProvider` is a `FutureProvider` calling `GET /library` via `ApiConstants.library`. `libraryActionsProvider` handles `POST /library` (save) and `DELETE /library/:resourceId` (remove). `bookmarkProvider.toggle()` calls server-side save/remove. `ApiConstants.library` and `ApiConstants.libraryRemove(id)` exist.

### P1-7 · Badges use real `FutureProvider`
**PASS.** `_badgesProvider` is a `FutureProvider` calling `GET /gamification/badges` (`ApiConstants.badges`). No hardcoded badge values. Empty state and loading states handled.

### P1-8 · Department name on profile
**PASS.** Profile screen line 57: `ref.watch(primaryDepartmentProvider).value?.name ?? 'Fisheries & Aquaculture'`. Falls back to hardcoded name only if provider hasn't loaded — this is a safe loading-state fallback, not a permanent hardcode.

### P1-9 · Sign-out navigation
**PASS.** `profile_screen.dart` lines 110–111: `await ref.read(authProvider.notifier).signOut()` followed by `context.go(AppRoutes.onboarding)` inside `context.mounted` guard.

### P1-10 · Upvote answer URL
**PASS.** `discussions_provider.dart` `UpvoteNotifier.upvoteAnswer()` calls `ApiConstants.upvoteAnswer(answerId)` which resolves to `/community/answers/$id/upvote`. The old wrong path `/community/questions/answers/$id/upvote` is gone.

### P1-11 · `questionDetailProvider` exists
**PASS.** `community_provider.dart` defines `questionDetailProvider` as `FutureProvider.family<QuestionWithAnswers?, String>`, calling `GET /community/questions/$id`. Used in `question_detail_screen.dart` line 30.

### P1-12 · `ApiConstants.userProfile(id)` exists and used
**PASS.** `api_constants.dart` line 20: `static String userProfile(String id) => '/users/$id/profile'`. Used in both `public_profile_screen.dart` (`_publicProfileProvider`) and `connections_screen.dart` (`_userProfileProvider`).

### P1-13 · `_ConnectionTile` computes `otherUserId` correctly
**PASS.** `connections_screen.dart` `_ConnectionTile.build()`:
```dart
final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id ?? '';
final otherUserId = connection.requesterId == currentUserId
    ? connection.receiverId
    : connection.requesterId;
```
Same ternary is repeated correctly in `_remove()`. Logic is correct for a mutual connection model.

---

## P2 Items

### P2-14 · `dataconnect_generated/` absent
**PASS.** Directory does not exist under `mobile_app/`. No `dataconnect` files found anywhere in the repo.

### P2-15 · API client timeouts
**PASS.** `api_client.dart` `BaseOptions`: `connectTimeout: const Duration(seconds: 30)`, `receiveTimeout: const Duration(seconds: 60)`.

### P2-16 · `NavigationBar selectedIndex` based on route
**PASS.** `MainShell._selectedIndex(BuildContext)` reads `GoRouterState.of(context).matchedLocation` and returns the correct tab index for each route prefix. `selectedIndex` is set from this method.

### P2-17 · Google Sign-In uses `GoogleSignIn().signIn()` pattern
**PASS.** `auth_provider.dart` `_mobileGoogleSignIn()`: instantiates `GoogleSignIn()`, calls `.signIn()`, extracts `authentication`, builds `GoogleAuthProvider.credential(...)`, calls `FirebaseAuth.instance.signInWithCredential(...)`. No `signInWithProvider` call on mobile path.

### P2-18 · Question body validator does not require 20+ characters
**PASS.** `post_question_screen.dart`: the body `TextFormField` has no validator at all. Body is optional. Title validator requires only ≥10 characters, which is reasonable.

---

## Missing Verification

`flutter analyze` output is not recorded in the commit or any attached artifact. The environment has a documented inability to run `flutter analyze` (it hangs — see `fix-verification.txt`). Manual code inspection of all changed files found no obvious type errors, unresolved imports, or syntax issues:

- All new imports resolve to packages present in `pubspec.yaml`
- `publishableKey` is the correct parameter for supabase_flutter 2.18.3 (verified from package source)
- No `firebase_storage` imports remain in Dart source files
- All `ApiConstants` references used in changed files exist in the updated `api_constants.dart`
- `DropdownButtonFormField` with `initialValue` is valid Flutter API

No errors were found on manual inspection. The missing analyze run is noted as a limitation, not a blocker, because every changed file was manually verified for import resolution and type correctness.

---

## Verdict

**APPROVED** — all P0 items correct, all P1 items correct, all P2 items correct. No static analysis errors found by manual inspection of all changed files.
