# CampusCore Bug-Fix Implementation Plan

**Based on:** full-audit-report.md  
**Scope:** P0 → P2 fixes only. No theme changes. No matric number fields.  
**Build commands:** `flutter analyze` (Flutter), `npm run lint` (backend)  
**Test approach:** `flutter analyze` must pass with no errors after each fix group.  
  For admin auth, manual smoke-test login flow. No automated test suite exists.

---

## Fix 1 — Admin API URL (P0)

**What:** Change `defaultValue` in `AdminApiClient.baseUrl` from `localhost:3000` to the production Railway URL. This is the single most important fix — every admin API call fails in production until this is done.

**Files to edit:**
- `admin_dashboard/lib/core/utils/api_client.dart`

**Exact change:**
```dart
// BEFORE
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000/api/v1',
);

// AFTER
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://campuscore-production-3f94.up.railway.app/api/v1',
);
```

**Verify:** `flutter analyze` in `admin_dashboard/` — no errors.

---

## Fix 2 — Admin Firebase init (P0)

**What:** Pass `options: DefaultFirebaseOptions.currentPlatform` to `Firebase.initializeApp()`. The catch block currently swallows the error silently — replace the silent print+continue with a rethrow so a real failure surfaces rather than causing mysterious downstream failures.

**Files to edit:**
- `admin_dashboard/lib/main.dart`

**Exact change:**
```dart
// BEFORE
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization error: $e');
    // Continue without Firebase for development
  }
  runApp(const ProviderScope(child: CampusCoreAdminApp()));
}

// AFTER
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: CampusCoreAdminApp()));
}
```

Note: Removing the try/catch entirely is correct here — if Firebase fails to initialize, there is no sensible fallback for an admin dashboard that depends on Firebase auth. Let the error propagate so it is visible in the browser console and crash logs.

**Verify:** `flutter analyze` in `admin_dashboard/` — no errors.

---

## Fix 3 — Admin login: real Firebase auth + role check (P0)

**What:** The Sign In button currently does `context.go(AdminRoutes.dashboard)` with zero credential checking. Replace with a real auth flow:
1. Firebase `signInWithEmailAndPassword`
2. Get `idToken`
3. POST `/auth/login` with `{idToken}`
4. Check returned `user.role === 'admin'`
5. Save `accessToken` under key `'admin_token'` in `SharedPreferences`
6. Navigate to dashboard

Also wire GoRouter to redirect unauthenticated users back to `/` (login page).

**No `AdminAuthNotifier` exists anywhere in the codebase** — the admin dashboard has no provider directory at all. Create a new file for the auth notifier, placed in `admin_dashboard/lib/core/providers/` (create the directory).

**Files to create:**
- `admin_dashboard/lib/core/providers/admin_auth_provider.dart`  
  Contains `AdminAuthState`, `AdminAuthNotifier` (Riverpod `StateNotifier`), and `adminAuthProvider`.

**Files to edit:**
- `admin_dashboard/lib/presentation/screens/auth/admin_login_screen.dart`  
  Convert to `ConsumerStatefulWidget`, add loading/error state, wire Sign In button to `adminAuthProvider.notifier.signIn(email, password)`.
- `admin_dashboard/lib/app/router/admin_router.dart`  
  Add `redirect` callback to `GoRouter` that reads `adminAuthProvider` state and redirects to `AdminRoutes.login` if not authenticated.

### 3a — Create `admin_auth_provider.dart`

