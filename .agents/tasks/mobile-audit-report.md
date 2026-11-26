# CampusCore Mobile App — Full Audit Report

**Date:** 2025-07  
**Scope:** `mobile_app/` — Flutter Android app  
**Backend:** `https://campuscore-bfrq.onrender.com/api/v1` (NestJS)  
**Storage target:** Supabase (`https://oflxgcsaxzauivbywmwl.supabase.co`, bucket `Resources`)

---

## Executive Summary

The mobile app is structurally complete — every screen exists, routing is wired, and most providers call real backend endpoints. However it cannot work in production as shipped because:

1. **The API base URL defaults to `localhost:3000`** — the app calls your own phone's localhost and gets connection errors immediately.
2. **File uploads use Firebase Storage**, which the project has migrated away from. Every upload attempt will fail because `firebase_storage` is still in `pubspec.yaml` while `supabase_flutter` is absent.
3. **No Supabase SDK in pubspec** — the upload provider imports `FirebaseStorage`; replacing it requires adding `supabase_flutter`.
4. Several secondary issues (stub screens, missing API constants, wrong upvote URL, library not server-wired) degrade individual features but do not prevent login.

---

## P0 — Blocks All Use

### P0-1 · API base URL defaults to `localhost:3000`
| | |
|---|---|
| **File** | `mobile_app/lib/core/constants/api_constants.dart` line 9 |
| **What is broken** | `defaultValue: 'http://localhost:3000/api/v1'` — unless `API_BASE_URL` is passed at build time (no release build does this), every API call fails with "connection refused" on real devices. |
| **Fix** | Change the `defaultValue` to the production Render URL: |

```dart
// BEFORE
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000/api/v1',
);

// AFTER
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://campuscore-bfrq.onrender.com/api/v1',
);
```

---

### P0-2 · Firebase Storage still used for uploads; Supabase missing from pubspec
| | |
|---|---|
| **File** | `mobile_app/pubspec.yaml` — `firebase_storage: ^12.4.0` present, `supabase_flutter` absent |
| **File** | `mobile_app/lib/presentation/providers/upload_provider.dart` lines 4, 55–80 |
| **What is broken** | `upload_provider.dart` imports `firebase_storage` and uploads files to Firebase Storage. The project uses Supabase Storage. Every resource upload fails. |
| **Fix** | 1. In `pubspec.yaml`: remove `firebase_storage: ^12.4.0`, add `supabase_flutter: ^2.5.2`. |
| | 2. In `main.dart`: initialize Supabase after Firebase (mirror `web_app/lib/main.dart`): |

```dart
await Supabase.initialize(
  url: 'https://oflxgcsaxzauivbywmwl.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9mbHhnY3NheHphdWl2Ynl3bXdsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU1MTE1MDEsImV4cCI6MjEwMTA4NzUwMX0.VsnSm-uuVv_4P2fNK5_7fL6LHmVmt90AGtTCwoD0Pxc',
);
```

| | 3. Create `mobile_app/lib/core/storage/supabase_storage.dart` — copy exactly from `web_app/lib/core/storage/supabase_storage.dart` (identical logic works on mobile). |
| | 4. Replace the Firebase Storage upload block in `upload_provider.dart` upload method (lines 55–80) with a `SupabaseStorageService.uploadFile(...)` call — same pattern as the web app. |

---

### P0-3 · Render backend wake-up ping missing on mobile
| | |
|---|---|
| **File** | `mobile_app/lib/main.dart` |
| **What is broken** | The web app pings `https://campuscore-bfrq.onrender.com/api/v1/departments` every 10 minutes to prevent cold-start delays (Render free tier sleeps after inactivity). The mobile app has no such ping. First-time logins on a cold backend take ~30 seconds and may time out. |
| **Fix** | Add the same `Timer.periodic` Dio ping from `web_app/lib/main.dart` to `mobile_app/lib/main.dart` after Supabase init. |

---

## P1 — Breaks Specific Features

