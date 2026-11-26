# Technical Design: Mobile App Full Sync & Feature Parity
*(Revision 2 — addresses all findings from design-review.json)*

---

## Overview

The work divides into two layers. The first is build infrastructure: confirming the exact state of `pubspec.yaml` and both Gradle files so the developer knows precisely what to run to get a clean build, with a corrected explanation of what each failure was and how to fully recover. The second is UI: expanding the home screen Quick Actions from four items to nine by converting the current horizontal `Row` into a `GridView.count`, wrapping each grid cell in a `Center` to fix vertical alignment, switching text overflow to `ellipsis`, creating three new placeholder screens, and registering three new routes in `app_router.dart`. Additionally, `offlineResourcesProvider` needs a one-line guard to omit `courseId` from the query string when it is empty, so that navigating to Resources from the home screen returns all resources instead of sending a malformed query.

No backend changes, no changes to the web or admin apps, and no changes to the five-tab bottom navigation bar.

Tech stack: Flutter (Dart), GoRouter for navigation, Riverpod for state, `AppColors`/`AppTheme` for theming — consistent with every existing screen.

---

## 1. Dependency and Build Fix

### 1.1 `file_picker` version

`pubspec.yaml` already declares `file_picker: ^8.3.7`. The pub solver error shown in the user's messages would only occur if an older `pubspec.lock` is still present and the solver is reading a pinned `8.0.6` from it. The fix is not `flutter clean` alone (which only removes `build/` and `.dart_tool/`); it requires forcing the solver to re-read and re-lock.

**Correct recovery sequence:**

```powershell
cd mobile_app
Remove-Item pubspec.lock        # force solver to pick fresh versions
flutter pub get                 # re-solve from pubspec.yaml constraints
```

If `flutter pub get` still fails after deleting `pubspec.lock`, the pub cache itself may hold a corrupt or outdated entry:

```powershell
flutter pub cache repair        # re-downloads and re-extracts all cached packages
flutter pub get
```

### 1.2 `compileSdk` and `targetSdk`

`android/app/build.gradle` already declares `compileSdk 36` and `targetSdk 36`. The root `android/build.gradle` also applies `compileSdkVersion 36` to every subproject via `afterEvaluate`. **No change needed to either Gradle file.**

The `CheckAarMetadataWorkAction` failure was caused by the old `file_picker 8.0.6` AAR (compiled against API 34), which conflicted with `flutter_plugin_android_lifecycle` requiring API 36+. Updating `file_picker` to `^8.3.7` (already in `pubspec.yaml`) and running the correct build sequence resolves it.

### 1.3 Developer runbook

Both `pubspec.yaml` and both Gradle files are already correct. The only required actions are:

```powershell
cd mobile_app
Remove-Item pubspec.lock        # remove stale lock file
flutter pub get                 # re-solve dependencies
flutter clean                   # remove old Gradle/build artefacts so device sees new theme
flutter run                     # rebuild and deploy to device
```

`flutter clean` is still useful here — it removes cached Gradle/AAR artefacts that can cause the device to run stale compiled code even after pub re-solves correctly. The two steps serve distinct purposes: `Remove-Item pubspec.lock` + `flutter pub get` fix the solver; `flutter clean` fixes the stale APK/AAR cache.

---

## 2. Home Screen Quick Actions Grid

### 2.1 Current state

`lib/presentation/screens/home/home_screen.dart` renders Quick Actions as a horizontal `Row` with four `_QuickAction` widgets separated by `SizedBox(width: 16)`. This hard-codes exactly four actions with no reflow.

### 2.2 Layout decision

Replace the `Row` with a `GridView.count` with these properties:

| Property | Value | Rationale |
|---|---|---|
| `crossAxisCount` | 3 | Three columns give each cell ≈ 92 dp on a 360 dp screen, comfortably surrounding the 52 dp icon. Four columns gives ≈ 68 dp — only 8 dp clear of the icon, visually cramped. |
| `crossAxisSpacing` | 12 | Fits three columns within 20 dp horizontal padding on each side. |
| `mainAxisSpacing` | 16 | Vertical breathing room between rows. |
| `shrinkWrap` | `true` | Grid lives inside a `SliverToBoxAdapter` → `Column`; must not expand infinitely. |
| `physics` | `NeverScrollableScrollPhysics()` | The parent `CustomScrollView` owns scrolling. |
| `childAspectRatio` | 0.85 | At 92 dp cell width this yields ≈ 108 dp cell height, accommodating 52 dp icon + 6 dp gap + two-line label at 11 sp (≈ 26 dp) with the `Center` wrapper distributing the remaining space. This ratio is only valid when each cell is wrapped in `Center` (see §2.4). |

Three columns × three rows = nine slots exactly, so all nine items from FR-4 are retained. No item needs to be removed.

### 2.3 Nine Quick Actions — final list

| # | Label | Icon | `AppColors` constant | Route |
|---|---|---|---|---|
| 1 | AI Tutor | `Icons.auto_awesome` | `accent` | `AppRoutes.aiAssistant` |
| 2 | GPA Calc | `Icons.calculate` | `info` | `AppRoutes.gpaCalculator` |
| 3 | Progress | `Icons.trending_up` | `success` | `AppRoutes.progress` |
| 4 | Upload | `Icons.upload_file` | `primaryLight` | `AppRoutes.uploadResource` |
| 5 | Resources | `Icons.folder_open` | `primary` | `AppRoutes.resources` |
| 6 | Connections | `Icons.people` | `primaryDark` | `AppRoutes.connections` |
| 7 | Leaderboard | `Icons.leaderboard` | `warning` | `AppRoutes.leaderboard` |
| 8 | Study Groups | `Icons.groups` | `accentLight` | `AppRoutes.studyGroups` |
| 9 | Announcements | `Icons.campaign` | `error` | `AppRoutes.announcements` |

No hardcoded hex values. All colors are `AppColors` constants.

### 2.4 `_QuickAction` widget — required changes

The existing `_QuickAction` uses `Column(mainAxisSize: MainAxisSize.min)` and `overflow: TextOverflow.visible`. Inside a `GridView.count` cell, `mainAxisSize: min` collapses the column to its minimum height and aligns it at the top-left of the allocated cell area, leaving uneven dead space below. `TextOverflow.visible` can render label text outside the cell boundary and visually bleed into adjacent cells.

Two changes are required:

1. **Wrap each grid child in `Center`** so the collapsed column is vertically centred within its allocated cell.
2. **Change `overflow` to `TextOverflow.ellipsis`** to prevent text bleed.

The cleanest approach is to introduce a thin `_QuickActionCell` wrapper in `home_screen.dart` rather than modifying `_QuickAction` itself (preserving it for any future non-grid use):

```dart
class _QuickActionCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCell({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
```

The Quick Actions section of `HomeScreen.build` becomes:

```dart
// Quick actions
const _SectionHeader(title: 'Quick Actions'),
const SizedBox(height: 12),
GridView.count(
  crossAxisCount: 3,
  crossAxisSpacing: 12,
  mainAxisSpacing: 16,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  childAspectRatio: 0.85,
  children: [
    _QuickActionCell(icon: Icons.auto_awesome,  label: 'AI Tutor',      color: AppColors.accent,       onTap: () => context.push(AppRoutes.aiAssistant)),
    _QuickActionCell(icon: Icons.calculate,      label: 'GPA Calc',      color: AppColors.info,         onTap: () => context.push(AppRoutes.gpaCalculator)),
    _QuickActionCell(icon: Icons.trending_up,    label: 'Progress',      color: AppColors.success,      onTap: () => context.push(AppRoutes.progress)),
    _QuickActionCell(icon: Icons.upload_file,    label: 'Upload',        color: AppColors.primaryLight, onTap: () => context.push(AppRoutes.uploadResource)),
    _QuickActionCell(icon: Icons.folder_open,    label: 'Resources',     color: AppColors.primary,      onTap: () => context.push(AppRoutes.resources)),
    _QuickActionCell(icon: Icons.people,         label: 'Connections',   color: AppColors.primaryDark,  onTap: () => context.push(AppRoutes.connections)),
    _QuickActionCell(icon: Icons.leaderboard,    label: 'Leaderboard',   color: AppColors.warning,      onTap: () => context.push(AppRoutes.leaderboard)),
    _QuickActionCell(icon: Icons.groups,         label: 'Study Groups',  color: AppColors.accentLight,  onTap: () => context.push(AppRoutes.studyGroups)),
    _QuickActionCell(icon: Icons.campaign,       label: 'Announcements', color: AppColors.error,        onTap: () => context.push(AppRoutes.announcements)),
  ],
),
```