```dart
// admin_dashboard/lib/core/providers/admin_auth_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_client.dart';

class AdminAuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AdminAuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  AdminAuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AdminAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  AdminAuthNotifier() : super(const AdminAuthState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('admin_token');
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(isAuthenticated: true);
    }
  }

  Future<String?> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // 1. Firebase sign-in
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      final firebaseToken = await credential.user?.getIdToken();
      if (firebaseToken == null) {
        state = state.copyWith(isLoading: false, error: 'Firebase token error.');
        return 'Firebase token error.';
      }

      // 2. Backend token exchange
      final resp = await adminApi.post('/auth/login', data: {'idToken': firebaseToken});
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] != true) {
        final msg = body['message']?.toString() ?? 'Login failed.';
        state = state.copyWith(isLoading: false, error: msg);
        return msg;
      }

      final tokenData = body['data'] as Map<String, dynamic>;
      final user = tokenData['user'] as Map<String, dynamic>? ?? {};
      final role = user['role']?.toString() ?? '';

      // 3. Role check
      if (role != 'admin') {
        await FirebaseAuth.instance.signOut();
        const msg = 'Access denied. Admin accounts only.';
        state = state.copyWith(isLoading: false, error: msg);
        return msg;
      }

      // 4. Persist token
      final accessToken = tokenData['accessToken']?.toString() ?? '';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_token', accessToken);

      state = state.copyWith(isAuthenticated: true, isLoading: false);
      return null; // success
    } on FirebaseAuthException catch (e) {
      final msg = _firebaseMsg(e.code);
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    } catch (e) {
      const msg = 'Sign in failed. Please try again.';
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
    state = const AdminAuthState();
  }

  String _firebaseMsg(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'Account disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return 'Sign in failed ($code).';
    }
  }
}

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>(
  (_) => AdminAuthNotifier(),
);
```

### 3b — Edit `admin_login_screen.dart`

- Change `StatefulWidget` → `ConsumerStatefulWidget` / `State` → `ConsumerState`
- Add `bool _loading = false;` and `String? _error;` fields (or read from provider)
- Wire the Sign In button:
  ```dart
  onPressed: _loading
      ? null
      : () async {
          setState(() { _loading = true; _error = null; });
          final err = await ref
              .read(adminAuthProvider.notifier)
              .signIn(_emailCtrl.text, _passwordCtrl.text);
          if (!mounted) return;
          if (err != null) {
            setState(() { _loading = false; _error = err; });
          } else {
            context.go(AdminRoutes.dashboard);
          }
        },
  ```
- Add an error text widget below the button, conditionally shown when `_error != null`:
  ```dart
  if (_error != null) ...[
    const SizedBox(height: 12),
    Text(_error!, style: const TextStyle(color: AdminColors.error, fontSize: 13)),
  ],
  ```
- Show a `CircularProgressIndicator` inside the button while loading
- Add required import: `import 'package:flutter_riverpod/flutter_riverpod.dart';` and `import '../../../core/providers/admin_auth_provider.dart';`

### 3c — Edit `admin_router.dart`

Add a `redirect` to `GoRouter` that checks `adminAuthProvider`:

```dart
// Change provider from `Provider<GoRouter>` to `Provider<GoRouter>` reading adminAuthProvider
final adminRouterProvider = Provider<GoRouter>((ref) {
  // Listen to auth state so router rebuilds on auth changes
  final authState = ref.watch(adminAuthProvider);

  return GoRouter(
    initialLocation: AdminRoutes.login,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == AdminRoutes.login;
      if (!isLoggedIn && !isLoginRoute) return AdminRoutes.login;
      if (isLoggedIn && isLoginRoute) return AdminRoutes.dashboard;
      return null;
    },
    routes: [
      // ... existing routes unchanged ...
    ],
  );
});
```

The existing route list does not change — only `redirect` and the `ref.watch(adminAuthProvider)` line are added.

**Verify:** `flutter analyze` in `admin_dashboard/` — no errors. Manual test: open admin dashboard, clicking Sign In without credentials shows an error; signing in with a non-admin account shows "Access denied"; signing in with a valid admin account navigates to dashboard.

---

## Fix 4 — Courses + Home: add `departmentId` query param (P1)

**What:** `GET /courses` is called without `departmentId`, returning an empty list. The fix requires two sub-steps:

**Sub-step 4a — Add `departmentId` to `AppUser` model**