### P1-1 · Library is not wired to the backend
| | |
|---|---|
| **File** | `mobile_app/lib/presentation/providers/library_provider.dart` — entire file |
| **What is broken** | `personalLibraryProvider` always returns an empty list (comment says "Until the screen wires in the resource list"). The Saved tab in `library_screen.dart` is permanently empty. The backend has a working `/library` endpoint. |
| **Fix** | Replace `personalLibraryProvider` with a `FutureProvider` that calls `GET /library` (see `web_app` equivalent). Add `ApiConstants.library = '/library'` and `ApiConstants.libraryRemove(id)`. Wire `bookmarkProvider.toggle()` to also call `POST /library` (save) / `DELETE /library/:id` (remove) so bookmarks persist server-side. |

---

### P1-2 · AI assistant lacks conversation history support
| | |
|---|---|
| **File** | `mobile_app/lib/presentation/providers/ai_provider.dart` — `ExplainNotifier.explain()` |
| **What is broken** | The backend's `POST /ai/explain` accepts a `history` array for multi-turn context. The mobile `explainProvider` never sends `history`. Each message is therefore stateless — the AI cannot refer to previous messages in the same session. The web app implements full conversation history (see `web_app/lib/presentation/screens/ai/ai_screen.dart`). |
| **Fix** | The mobile AI screen is tab-based (not chat-based). Upgrade it to a chat-style interface matching the web app — single input field, message list, mode selector chips, history sent to `/ai/explain`. Also add `ConversationStorage` (copy from `web_app/lib/core/storage/conversation_storage.dart` — uses `SharedPreferences`, already available in `pubspec.yaml`) for conversation persistence. |

---

### P1-3 · Home screen community section is hardcoded stub
| | |
|---|---|
| **File** | `mobile_app/lib/presentation/screens/home/home_screen.dart` — `_DiscussionPreviewList` class (lines ~270–310) |
| **What is broken** | Shows two hardcoded fake questions ("What is the optimal protein level for catfish juveniles?", "Can someone explain the nitrogen cycle?"). Does not call the backend. |
| **Fix** | Replace `_DiscussionPreviewList` with a real provider call to `allQuestionsProvider`, taking the first 2–3 items. Pattern already exists — `_RealCoursesList` in the same file does it correctly. |

---

