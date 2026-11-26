# Requirements: Mobile App Full Sync & Feature Parity

## Summary

The mobile app (`mobile_app/`) has accumulated several issues across three layers:

1. **Build breakage** — a `file_picker` version conflict and a `compileSdk` mismatch block `flutter pub get` and Gradle assembly.
2. **Hot-reload/deployment gap** — the app installs and runs but new UI changes (colors, layouts) are not reflected on the physical device, indicating a stale build artefact rather than a live-code problem.
3. **Missing home screen features** — the home screen Quick Actions grid shows only four items (AI Tutor, GPA Calc, Progress, Upload). It is missing Resources, Leaderboard, Study Groups, Connections, and Announcements. The user confirmed the bottom navigation is correct (Home, Courses, Community, Library, Profile) and should not change.

The goal is to resolve all three issues so the app builds cleanly, the physical device sees the current code, and the home screen Quick Actions surface every major feature the platform supports.

---

## Assumptions

> These inferences were made because the user's messages did not specify exact designs. The design step will produce concrete UI decisions.

- **A1.** "Resources" in the home screen Quick Actions links to `/resources` (the existing `ResourcesScreen`), consistent with how other Quick Actions work.
- **A2.** "Leaderboard" is a new destination that does not yet have a screen; a placeholder screen is sufficient for this sync task.
- **A3.** "Study Groups" is similarly a new destination requiring a placeholder screen.
- **A4.** "Connections" links to the existing `ConnectionsScreen` at `/connections`.
- **A5.** "Announcements" is a new destination requiring a placeholder screen. It is distinct from the notifications system.
- **A6.** The Quick Actions grid should reflow to two rows of four to accommodate eight items without overcrowding a typical phone screen.
- **A7.** "New features like the color" not showing on device is a stale build / cached Gradle artefact — not a code defect in the theme itself. `AppColors` already defines the correct brand palette.
- **A8.** `file_picker: ^8.3.7` is the correct resolution version (this is what Pub itself recommended in the error output).
- **A9.** The root `build.gradle` already sets `compileSdkVersion 36` for all subprojects via `afterEvaluate`, so no change to that file is needed; the fix is confirming `app/build.gradle` has `compileSdk 36` (it already does).

---

## Functional Requirements

### FR-1 — Dependency resolution (file_picker)
The `pubspec.yaml` constraint on `file_picker` must be updated from the pinned `8.0.6` to `^8.3.7` so that `flutter pub get` resolves without error. No other dependency versions may change unless forced by the solver.

### FR-2 — Android compileSdk alignment
The app-level `android/app/build.gradle` must declare `compileSdk 36` and `targetSdk 36`. The root `build.gradle` subproject override already sets this for plugin modules; both values must agree so `CheckAarMetadataWorkAction` passes.

### FR-3 — Clean device build
After FR-1 and FR-2 are resolved, the developer must be able to `flutter clean && flutter pub get && flutter run` targeting a physical Android device without build errors. The running app must reflect the current `AppColors` theme and all code written to date.

### FR-4 — Home screen Quick Actions grid
The home screen must display Quick Actions for all eight features listed below. Each action navigates to the corresponding route when tapped.

| Label | Icon (suggested) | Target route |
|---|---|---|
| AI Tutor | `Icons.auto_awesome` | `/ai-assistant` |
| GPA Calc | `Icons.calculate` | `/gpa-calculator` |
| Progress | `Icons.trending_up` | `/progress` |
| Upload | `Icons.upload_file` | `/upload-resource` |
| Resources | `Icons.folder_open` | `/resources` |
| Leaderboard | `Icons.leaderboard` | `/leaderboard` |
| Study Groups | `Icons.groups` | `/study-groups` |
| Connections | `Icons.people` | `/connections` |
| Announcements | `Icons.campaign` | `/announcements` |

> Note: That is nine items. If the design step decides the grid must be capped at eight, "Upload" is the lowest priority candidate for removal because uploading is also accessible from the Library screen and the Resources screen.

### FR-5 — New placeholder screens
For every new route added in FR-4 that does not already have a screen (`/leaderboard`, `/study-groups`, `/announcements`), a minimal placeholder screen must exist. Each placeholder must show the feature name and a "Coming soon" message so navigation does not crash.

### FR-6 — Router registration
Every new route added in FR-4 must be registered in `AppRoutes` constants and in the `GoRouter` routes list in `app_router.dart`. Routes that land outside the bottom-nav shell (like the existing `/ai-assistant`) follow the same pattern — full-screen, no shell wrapping.

---

## Non-Functional Requirements

### NFR-1 — No regression to existing navigation
The five-tab bottom navigation bar (Home, Courses, Community, Library, Profile) must remain unchanged in both structure and routing logic.

### NFR-2 — Theme compliance
All new widgets must use `AppColors` constants. No hardcoded hex or `Color(0x...)` literals may appear in new code.

### NFR-3 — Build cleanliness
`flutter analyze` must report zero errors (warnings acceptable) after the changes. The Gradle build must complete without task failures on Android API 36.

### NFR-4 — Scroll layout
The home screen must remain scrollable when the Quick Actions grid grows to two rows, with no overflow on common screen sizes (≥ 360 dp width).

---

## Acceptance Criteria

1. `flutter pub get` in `mobile_app/` completes without version-solving errors.
2. `flutter build apk --debug` (or `flutter run`) completes without a Gradle `CheckAarMetadataWorkAction` failure.
3. Installing the freshly built APK on a physical Android device shows the deep-teal brand color (`#006B5E`) in the app bar, navigation bar indicator, and buttons — confirming the new theme is active.
4. The home screen Quick Actions grid displays at least eight named actions (all items in FR-4, or eight if a final design decision removes one).
5. Tapping "AI Tutor" navigates to the AI Assistant screen.
6. Tapping "GPA Calc" navigates to the GPA Calculator screen.
7. Tapping "Progress" navigates to the Progress screen.
8. Tapping "Upload" navigates to the Upload Resource screen.
9. Tapping "Resources" navigates to the Resources screen.
10. Tapping "Connections" navigates to the Connections screen.
11. Tapping "Leaderboard" opens a screen without a runtime error.
12. Tapping "Study Groups" opens a screen without a runtime error.
13. Tapping "Announcements" opens a screen without a runtime error.
14. The five-tab bottom navigation bar still functions correctly on all five tabs after the changes.
15. `flutter analyze` exits with zero errors in `mobile_app/`.

---

## Out of Scope

- Implementing actual Leaderboard, Study Groups, or Announcements feature logic — placeholders satisfy this task.
- Changes to the web app, admin dashboard, or backend.
- iOS build fixes (Android is the stated target platform).
- Dark mode support.
- Adding Leaderboard, Study Groups, Connections, or Announcements to the bottom navigation bar — the user confirmed the five-tab bar is correct.
- Any changes to the Community, Courses, Library, or Profile screens beyond what is required by the routing additions.