The old `Row` and its four `_QuickAction` calls are deleted entirely.

### 2.5 Resources route — empty courseId guard

When the Quick Actions tile calls `context.push(AppRoutes.resources)` with no query parameter, the `GoRoute` handler passes `courseId = ''` to `ResourcesScreen`, which passes it to `offlineResourcesProvider('')`. That provider unconditionally sends `GET /resources?courseId=` — a malformed request that returns an empty list or an error, not all resources.

**Fix:** add a guard in `offlineResourcesProvider` to omit the `courseId` query param when it is empty:

```dart
// In offline_resources_provider.dart, replace the api.get call:
final queryParams = courseId.isNotEmpty
    ? {'courseId': courseId}
    : <String, String>{};
final response = await api.get(
  ApiConstants.resources,
  queryParams: queryParams,
);
```

This change also affects the cache key: `_cacheKey('')` produces `'resources_course_'`, which is a valid (and distinct) cache key for the "all resources" view. No change to the cache key logic is needed.

The backend contract (from `api/API.md` and standard REST convention) is that `GET /resources` with no `courseId` returns all resources accessible to the authenticated user. This is the intended behavior when navigating from the Quick Actions tile.

---

## 3. New Placeholder Screens

Three screens do not yet exist. Each is a minimal `StatelessWidget` in its own directory. `StatelessWidget` is used because `ref` is not needed; migration to `ConsumerWidget` can happen when the feature is built out.

| Screen | File path |
|---|---|
| Leaderboard | `lib/presentation/screens/leaderboard/leaderboard_screen.dart` |
| Study Groups | `lib/presentation/screens/study_groups/study_groups_screen.dart` |
| Announcements | `lib/presentation/screens/announcements/announcements_screen.dart` |

**Leaderboard** (`leaderboard_screen.dart`):

```dart
import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard, size: 64, color: AppColors.textHint),
            SizedBox(height: 16),
            Text('Leaderboard',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            SizedBox(height: 8),
            Text('Coming soon',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
```

**Study Groups** (`study_groups_screen.dart`) — same pattern, substituting `'Study Groups'` and `Icons.groups`.

**Announcements** (`announcements_screen.dart`) — same pattern, substituting `'Announcements'` and `Icons.campaign`.

Design decisions:
- `StatelessWidget` — no Riverpod dependency until the feature is built. No unused-parameter lint warning.
- `AppBar` uses theme-driven colors — no explicit `backgroundColor` override.
- `AppColors.textHint` / `AppColors.textSecondary` for the icon and subtitle, matching the `_EmptyState` pattern already in `home_screen.dart`.

---

## 4. Router Changes

### 4.1 New `AppRoutes` constants

Add to the `AppRoutes` class in `lib/app/router/app_router.dart`:

```dart
static const String leaderboard   = '/leaderboard';
static const String studyGroups   = '/study-groups';
static const String announcements = '/announcements';
```

### 4.2 New `GoRoute` entries — exact insertion point

The full-screen routes section of `app_router.dart` currently ends with:

```dart
GoRoute(path: AppRoutes.connections, builder: (_, __) => const ConnectionsScreen()),
GoRoute(
  path: '${AppRoutes.discussions}/:threadId',
  builder: (_, state) => ThreadDetailScreen(threadId: state.pathParameters['threadId']!),
),
GoRoute(
  path: '${AppRoutes.profile}/:userId',
  builder: (_, state) => PublicProfileScreen(userId: state.pathParameters['userId']!),
),
```

Insert the three new routes **after `AppRoutes.connections` and before the `/:threadId` parameterised route**:

```dart
GoRoute(path: AppRoutes.connections,     builder: (_, __) => const ConnectionsScreen()),
// ↓ new entries
GoRoute(path: AppRoutes.leaderboard,     builder: (_, __) => const LeaderboardScreen()),
GoRoute(path: AppRoutes.studyGroups,     builder: (_, __) => const StudyGroupsScreen()),
GoRoute(path: AppRoutes.announcements,   builder: (_, __) => const AnnouncementsScreen()),
// ↑ new entries
GoRoute(
  path: '${AppRoutes.discussions}/:threadId',
  ...
),
```

Placing them before the parameterised routes is both conventional and safe — none of the new fixed paths can be matched by `/:threadId` or `/:userId`, so ordering is not functionally significant here. The insertion point is specified to give the implementer an unambiguous location.

These routes are outside the `ShellRoute` — no bottom navigation bar on placeholder screens, consistent with `/ai-assistant`, `/progress`, `/connections`, and all other full-screen destinations.

### 4.3 New imports

Add at the top of `app_router.dart` alongside the other screen imports:

```dart
import '../../presentation/screens/leaderboard/leaderboard_screen.dart';
import '../../presentation/screens/study_groups/study_groups_screen.dart';
import '../../presentation/screens/announcements/announcements_screen.dart';
```

---

## 5. Files Summary

### Modified

| File | What changes |
|---|---|
| `lib/presentation/screens/home/home_screen.dart` | Delete Quick Actions `Row` + four `_QuickAction` calls; add `GridView.count` with nine `_QuickActionCell` calls; add `_QuickActionCell` class |
| `lib/presentation/providers/offline_resources_provider.dart` | Add `courseId.isNotEmpty` guard before the `api.get` call |
| `lib/app/router/app_router.dart` | Three new `AppRoutes` constants, three new imports, three new `GoRoute` entries |

### Created

| File | Content |
|---|---|
| `lib/presentation/screens/leaderboard/leaderboard_screen.dart` | Leaderboard placeholder |
| `lib/presentation/screens/study_groups/study_groups_screen.dart` | Study Groups placeholder |
| `lib/presentation/screens/announcements/announcements_screen.dart` | Announcements placeholder |

---

## 6. Error Handling

### 6.1 Navigation from Quick Actions

Each `_QuickActionCell.onTap` calls `context.push(route)`. All target routes are registered in `GoRouter` before this code runs, so no "no matching route" error can occur at runtime. The three new routes point to stateless placeholder screens with no async operations — no loading or error state to handle.

### 6.2 Resources with empty courseId

With the guard in `offlineResourcesProvider` (§2.5), an empty `courseId` omits the query param entirely, sending `GET /resources`. If the backend returns an error for that endpoint, the existing `ErrorView` with retry is shown — the same behavior as any other resources load failure. This path is recoverable; it is logged at the `ErrorView` level by the existing `error:` branch in `resourcesAsync.when`.

### 6.3 `flutter pub get` failure after deleting pubspec.lock

If the solver still fails after deleting `pubspec.lock`, the failure is fatal to the build step. The developer must run `flutter pub cache repair` to clear and re-download the pub cache, then re-run `flutter pub get`. This is not a code defect — it is a local environment issue.

### 6.4 `flutter clean` locking