### P1-4 · Profile screen shows hardcoded badges
| | |
|---|---|
| **File** | `mobile_app/lib/presentation/screens/profile/profile_screen.dart` lines ~85–96 |
| **What is broken** | Displays two hardcoded badges (`_Badge(label: 'Fresh Scholar')` / `_Badge(label: 'Bookworm')`). Does not call `GET /gamification/badges`. Users see badges that are wrong or not earned. |
| **Fix** | Add `final badgesProvider = FutureProvider<List>` calling `GET /gamification/badges`. Render real earned badges from the API. If the list is empty, show "No badges yet". Also add `ApiConstants.badges = '/gamification/badges'` (already defined but the screen doesn't use it). |

---

### P1-5 · Profile screen hardcodes department name
| | |
|---|---|
| **File** | `mobile_app/lib/presentation/screens/profile/profile_screen.dart` line ~55 |
| **What is broken** | `'${user.displayLevel} • Fisheries & Aquaculture'` — department name is hardcoded. |
| **Fix** | Use `ref.watch(primaryDepartmentProvider)` to get the real department name, same as `home_screen.dart` does in `_DepartmentCard`. |

---

### P1-6 · Sign-out does not redirect to login/onboarding
| | |
|---|---|
| **File** | `mobile_app/lib/presentation/screens/profile/profile_screen.dart` line ~107 |
| **What is broken** | `ref.read(authProvider.notifier).signOut()` clears tokens and Firebase state but does not navigate away. The user stays on the Profile screen, which then shows an error state from the broken `currentUserProvider` call. |
| **Fix** | After `signOut()`, navigate to `AppRoutes.onboarding` (or `AppRoutes.login`). The `appRouterProvider` redirect guard checks `currentUserProvider`, but that only runs on route changes — an explicit `context.go(AppRoutes.onboarding)` is needed. |

---

### P1-7 · Answer upvote URL is wrong
| | |
|---|---|
| **File** | `mobile_app/lib/presentation/providers/discussions_provider.dart` line ~132 |
| **What is broken** | `upvoteAnswer` posts to `'${ApiConstants.questions}/answers/$answerId/upvote'` which resolves to `/community/questions/answers/{id}/upvote`. The correct backend route is `POST /community/answers/{id}/upvote`. |
| **Fix** | Change the path in `upvoteAnswer`: |

```dart
// BEFORE
await api.post('${ApiConstants.questions}/answers/$answerId/upvote');

// AFTER
await api.post('/community/answers/$answerId/upvote');
```

---

### P1-8 · `answersProvider` fetches question detail, not answers separately
| | |
|---|---|
| **File** | `mobile_app/lib/presentation/providers/community_provider.dart` lines ~48–58 |
| **What is broken** | `answersProvider` calls `GET /community/questions/:id` (the full question+answers endpoint) and extracts `data['answers']`. This works if the backend returns them in the top-level response, but the backend returns `{ question, answers }` unwrapped in `data`. The current code does `response.data['data']` and then `['answers']`, which may miss data if the response wrapper changes. More importantly, `questionDetailScreen` fetches answers separately but the question itself comes from `allQuestionsProvider` cache — if the cache is empty (e.g. navigated directly from a notification), the question title shows as blank. |
| **Fix** | Add a `questionDetailProvider(id)` that calls `GET /community/questions/:id` and returns both question and answers. The `question_detail_screen.dart` should watch `questionDetailProvider` directly instead of combining `allQuestionsProvider` + `answersProvider`. |

---

### P1-9 · `api_constants.dart` is missing many endpoints used in screens
| | |
|---|---|
| **File** | `mobile_app/lib/core/constants/api_constants.dart` |
| **What is broken** | Several endpoints are hardcoded inline in screens/providers as string literals, not constants: |
|  | • `notifications_screen.dart`: `/notifications/$id/read` and `/notifications/read-all` — hardcoded strings, not using constants |
|  | • `discussions_provider.dart`: `/community/answers/$id/upvote`, `/community/questions/$id/upvote`, `/community/questions/$id/answers` — no constants |
|  | • `public_profile_screen.dart`: `ApiConstants.me.replaceAll('/me', '')` to build `/users/$id/profile` — string manipulation hack |
|  | • No `ApiConstants.library`, `ApiConstants.libraryRemove(id)`, `ApiConstants.unreadCount` etc. |
| **Fix** | Add the missing constants. Mirror the `web_app/lib/core/constants/api_constants.dart` which is fully complete. Key additions needed: |

```dart
// Notifications
static const String notificationsReadAll = '/notifications/read-all';
static const String unreadCount = '/notifications/unread-count';
static String markNotificationRead(String id) => '/notifications/$id/read';

// Community (add these helper methods)
static String questionAnswers(String id) => '/community/questions/$id/answers';
static String upvoteQuestion(String id) => '/community/questions/$id/upvote';
static String upvoteAnswer(String id) => '/community/answers/$id/upvote';
static String questionDetail(String id) => '/community/questions/$id';

// Users
static String userProfile(String id) => '/users/$id/profile';

// Library
static const String library = '/library';
static String libraryRemove(String id) => '/library/$id';
```

---

### P1-10 · `public_profile_screen.dart` uses URL manipulation hack for profile endpoint
| | |
|---|---|
| **File** | `mobile_app/lib/presentation/screens/profile/public_profile_screen.dart` lines ~74–76 |
| **What is broken** | `ApiConstants.me.replaceAll('/me', '')` is used to derive `/users` from `/users/me`. This is fragile — any change to the `/me` constant breaks the public profile endpoint silently. |
| **Fix** | After adding `ApiConstants.userProfile(id)`, use it directly: `api.get(ApiConstants.userProfile(userId))`. |

---

### P1-11 · Connections screen displays generic "User" label (no names)
| | |
|---|---|
| **File** | `mobile_app/lib/presentation/screens/profile/connections_screen.dart` `_ConnectionTile` widget |
| **What is broken** | Every connection shows `title: const Text('User')`. The backend connection entity only stores `requesterId`/`receiverId` UUIDs, not embedded user names. The screen needs to fetch user profiles to show names. |
| **Fix** | In `_ConnectionTile`, derive the other user's ID (`connection.requesterId == currentUserId ? connection.receiverId : connection.requesterId`) then watch `_publicProfileProvider(otherUserId)` (already defined in `public_profile_screen.dart`) to display their name and avatar. |

---

### P1-12 · `offlineResourcesProvider` / `offlineCoursesProvider` exist but screens use `resourcesByCourseProvider` / `coursesProvider` instead
| | |
|---|---|
| **File** | `mobile_app/lib/presentation/providers/offline_resources_provider.dart` |
| **What is broken** | `offline_resources_provider.dart` implements a proper cache-first offline strategy for both resources and courses. However, `resources_screen.dart` and `courses_screen.dart` watch `resourcesByCourseProvider` / `coursesProvider` which have no offline fallback. The `OfflineBanner` in `resources_screen.dart` wraps a provider that never writes to Hive. |
| **Fix** | Switch `resources_screen.dart` to use `offlineResourcesProvider(courseId)` and `courses_screen.dart` / `courses_provider.dart` to use `offlineCoursesProvider(dept.id)` (or write to Hive inside the existing providers after a successful fetch). |

---

### P1-13 · Question body forced required on mobile (backend makes it optional)
| | |
|---|---|
| **File** | `mobile_app/lib/presentation/screens/community/post_question_screen.dart` lines ~97–105 |
| **What is broken** | The form validator requires body to be at least 20 characters. The backend DTO (`PostQuestionDto`) marks `body` as `@IsOptional()`. Users who only want a title-only question get blocked on mobile (web app doesn't block). |
| **Fix** | Change the body validator to make it optional (or at minimum allow shorter descriptions). Align with the backend: body is optional. Remove the "provide more detail" enforcement: |

```dart
// BEFORE
validator: (v) {
  if (v == null || v.trim().isEmpty) return 'Please provide details';
  if (v.trim().length < 20) return 'Please provide more detail (at least 20 characters)';
  return null;
},

// AFTER — body is optional
validator: (v) => null,  // or show hint but don't block submission
```

---

## P2 — Quality / Polish Issues

### P2-1 · Nunito font not loaded
| | |
|---|---|
| **File** | `mobile_app/pubspec.yaml` lines ~62–74 |
| **What is broken** | The entire `fonts:` section is commented out. `AppTheme` sets `fontFamily: 'Nunito'` but the font files are never declared, so Flutter silently falls back to the system default font. |
| **Fix** | Add Nunito font files to `mobile_app/assets/fonts/` (download from Google Fonts or copy from the web app if they exist there), then uncomment the fonts block in `pubspec.yaml`. |

---

### P2-2 · `dataconnect_generated/` directory contains stale Firebase DataConnect stubs
| | |
|---|---|
| **File** | `mobile_app/lib/dataconnect_generated/` — 20+ files |
| **What is broken** | These are auto-generated Firebase DataConnect files (a Firebase feature not used by CampusCore). They reference Firebase-specific types and will not compile if DataConnect package is ever added. They add confusion and dead code. |
| **Fix** | Delete the entire `mobile_app/lib/dataconnect_generated/` directory. It is not imported anywhere in the app. |

---

### P2-3 · Router redirect guard re-runs on every navigation but `currentUserProvider` is not invalidated on login
| | |
|---|---|
| **File** | `mobile_app/lib/app/router/app_router.dart` lines ~42–52 |
| **What is broken** | The GoRouter redirect checks `ref.read(currentUserProvider).valueOrNull`. `currentUserProvider` is a `FutureProvider` — it fires once and caches. After login the user object becomes available, but if the router re-evaluates before `currentUserProvider` resolves (or if the provider is stale), the redirect to `integrityPolicy` can trigger incorrectly. |
| **Fix** | After successful login/registration in `auth_provider.dart`, call `ref.invalidate(currentUserProvider)` so the router guard picks up the fresh user. The `registerWithFirebase` method already sets `state = AsyncValue.data(firebaseUser)` but doesn't invalidate the user provider. |

---

### P2-4 · No Render cold-start handling (timeout too short)
| | |
|---|---|
| **File** | `mobile_app/lib/core/network/api_client.dart` line 15 |
| **What is broken** | `connectTimeout: Duration(seconds: 15)`. The Render free tier can take 25–35 seconds to wake from sleep. The first API call on cold start will time out before the server responds, resulting in a misleading "connection error" on login. |
| **Fix** | Increase `connectTimeout` to `Duration(seconds: 30)` and `receiveTimeout` to `Duration(seconds: 60)`. Add a retry-once mechanism in `_tryRefreshToken` and any critical-path calls (login, `/users/me`). |

---

### P2-5 · Google Sign-In on mobile falls through to `signInWithProvider` (web API)
| | |
|---|---|
| **File** | `mobile_app/lib/presentation/providers/auth_provider.dart` lines ~73–82 |
| **What is broken** | `_mobileGoogleSignIn()` calls `FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider())` which is the web approach. On Android it may work but proper Google Sign-In on Android requires the `google_sign_in` package (already in `pubspec.yaml`) with `GoogleSignIn().signIn()`. The current approach skips the native Google account picker. |
| **Fix** | Implement `_mobileGoogleSignIn()` using `GoogleSignIn` package: |

```dart
import 'package:google_sign_in/google_sign_in.dart';

Future<UserCredential?> _mobileGoogleSignIn() async {
  final googleUser = await GoogleSignIn().signIn();
  if (googleUser == null) return null;
  final googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  return FirebaseAuth.instance.signInWithCredential(credential);
}
```

---

### P2-6 · Token storage uses `SharedPreferences` (not secure storage)
| | |
|---|---|
| **File** | `mobile_app/lib/core/storage/token_storage.dart` |
| **What is broken** | JWT access and refresh tokens are stored in `SharedPreferences` which is not encrypted. On rooted devices or via Android backup, tokens can be extracted. Best practice is to use `flutter_secure_storage`. |
| **Fix** | Add `flutter_secure_storage: ^9.0.0` to `pubspec.yaml`. Replace `SharedPreferences` calls with `FlutterSecureStorage` in `token_storage_mobile.dart`. This is a security hardening improvement. |

---

### P2-7 · `NavigationBar` does not highlight the selected item
| | |
|---|---|
| **File** | `mobile_app/lib/app/router/app_router.dart` — `MainShell.build()` |
| **What is broken** | `NavigationBar` uses `onDestinationSelected` but has no `selectedIndex` property set. The currently selected destination is never highlighted — all tabs always appear unselected visually. |
| **Fix** | Track selected index based on the current GoRouter location: |

```dart
Widget build(BuildContext context) {
  final location = GoRouterState.of(context).matchedLocation;
  final index = _indexFromLocation(location);
  return Scaffold(
    body: child,
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) { /* ... */ },
      destinations: const [ /* ... */ ],
    ),
  );
}

int _indexFromLocation(String location) {
  if (location.startsWith('/courses')) return 1;
  if (location.startsWith('/community')) return 2;
  if (location.startsWith('/library')) return 3;
  if (location.startsWith('/profile')) return 4;
  return 0;
}
```

---

### P2-8 · `_BookmarkCard` in library screen shows raw UUID instead of resource title
| | |
|---|---|
| **File** | `mobile_app/lib/presentation/screens/library/library_screen.dart` — `_BookmarkCard` |
| **What is broken** | Shows `'Resource $resourceId'` — just the UUID. The Bookmarks tab is only backed by local in-memory IDs (no resource object available). |
| **Fix** | After fixing P1-1 (library from backend), bookmarks will have full `ResourceModel` objects — replace `_BookmarkCard` with `_LibraryResourceCard`. If keeping local-only bookmarks in addition, fetch the resource by ID using `_resourceByIdProvider(resourceId)` (already defined in `resource_viewer_screen.dart`). |

---

### P2-9 · `_ConnectionTile.otherUserId` calculation is wrong
| | |
|---|---|
| **File** | `mobile_app/lib/presentation/screens/profile/connections_screen.dart` `_ConnectionTile.build()` line ~71 |
| **What is broken** | `connection.requesterId == connection.receiverId` — this is only true when someone connects to themselves (impossible). It should be `connection.requesterId == currentUserId ? connection.receiverId : connection.requesterId`. The current code always picks `receiverId`. |
| **Fix** | Inject or watch `currentUserProvider` in `_ConnectionTile` and compute: |

```dart
final currentId = ref.watch(currentUserProvider).valueOrNull?.id ?? '';
final otherUserId = connection.requesterId == currentId
    ? connection.receiverId
    : connection.requesterId;
```

---

### P2-10 · FCM background handler imports from app code (potential init order issue)
| | |
|---|---|
| **File** | `mobile_app/lib/main.dart` line 7 and `fcm_service.dart` line ~62 |
| **What is broken** | `firebaseMessagingBackgroundHandler` is defined in `fcm_service.dart` and registered before `OfflineCache.init()`. Background handlers run in a separate isolate where app state is not initialized. The handler only calls `debugPrint`, which is safe — but if it ever needs to access `Hive` or `Riverpod`, it will crash silently. |
| **Fix** | Move `firebaseMessagingBackgroundHandler` to a top-level function in `main.dart` (not inside a class) and ensure it only uses Flutter primitives. This is low priority since the current handler only prints, but document it. |

---

### P2-11 · `discussions_screen.dart` has its own `AppBar` but is embedded in `CommunityScreen`'s `TabBarView`
| | |
|---|---|
| **File** | `mobile_app/lib/presentation/screens/community/discussions_screen.dart` — `DiscussionsScreen.build()` |
| **What is broken** | `DiscussionsScreen` extends `ConsumerStatefulWidget` and returns a `Scaffold` with its own `AppBar`. When embedded as the second tab in `CommunityScreen`'s `TabBarView`, this creates a nested `Scaffold` — two app bars stack, or the inner one becomes invisible and its level filter chips may not render correctly. |
| **Fix** | Refactor `DiscussionsScreen` into a stateful widget that returns only the body content (Column with chips + list), not a full Scaffold. The FAB for "New Thread" should be moved to the parent `CommunityScreen` using `AnimatedBuilder` on `_tabCtrl` (already done for "Ask Question"). |

---

### P2-12 · `upvoteAnswer` path (already P1-7) also affects `question_detail_screen.dart`
| | |
|---|---|
| **File** | `mobile_app/lib/presentation/screens/community/question_detail_screen.dart` `_AnswerCard` |
| **What is broken** | `_AnswerCard` calls `ref.read(upvoteProvider.notifier).upvoteAnswer(...)` which uses the wrong URL (covered in P1-7). Both the community screen and the question detail screen will silently fail to upvote answers. |

---

## Summary Table

| # | Priority | File | Description |
|---|----------|------|-------------|
| P0-1 | P0 | `core/constants/api_constants.dart:9` | API base URL is `localhost:3000` |
| P0-2 | P0 | `pubspec.yaml`, `providers/upload_provider.dart` | Firebase Storage used; Supabase missing |
| P0-3 | P0 | `main.dart` | No Render cold-start ping |
| P1-1 | P1 | `providers/library_provider.dart` | Library not wired to backend |
| P1-2 | P1 | `providers/ai_provider.dart` + `screens/ai_assistant/` | AI lacks conversation history |
| P1-3 | P1 | `screens/home/home_screen.dart` | Fake hardcoded community questions |
| P1-4 | P1 | `screens/profile/profile_screen.dart` | Hardcoded badges |
| P1-5 | P1 | `screens/profile/profile_screen.dart:55` | Hardcoded department name |
| P1-6 | P1 | `screens/profile/profile_screen.dart:107` | Sign-out no redirect |
| P1-7 | P1 | `providers/discussions_provider.dart:132` | Wrong upvote-answer URL |
| P1-8 | P1 | `providers/community_provider.dart:48` | Question detail loads from stale cache |
| P1-9 | P1 | `core/constants/api_constants.dart` | Missing many endpoint constants |
| P1-10 | P1 | `screens/profile/public_profile_screen.dart:74` | URL hack to build profile endpoint |
| P1-11 | P1 | `screens/profile/connections_screen.dart` | Connections show "User" not real name |
| P1-12 | P1 | `providers/offline_resources_provider.dart` | Offline providers unused by screens |
| P1-13 | P1 | `screens/community/post_question_screen.dart:97` | Body forced required (backend optional) |
| P2-1 | P2 | `pubspec.yaml:62` | Nunito font not loaded |
| P2-2 | P2 | `lib/dataconnect_generated/` | Stale Firebase DataConnect stubs |
| P2-3 | P2 | `app/router/app_router.dart:42` | Router redirect uses stale user provider |
| P2-4 | P2 | `core/network/api_client.dart:15` | Timeout too short for cold Render start |
| P2-5 | P2 | `providers/auth_provider.dart:73` | Google Sign-In uses web API on mobile |
| P2-6 | P2 | `core/storage/token_storage.dart` | Tokens in unencrypted SharedPreferences |
| P2-7 | P2 | `app/router/app_router.dart` (MainShell) | Bottom nav never highlights selected tab |
| P2-8 | P2 | `screens/library/library_screen.dart` | Bookmarks show raw UUID |
| P2-9 | P2 | `screens/profile/connections_screen.dart:71` | Wrong other-user-ID calculation |
| P2-10 | P2 | `main.dart`, `core/services/fcm_service.dart` | FCM background handler in wrong scope |
| P2-11 | P2 | `screens/community/discussions_screen.dart` | Nested Scaffold in TabBarView |
| P2-12 | P2 | `screens/community/question_detail_screen.dart` | Upvote-answer wrong URL (same as P1-7) |

---

## What is Working Correctly (No Fixes Needed)

- Firebase options correctly point to `campuscore-5658f` project — `android`, `web` configs correct
- `google-services.json` present and valid (project `campuscore-5658f`, package `com.campuscore.app`)
- `AndroidManifest.xml` — correct permissions, FCM service registered, POST_NOTIFICATIONS declared
- Auth flow: login, register, forgot-password — all call real Firebase + backend token exchange
- Register screen: no matric number required (field is in edit profile only, optional)
- Department ID is passed when fetching courses (`coursesProvider` queries `departmentId`)
- `token_storage.dart` — correct platform branching (web vs mobile)
- `api_client.dart` — JWT attach + 401 refresh interceptor working
- `FCM service` — token upload to backend on login, notification deep-link navigation
- `OfflineCache` (Hive) — initialized correctly; `offlineResourcesProvider` pattern is correct
- GPA calculator — fully wired to backend (save/delete/CGPA), trend chart working
- Courses screen — level filter tabs, correct API call with `departmentId`
- Course detail screen — 6 tabs, resources filtered by type all wired
- Community Q&A — paginated questions, post question, post answer all wired
- Discussions — threads, create thread, replies all wired
- Connections — send request, accept, remove, status all wired; `ConnectButton` works
- Progress tracker — streak, semester overview, per-course topic progress all wired
- Notifications — list, unread count, mark read, mark all read all wired
- Search — `GET /search?q=...&departmentId=...` wired, results render
- GoRouter — all 20+ routes defined, shell navigation correct, integrity policy redirect guard
- `error_helper.dart` — friendly DioException messages including exam-lock 403
- `app_theme.dart` — `AppColors` constants, Material 3, full theme (no hardcoded hex in widgets)
