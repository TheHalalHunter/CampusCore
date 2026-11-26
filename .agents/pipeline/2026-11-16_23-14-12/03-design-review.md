# Design Review: Mobile App Full Sync & Feature Parity

**Design file:** `02-design.md`  
**Requirements file:** `01-requirements.md`  
**Reviewer:** Design Review Subagent  
**Verdict:** CHANGES_REQUESTED

---

## Findings

### 1. [HIGH] `ResourcesScreen` does NOT handle empty `courseId` gracefully — it sends a bad API request

**Where:** Section 2.5 and Section 6.2 of the design.

**Claim:** "The existing `/resources` route handler reads `courseId` from the query parameter and defaults to `''` when absent. `ResourcesScreen` already handles an empty `courseId` by showing all resources."

**Actual behavior (verified in source):**
`ResourcesScreen` passes `courseId` directly to `offlineResourcesProvider(widget.courseId)`. That provider unconditionally calls `api.get(ApiConstants.resources, queryParams: {'courseId': courseId})` with whatever string it received — including `''`. There is no guard, no early return for empty strings, and no "show all resources" branch. An empty `courseId` sends `GET /resources?courseId=` to the backend, which will either return an empty list or an error, not "all resources". The design presents this as a non-issue; it is a runtime behavioral defect.

**Concrete fix:**  
Either (a) pass a meaningful default or don't pass the query param at all when `courseId` is empty:

```dart
// In offlineResourcesProvider, before the api.get call:
final queryParams = courseId.isNotEmpty ? {'courseId': courseId} : <String, String>{};
final response = await api.get(ApiConstants.resources, queryParams: queryParams);
```

Or (b) note in the design that the Quick Actions "Resources" tile intentionally navigates to `/resources?courseId=` and the backend returns all resources for an empty/absent `courseId` — but this must be verified against the backend contract before claiming it.

---

### 2. [HIGH] `_QuickAction` uses `mainAxisSize: MainAxisSize.min` and a fixed 52 dp icon — it will not fill a `GridView.count` cell correctly without layout guidance

**Where:** Section 2.4 of the design.

**Claim:** "The existing `_QuickAction` widget is unchanged — it already accepts any icon, color, label, and callback. Only the container that holds them changes."

**Actual widget (verified in source):**
```dart
child: Column(
  mainAxisSize: MainAxisSize.min,   // <-- shrinks to minimum height
  children: [
    Container(width: 52, height: 52, ...),
    SizedBox(height: 6),
    Text(label, ..., overflow: TextOverflow.visible),  // <-- can overflow
  ],
),
```

Inside a `GridView.count` cell, the outer `GestureDetector → Column(mainAxisSize: min)` will not center itself in the allocated cell area. The cell's height is determined by `childAspectRatio: 0.85`, which at 92 dp width gives ≈ 108 dp cell height. The column collapses to its minimum size and aligns at the top-left, leaving uneven space. Additionally, `overflow: TextOverflow.visible` can render text outside the cell boundary and visually bleed into adjacent cells.

**Concrete fix:**  
Wrap the `_QuickAction` content in a `Center` and change `overflow` to `TextOverflow.ellipsis` for the grid variant:

```dart
// In home_screen.dart, the grid cell wrapper (not the widget itself):
GridView.count(
  ...
  children: [
    _QuickActionCell(icon: ..., label: ..., color: ..., onTap: ...),
    ...
  ],
),

// New internal layout:
class _QuickActionCell extends StatelessWidget {
  ...
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 52, height: 52, ...),
            const SizedBox(height: 6),
            Text(label, ..., maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
```

Alternatively, keep the existing `_QuickAction` for other possible uses and create a new `_QuickActionCell` for the grid. Either way, the design must specify this change explicitly rather than claiming the widget is unchanged.

---

### 3. [MEDIUM] Design claims `pubspec.yaml` already has `file_picker: ^8.3.7` and "no change needed" — this is true, but the rationale for why `flutter pub get` was still failing is never addressed

**Where:** Section 1.1 of the design.

**Issue:** The design states both "no change needed to `pubspec.yaml`" and that the original error was caused by "a previously cached APK". But the original user error message is unambiguous: `flutter pub get` itself failed — not just the Gradle build. `flutter pub get` failing is a pub solver failure, not an APK cache issue. If `pubspec.yaml` already has `^8.3.7`, `flutter pub get` should not fail at all. The design does not reconcile this. The stated fix ("run `flutter clean`") does not affect `pub get` behaviour; `flutter clean` deletes the `build/` directory and `.dart_tool/` but pub's package cache is in `~/.pub-cache/` and is unaffected.