`flutter clean` can fail if `build/` is locked by an open IDE Gradle daemon. Mitigation: close Android Studio / VS Code, or stop any running Gradle daemon with `./gradlew --stop` before cleaning.

---

## 7. Validation Rules

This change involves no user input or external API calls in new code. The only runtime "inputs" are tap callbacks, which invoke GoRouter typed route constants — compile-time strings, not user data. The `courseId` passed to `offlineResourcesProvider` is either a non-empty string from a course detail navigation or an empty string from the Quick Actions tile; both cases are now handled correctly (§2.5).

---

## 8. Testability

| Test type | What to test |
|---|---|
| Widget test | Render `HomeScreen` in a `ProviderScope`; assert nine `_QuickActionCell` widgets appear in a `GridView`. |
| Widget test | Tap each `_QuickActionCell`; assert `GoRouter` navigated to the expected path. |
| Widget test | Render each placeholder screen; assert `AppBar` title and "Coming soon" text render without error. |
| Unit test | Call `offlineResourcesProvider` with `courseId = ''`; mock `ApiClient`; assert the query params map does not contain a `courseId` key. |
| Unit test | Call `offlineResourcesProvider` with a non-empty `courseId`; assert the query params map contains `{'courseId': 'abc'}`. |
| Integration test | `flutter run` on device; verify brand color in AppBar; verify all nine taps navigate without crash. |

---

## 9. Invariants and Ownership

| Invariant | Owner | Enforcement |
|---|---|---|
| All colors from `AppColors` | `AppTheme` via theme data + code review | No hardcoded `Color(0x...)` literals in new files |
| Bottom nav has exactly five tabs | `MainShell` in `app_router.dart` | No new `NavigationDestination` entries added |
| New routes outside `ShellRoute` | `GoRouter` route tree | Placement after `ShellRoute` block, same as existing full-screen routes |
| `pubspec.yaml` constraints unchanged | Pub solver | Only `pubspec.lock` deleted and re-generated; no manual edits to `pubspec.yaml` |
| `courseId` query param omitted when empty | `offlineResourcesProvider` | Guard at the provider level — `ResourcesScreen` passes whatever it receives, so the fix lives where the API call is made |

---

## Review Response Log

Findings from `design-review.json` and `03-design-review.md`:

| Finding | Severity | Action |
|---|---|---|
| **1** — `ResourcesScreen` does not handle empty `courseId` | HIGH | **Addressed** — §2.5 adds an `isNotEmpty` guard in `offlineResourcesProvider` to omit the query param when `courseId` is empty. §6.2 describes the error path. |
| **2** — `_QuickAction` is not grid-compatible without layout changes | HIGH | **Addressed** — §2.4 introduces `_QuickActionCell` with a `Center` wrapper and `TextOverflow.ellipsis`, replacing all grid usage. The old `_QuickAction` class is preserved but no longer used in the grid. |
| **3** — `flutter clean` does not fix a pub solver failure | MEDIUM | **Addressed** — §1.1 and §1.3 now correctly distinguish the two failure types. The runbook deletes `pubspec.lock` before `flutter pub get` to force re-solving, and documents `flutter pub cache repair` as the escalation step. `flutter clean` is retained with its correct purpose (Gradle/AAR cache). |
| **4** — `GoRoute` insertion point is ambiguous | MEDIUM | **Addressed** — §4.2 specifies insertion after `AppRoutes.connections` and before the `/:threadId` parameterised route, with the surrounding code quoted for clarity. |
| **5** — `childAspectRatio: 0.85` contingent on layout fix | MEDIUM | **Addressed** — §2.2 now explicitly states the ratio is only valid with the `Center` wrapper (§2.4). |
| **6** — Unused `ref` in `ConsumerWidget` placeholder screens | NIT | **Addressed** — §3 now uses `StatelessWidget` for all three placeholders. No unused-parameter warning. |
| **7** — `flutter run --debug` flag is redundant | NIT | **Addressed** — §1.3 runbook uses `flutter run` without the `--debug` flag. |