The backend returns `departmentId` in the user object (it's a column on the `users` table), but `AppUser.fromJson` doesn't parse it. Without this, the providers can't read it.

File: `web_app/lib/core/providers/auth_provider.dart`

- Add `final String? departmentId;` field to `AppUser`
- Add `this.departmentId,` to the constructor
- Add `departmentId: json['departmentId']?.toString(),` to `fromJson`
- Add `'departmentId': departmentId,` to `toJson`

**Sub-step 4b — Fix `coursesProvider`**

File: `web_app/lib/presentation/screens/courses/courses_screen.dart`

Change `coursesProvider` to read `currentUserProvider` and pass `departmentId`:

```dart
// BEFORE
final coursesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final resp = await api.get(ApiConstants.courses);
  final data = resp.data['data'];
  if (data is List) return data.cast<Map<String, dynamic>>();
  return [];
});

// AFTER
final coursesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final user = ref.read(currentUserProvider);
  final resp = await api.get(
    ApiConstants.courses,
    queryParameters: user?.departmentId != null
        ? {'departmentId': user!.departmentId}
        : null,
  );
  final data = resp.data['data'];
  if (data is List) return data.cast<Map<String, dynamic>>();
  return [];
});
```

Also add the import for `auth_provider.dart` at the top of `courses_screen.dart`:
```dart
import '../../../core/providers/auth_provider.dart';
```

**Sub-step 4c — Fix `homeDashboardProvider`**

File: `web_app/lib/presentation/screens/home/home_screen.dart`

Change the `api.get(ApiConstants.courses)` call inside `homeDashboardProvider` to include `departmentId`:

```dart
// BEFORE
final homeDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final results = await Future.wait([
      api.get(ApiConstants.courses),
      api.get(ApiConstants.resources),
      api.get(ApiConstants.gpa),
    ]);
    // ...

// AFTER
final homeDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final user = ref.read(currentUserProvider);
  try {
    final results = await Future.wait([
      api.get(
        ApiConstants.courses,
        queryParameters: user?.departmentId != null
            ? {'departmentId': user!.departmentId}
            : null,
      ),
      api.get(ApiConstants.resources),
      api.get(ApiConstants.gpa),
    ]);
    // rest unchanged
```

The import for `auth_provider.dart` is already present in `home_screen.dart` (line: `import '../../../core/providers/auth_provider.dart';`).

**Dependency note:** Fix 4b and 4c depend on Fix 4a (the `departmentId` field must exist on `AppUser` before the providers can read it).

**Verify:** `flutter analyze` in `web_app/` — no errors.

---

## Fix 5 — Profile update: correct endpoint and field names (P1)

**What:** Two bugs in tandem — wrong URL (`/users/profile` → should be `/users/me`) and wrong body fields (`firstName`/`lastName` → should be `fullName`).

**Sub-step 5a — Fix the endpoint constant**

File: `web_app/lib/core/constants/api_constants.dart`

```dart
// BEFORE
static const String updateProfile = '/users/profile';

// AFTER
static const String updateProfile = '/users/me';
```

**Sub-step 5b — Fix the request body**

File: `web_app/lib/core/providers/auth_provider.dart`, method `updateProfile` (around line 243)

```dart
// BEFORE
final resp = await _api.patch(ApiConstants.updateProfile, data: {
  'firstName': firstName,
  'lastName':  lastName,
});

// AFTER
final resp = await _api.patch(ApiConstants.updateProfile, data: {
  'fullName': '$firstName $lastName',
});
```

**Verify:** `flutter analyze` in `web_app/` — no errors.

---

## Fix 6 — Admin Users screen: replace mock data with real API (P2)

**What:** `UsersScreen` uses a hardcoded `List.generate(12, ...)`. Replace with a Riverpod `FutureProvider` calling `GET /admin/users`. Wire the suspend/activate icon buttons and the role-change dialog to the appropriate backend endpoints.

**No existing user provider exists in the admin dashboard.** Create one inside the new `core/providers/` directory (already created by Fix 3).

**Files to create:**
- `admin_dashboard/lib/core/providers/admin_users_provider.dart`

**Files to edit:**
- `admin_dashboard/lib/presentation/screens/users/users_screen.dart`

### 6a — Create `admin_users_provider.dart`

```dart
// admin_dashboard/lib/core/providers/admin_users_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/api_client.dart';

class AdminUser {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? academicLevel;
  final bool isActive;
  final String createdAt;

  const AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.academicLevel,
    required this.isActive,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id:            json['id']?.toString() ?? '',
      fullName:      json['fullName']?.toString() ?? json['full_name']?.toString() ?? '',
      email:         json['email']?.toString() ?? '',
      role:          json['role']?.toString() ?? 'student',
      academicLevel: json['academicLevel']?.toString() ?? json['academic_level']?.toString(),
      isActive:      json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      createdAt:     json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
    );
  }
}

final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) async {
  try {
    final response = await adminApi.get('/admin/users', params: {'limit': 100});
    final raw = response.data['data'] ?? response.data;
    final list = raw is List ? raw : (raw['users'] as List? ?? []);
    return list
        .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});
```

Note: Check the actual response shape from `AdminService.getAllUsers` — it may return `{ data: { users: [...], total: N } }` or just `{ data: [...] }`. The provider handles both with the `raw is List` guard above.

### 6b — Rewrite `UsersScreen`

- Change `StatefulWidget` → `ConsumerStatefulWidget`, `State` → `ConsumerState`
- Add import: `import 'package:flutter_riverpod/flutter_riverpod.dart';` and `import '../../../core/providers/admin_users_provider.dart';`
- Remove the static `_users` list
- In `build()`, call `ref.watch(adminUsersProvider)` and use `.when(loading:, error:, data:)` to render
- The `filtered` list is now derived from the `AdminUser` list (mapping `AdminUser.fullName` → display name, `AdminUser.isActive` → status, etc.)
- The suspend/activate icon button `onPressed`:
  ```dart
  onPressed: () async {
    final userId = u.id;
    final endpoint = u.isActive
        ? '/admin/users/$userId/suspend'
        : '/admin/users/$userId/activate';
    try {
      await adminApi.patch(endpoint);
      ref.invalidate(adminUsersProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action failed. Please try again.')),
        );
      }
    }
  },
  ```
- The role-change dialog `onTap` for each role option:
  ```dart
  onTap: () async {
    Navigator.pop(context);
    try {
      await adminApi.patch(
        '/admin/users/${u.id}/role',
        data: {'role': r.toLowerCase()},
      );
      ref.invalidate(adminUsersProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role change failed.')),
        );
      }
    }
  },
  ```
- Keep the UI structure (`DataTable`, `_RoleChip`, `_StatusChip`, mobile `ListView`) identical — only data source and callbacks change.

**Verify:** `flutter analyze` in `admin_dashboard/` — no errors.

---

## Fix 7 — Admin Departments screen: replace mock data with real API (P2)

**What:** `DepartmentsScreen` uses a static `_departments` list. Replace with a Riverpod provider calling `GET /departments`. Wire Add Department to `POST /departments`.

The existing `courses_management_screen.dart` already defines `adminDepartmentsProvider` (calls `GET /departments`) — **do not duplicate it**. Instead, import and reuse it.

**Files to read first:** `admin_dashboard/lib/presentation/screens/courses/courses_management_screen.dart` — verify `adminDepartmentsProvider` is accessible (it's defined at file scope in that file). Decision: move the provider to a shared location OR import it from `courses_management_screen.dart`.

**Decision:** Move `adminDepartmentsProvider` out of `courses_management_screen.dart` into a new shared provider file, and import it in both screens. This avoids a dependency on a screen file.

**Files to create:**
- `admin_dashboard/lib/core/providers/admin_departments_provider.dart`

**Files to edit:**
- `admin_dashboard/lib/presentation/screens/courses/courses_management_screen.dart` — remove the local `adminDepartmentsProvider` definition, import from the new shared file
- `admin_dashboard/lib/presentation/screens/departments/departments_screen.dart` — convert to `ConsumerWidget`, import shared provider, load real data

### 7a — Create `admin_departments_provider.dart`

```dart
// admin_dashboard/lib/core/providers/admin_departments_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/api_client.dart';

class DepartmentModel {
  final String id;
  final String name;
  final String? university;
  final bool isActive;

  const DepartmentModel({
    required this.id,
    required this.name,
    this.university,
    required this.isActive,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id:         json['id']?.toString() ?? '',
      name:       json['name']?.toString() ?? '',
      university: json['university']?.toString(),
      isActive:   json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
    );
  }
}

final adminDepartmentsProvider =
    FutureProvider<List<DepartmentModel>>((ref) async {
  try {
    final response = await adminApi.get('/departments');
    final data = (response.data['data'] ?? response.data) as List;
    return data
        .map((e) => DepartmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});
```

### 7b — Update `courses_management_screen.dart`

- Remove the `adminDepartmentsProvider` FutureProvider definition that currently exists in this file
- Add import: `import '../../../core/providers/admin_departments_provider.dart';`
- Update references: wherever `adminDepartmentsProvider` was used in this file, it now comes from the import — the usage code is unchanged

### 7c — Rewrite `departments_screen.dart`

- Change `StatelessWidget` → `ConsumerWidget`
- Add imports for Riverpod and `admin_departments_provider.dart`
- Remove static `_departments` list
- In `build()`, call `ref.watch(adminDepartmentsProvider)` and render with `.when(loading:, error:, data:)`
- The `GridView` renders `DepartmentModel` items instead of map entries
- The Add Department `ElevatedButton.icon onPressed` and the card's `InkWell onTap` wire to a dialog that POSTs `POST /departments` with `{name, university}` and then `ref.invalidate(adminDepartmentsProvider)`. The dialog can be modeled on the `_CreateLockDialog` pattern from `exam_lock_screen.dart`.
- Keep the card layout visually identical

**Verify:** `flutter analyze` in `admin_dashboard/` — no errors.

---

## Fix 8 — Admin Settings: wire exam lock toggle to backend (P2)

**What:** The `_examLockEnabled` toggle in `SettingsScreen` currently only calls `setState`. Wire it to the Exam Lock API by reusing `examLocksProvider` from `exam_lock_screen.dart`.

**Approach:** The exam lock concept has two states: "there is at least one currently-active exam lock" = enabled, "no active lock" = disabled. The toggle:
- When turned ON → open the `_CreateLockDialog` from `exam_lock_screen.dart` (reuse it). If the user cancels the dialog, reset the toggle to false.
- When turned OFF → call `DELETE /exam-lock/:id` on each currently-active lock.

This mirrors the design intent of the existing `ExamLockScreen` without duplicating the data model.

**Files to edit:**
- `admin_dashboard/lib/presentation/screens/settings/settings_screen.dart`

**Files to read first:**
- `admin_dashboard/lib/presentation/screens/exam_lock/exam_lock_screen.dart` — confirm `examLocksProvider`, `ExamLockModel`, and `_CreateLockDialog` are exported/accessible

**Exact changes:**

1. Convert `StatefulWidget` → `ConsumerStatefulWidget`, `State` → `ConsumerState`
2. Add imports:
   ```dart
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import '../exam_lock/exam_lock_screen.dart';
   import '../../../core/utils/api_client.dart';
   ```
3. Remove `bool _examLockEnabled = false;` local field — derive it from `examLocksProvider` instead:
   ```dart
   final locksAsync = ref.watch(examLocksProvider);
   final examLockEnabled = locksAsync.maybeWhen(
     data: (locks) => locks.any((l) => l.isCurrentlyActive),
     orElse: () => false,
   );
   ```
4. Wire the `_SettingsTile` for exam lock:
   ```dart
   _SettingsTile(
     // ... same icon/title/subtitle ...
     value: examLockEnabled,
     onChanged: (v) async {
       if (v) {
         // Turn ON — show create dialog
         await showDialog(
           context: context,
           builder: (_) => _CreateLockDialog(
             onCreated: () => ref.invalidate(examLocksProvider),
           ),
         );
       } else {
         // Turn OFF — delete all active locks
         final locks = locksAsync.asData?.value ?? [];
         for (final lock in locks.where((l) => l.isCurrentlyActive)) {
           try {
             await adminApi.delete('/exam-lock/${lock.id}');
           } catch (_) {}
         }
         ref.invalidate(examLocksProvider);
       }
     },
   ),
   ```
5. Keep `_newRegistrations` and `_aiAssistantEnabled` as local state (no backend endpoint exists for these — they stay as UI-only toggles with a TODO comment noting they need a backend endpoint).

**Verify:** `flutter analyze` in `admin_dashboard/` — no errors.

---

## Reports screen check (P2)

**Check:** Does a reports or community-flags backend endpoint exist?

**Finding from codebase scan:** The 17 registered backend modules are: `admin`, `ai`, `auth`, `community`, `connections`, `courses`, `departments`, `discussions`, `exam-lock`, `gamification`, `gpa`, `notifications`, `progress`, `resources`, `search`, `stellar`, `users`. **There is no `reports` or `flags` module.** The community module handles Q&A questions and answers, not reports/flags.

**Decision: Leave `ReportsScreen` as-is (static mock data).** No backend endpoint exists to wire to. Add a TODO comment at the top of the file noting that a reports/flags backend module is needed before this screen can be wired.

File: `admin_dashboard/lib/presentation/screens/reports/reports_screen.dart`
Add at top of class:
```dart
// TODO: Wire to backend once a reports/flags endpoint is implemented.
// Backend currently has no reports module. Static data is a placeholder only.
```

---

## Execution Order

The fixes must be applied in this order because of dependencies:

1. **Fix 1** — Admin API URL (prerequisite for all admin API calls to work)
2. **Fix 2** — Admin Firebase init (prerequisite for Fix 3 to work)
3. **Fix 3** — Admin login auth flow (depends on Fixes 1 + 2)
4. **Fix 4a** — Add `departmentId` to `AppUser` (prerequisite for Fixes 4b + 4c)
5. **Fix 4b** — `coursesProvider` departmentId (depends on Fix 4a)
6. **Fix 4c** — `homeDashboardProvider` departmentId (depends on Fix 4a)
7. **Fix 5** — Profile endpoint + body fields (independent of all other fixes)
8. **Fix 7a** — Create `admin_departments_provider.dart` (prerequisite for Fix 7b + 7c)
9. **Fix 7b** — Update `courses_management_screen.dart` to import shared provider (depends on Fix 7a, must happen before or simultaneously with 7c)
10. **Fix 7c** — Wire Departments screen to real API (depends on Fix 7a)
11. **Fix 6a** — Create `admin_users_provider.dart` (independent of 7 and 8)
12. **Fix 6b** — Wire Users screen to real API (depends on Fix 6a)
13. **Fix 8** — Wire Settings exam lock toggle (depends on Fix 3 auth context being present)
14. **Reports TODO** — Add placeholder comment (cosmetic, any time)

Fixes 5, 6, 7, 8 are independent of each other (they touch different files) and can be applied after Fixes 1–4a.

---

## Key facts discovered during exploration

| Fact | Impact |
|------|--------|
| `AppUser` has NO `departmentId` field | Fix 4 must add it to the model first |
| Backend user entity has `fullName` (not `firstName`+`lastName`) | Fix 5 body must be `{fullName: ...}` |
| `adminDepartmentsProvider` already exists in `courses_management_screen.dart` | Fix 7 must move it rather than duplicate |
| `examLocksProvider` + `ExamLockModel` + `_CreateLockDialog` are all in `exam_lock_screen.dart` | Fix 8 imports from there |
| No `admin/lib/core/providers/` directory exists yet | Fixes 3, 6, 7 all create files in it — create directory with Fix 3 |
| No reports backend module exists | Reports screen stays as mock with TODO |
| `GET /departments` is `@Public()` — no auth token required | `adminDepartmentsProvider` works even before Fix 3 |
| `GET /admin/users` requires admin JWT (`@Roles(UserRole.ADMIN)`) | Fix 6 only works correctly after Fix 3 stores a real token |