**Concrete fix:**  
Acknowledge the discrepancy explicitly. If the `pubspec.yaml` truly already has `^8.3.7`, the `flutter pub get` failure shown in the user's message would not occur with that file. The design should state: "If `flutter pub get` still fails after confirming `pubspec.yaml` has `^8.3.7`, run `flutter pub cache repair` or delete `pubspec.lock` and re-run `flutter pub get` to force the solver to pick a fresh lock." Without this, the developer following the runbook may still hit the original error.

---

### 4. [MEDIUM] The placeholder screen import path in the template is wrong

**Where:** Section 3 of the design — the sample `LeaderboardScreen` code.

**Claim:**
```dart
import '../../../app/theme/app_theme.dart';
```

**Issue:** The placeholder screens will be created at:
- `lib/presentation/screens/leaderboard/leaderboard_screen.dart`
- `lib/presentation/screens/study_groups/study_groups_screen.dart`
- `lib/presentation/screens/announcements/announcements_screen.dart`

From `lib/presentation/screens/<feature>/screen.dart`, three `../` jumps go to `lib/`, not to `lib/app/`. The correct path is:

```dart
import '../../../app/theme/app_theme.dart';
```

This is actually **correct** — `../../../` from `lib/presentation/screens/leaderboard/` goes to `lib/presentation/screens/` → `lib/presentation/` → `lib/` and then `app/theme/app_theme.dart`. That resolves to `lib/app/theme/app_theme.dart`. ✓

Upon rechecking: this path is correct. Withdraw this sub-finding.

**Actual concern (keeping MEDIUM for a different reason):** The design imports `flutter_riverpod` in the placeholder screens but the screens contain no `ref` usage at all. `ConsumerWidget` requires `WidgetRef ref` in the build signature, which Dart will compile fine, but `flutter analyze` will warn about an unused parameter. The design claims "NFR-3: `flutter analyze` must report zero errors (warnings acceptable)" — but this is a stylistic inconsistency the design should address. Since warnings are explicitly acceptable per NFR-3, downgrading this to NIT.

**Revised severity:** NIT (see Finding 7).

---

### 5. [MEDIUM] The `GoRoute` insertion point "after `GoRoute(path: AppRoutes.connections, ...)`" is ambiguous — `connections` has no sibling comment in source

**Where:** Section 4.2 of the design.

**Claim:** "Add after `GoRoute(path: AppRoutes.connections, ...)` in the full-screen routes section."

**Actual source:** The full-screen routes section in `app_router.dart` does not have any grouping comments. The routes are listed in a flat sequence. The `connections` route is the last route before the two parameterised routes (`/:threadId` and `/:userId`). The design does not specify whether the new routes go before or after those parameterised routes. While this won't break anything functionally (GoRouter evaluates routes in declaration order and the new paths don't conflict), the design should give an unambiguous insertion point to avoid ordering mistakes.

**Concrete fix:**  
Specify: "Insert the three new `GoRoute` entries after `GoRoute(path: AppRoutes.connections, ...)` and before the two parameterised routes (`/:threadId` and `/:userId`)." Or provide the complete updated routes list.

---

### 6. [MEDIUM] `childAspectRatio: 0.85` is derived from a 360 dp base but is never validated against the actual content height

**Where:** Section 2.2 of the design.

**Issue:** The design states `childAspectRatio: 0.85` "fits the 52 dp icon + 6 dp gap + two-line label at 11 sp". At 92 dp cell width, `height = 92 / 0.85 ≈ 108 dp`. Content height is: 52 (icon) + 6 (gap) + ~26 (two lines × 11 sp × ~1.2 line height) = ~84 dp, which fits. However, the design does not account for the vertical padding that `GridView` cells apply, nor for the `Center` wrapper that would need to be added (see Finding 2). More critically, `GridView.count` cells allocate the full cell height; `Column(mainAxisSize: min)` will leave dead space rather than clipping. The claimed ratio is plausible but not verified with the actual widget geometry, and it depends on the layout fix in Finding 2 being applied.

**Concrete fix:**  
The design must state that `childAspectRatio` is contingent on the layout fix (wrapping in `Center`). Without that fix, the aspect ratio is irrelevant since the content will not be positioned correctly regardless of the ratio. Add: "This ratio assumes the cell content is wrapped in `Center` to handle vertical alignment within the allocated cell space."

---

### 7. [NIT] Placeholder screens use `ConsumerWidget` with an unused `ref` parameter

**Where:** Section 3, code snippet.

**Issue:** The placeholder screens import `flutter_riverpod` and extend `ConsumerWidget`, but `ref` is never used. `flutter analyze` will emit an unused-parameter hint for `ref`. This contradicts the design's own rationale ("Riverpod-aware for future use") — that is a speculative reason to introduce a warning today.

**Concrete fix:**  
Either use a plain `StatelessWidget` now and migrate to `ConsumerWidget` when state is needed, or suppress the hint with:
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ignore: unused_element
```
Or keep `ConsumerWidget` and accept the warning (NFR-3 permits warnings). Just make the choice explicit in the design.

---

### 8. [NIT] Section 1.3 runbook says `flutter run --debug` but `flutter run` already defaults to debug mode

**Where:** Section 1.3.

**Issue:** Minor inaccuracy — `flutter run` without flags already runs in debug mode. The flag `--debug` is not wrong, just redundant.

**Concrete fix:** Use `flutter run` or `flutter run --release` depending on what the developer needs. The comment `# or --release` already conveys this, so just remove `--debug`.

---

## Verified Assumptions

| Claim | Source checked | Result |
|---|---|---|
| `file_picker: ^8.3.7` is already in `pubspec.yaml` | `mobile_app/pubspec.yaml` | ✓ Correct — `file_picker: ^8.3.7` is present |
| `app/build.gradle` has `compileSdk 36` and `targetSdk 36` | `android/app/build.gradle` | ✓ Correct — both set to 36 |
| Root `build.gradle` applies `compileSdkVersion 36` via `afterEvaluate` | `android/build.gradle` | ✓ Correct — `afterEvaluate` block sets `compileSdkVersion 36` |
| `AppColors.accentLight`, `primaryDark`, `warning`, `info`, `error`, `success` all exist | `app/theme/app_theme.dart` | ✓ All constants present |
| `ConnectionsScreen` exists at `screens/profile/connections_screen.dart` | Filesystem search | ✓ Confirmed |
| `AppRoutes.connections` is registered as a full-screen route | `app_router.dart` | ✓ Confirmed |
| Import path `'../../../app/theme/app_theme.dart'` is correct from `screens/<feature>/` | Existing screens confirmed this pattern | ✓ Correct — all existing screens use this path |
| `_QuickAction` widget accepts `icon`, `color`, `label`, `onTap` | `home_screen.dart` lines 389–432 | ✓ Correct |
| Home screen Quick Actions are currently a `Row` with 4 items | `home_screen.dart` lines 139–171 | ✓ Correct — a bare `Row` with 4 `_QuickAction` items |
| `AppRoutes.leaderboard`, `studyGroups`, `announcements` do NOT yet exist in mobile router | `app_router.dart` full read | ✓ Confirmed — none of the three constants or routes exist |
| New placeholder directories do not yet exist in mobile `screens/` | Filesystem search | ✓ Confirmed — no `leaderboard/`, `study_groups/`, or `announcements/` under mobile `screens/` |
| All new routes are placed outside `ShellRoute` (consistent with `/connections`, `/ai-assistant`) | `app_router.dart` | ✓ Correct placement pattern |

---

## Unverified / Wrong Assumptions

| Claim in design | What source shows | Severity |
|---|---|---|
| "`ResourcesScreen` already handles an empty `courseId` by showing all resources" (§2.5, §6.2) | `offlineResourcesProvider` passes `courseId` directly to the API with no empty-string guard. An empty `courseId` sends `GET /resources?courseId=` to the backend. No "show all" branch exists in the screen or the provider. | HIGH (Finding 1) |
| "The existing `_QuickAction` widget is unchanged — it already accepts any icon, color, label, and callback. Only the container that holds them changes." (§2.4) | `_QuickAction` uses `Column(mainAxisSize: min)` and `TextOverflow.visible`. In a `GridView.count` cell this produces top-aligned, potentially overflow-bleeding content. The widget must be wrapped or modified to work correctly in a grid. The design omits this required change. | HIGH (Finding 2) |
| "The stale build on the physical device was caused by a previously cached APK from before the `pubspec.yaml` was corrected." (§1.1) | The user's first two error messages show `flutter pub get` failing (a pub solver error), not a Gradle failure on a stale AAR. `flutter clean` does not affect pub's package cache. If `pubspec.yaml` already has `^8.3.7`, `flutter pub get` should succeed without `flutter clean`. The runbook's explanation is incorrect and the fix may be incomplete. | MEDIUM (Finding 3) |
