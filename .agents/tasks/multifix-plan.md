# Implementation Plan — CampusCore Multi-Fix

Covers five issues found during exploration. Each item leaves the codebase in a
buildable state. Order follows dependency: auth_provider compile fix first (blocks
web_app build), then Flutter UI fixes, then admin dashboard, then keep-alive.

---

## Findings from code exploration

### Issue 1 — Community "retry"
The `questionsProvider` in `community_screen.dart` already handles the
`{ questions: [...], total: N }` shape correctly. The real cause is a
**network/auth error**: the backend `community.service.ts` `findQuestions` does a
LEFT JOIN against the `users` table using a raw QueryBuilder, which can throw if
the DB query fails. More importantly, **the provider swallows the error shape from
the backend** — but looking at `api_client.dart` the Authorization header IS
attached. The root problem is that `questionsProvider` uses `ref.read(apiClientProvider)`
instead of `ref.watch` inside a `FutureProvider.autoDispose`, meaning if the token
loads after the provider fires the first request goes out unauthenticated (401 →
token cleared → error). Fix: change `ref.read` to `ref.watch` so the provider
rebuilds when auth state changes, and add a `ref.watch(authStateProvider)` guard
to delay the fetch until auth is initialized.

### Issue 2 — Resources tab blank / infinite skeleton
`courseResourcesProvider` also uses `ref.read(apiClientProvider)`. The real
problem: `ResourcesService.findByCourse` returns `Promise<[Resource[], number]>`
(a TypeORM tuple), and the `ResponseInterceptor` wraps this as
`{ success: true, data: [Array, number] }`. The Flutter provider only checks
`if (data is List)` — but `data` is the two-element tuple `[[...items], count]`,
so the first branch does match BUT `data[0]` is a `List<dynamic>` and `.cast()`
on it works. Wait — `data is List` would be true, and it would try
`data.cast<Map<String, dynamic>>()` on `[[...], 123]` which throws a cast error
(a List cast as Map fails). The existing code has the tuple fallback already but
it's checking `data[0] is List` — which is correct. However the **real** issue
is the silent swallow: `courseResourcesProvider` calls `resp.data['data']` and
if that fails the provider never transitions from loading to error because the
`AsyncValue` shows loading indefinitely until timeout.

Actually re-reading the code: `_ResourcesTab` correctly renders an error state
from `resourcesAsync.when(error: ...)`. So the skeleton *showing forever* means
the provider never resolves — likely the Dio request times out (Render cold start
= 30 s+, but `receiveTimeout` is only 15 s). Fix: increase `receiveTimeout` to
30 s in `api_client.dart`, and fix the resources response parsing to handle the
tuple `[items[], count]` that `findByCourse` actually returns.

### Issue 3 — Ask AI Tutor button is a no-op
`_OverviewTab` in `course_detail_screen.dart` line ~197:
`onPressed: () {}` — just needs `context.go('/ai')`.

### Issue 4 — Admin growth chart hardcoded
`_UserGrowthChart` in `dashboard_screen.dart` uses 6 hardcoded `FlSpot` points.
The task says to replace it with a **bar chart** of users by role using `byRole`
from `GET /admin/stats` (already fetched in `statsProvider`). The existing
`_RoleBreakdownChart` (pie chart) handles this data. The plan: remove
`_UserGrowthChart`, replace the `Row` in the build method with a new full-width
`_UsersByRoleBarChart` widget that reads `byRole` and renders a `BarChart` from
`fl_chart` using `AdminColors`.

### Issue 5 — Tab-switch reload / Render cold start
Both `main.dart` files need a `Timer.periodic` that fires every 10 minutes and
calls `GET /api/v1/departments` via Dio to keep the Render dyno alive.

---

## Plan

- [ ] 1. Fix `auth_provider.dart` duplicate `body` variable (blocks `flutter build web`)

  The build error reports two `final body` declarations in the same scope at
  lines 258 and 264. The `updateProfile` method currently names the response
  variable `respBody`, so the conflict must be in a sign-up or google-sign-in
  method. Rename the second `body` in whichever method declares it twice to
  `respBody` so both calls in the same `try` block have distinct names.

  Files:
  - `web_app/lib/core/providers/auth_provider.dart`

  Change: find any `try` block that contains both `final body = <String, dynamic>{...}`
  and `final body = resp.data as Map<String, dynamic>` in the same scope.
  Rename the response-cast one to `final respBody = resp.data as Map<String, dynamic>`
  and update all subsequent references to `body['success']`, `body['data']`,
  `body['message']` in that block to use `respBody`.

  Verify: `cd web_app && flutter analyze lib/core/providers/auth_provider.dart`
  — zero errors reported.

---

- [ ] 2. Fix `questionsProvider` to use `ref.watch` and wait for auth init

  `ref.read(apiClientProvider)` inside a `FutureProvider.autoDispose` misses
  token changes. Change to `ref.watch`. Also add an early-exit guard: if the
  auth notifier has not yet initialized, throw so the provider shows loading
  rather than firing an unauthenticated request.

  Files:
  - `web_app/lib/presentation/screens/community/community_screen.dart`

  Change (replace the top of `questionsProvider`):
  ```dart
  import '../../../core/providers/auth_provider.dart';
  // ...
  final questionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
    // Wait until auth is initialized; throws on unauthenticated to show error state
    final authState = ref.watch(authStateProvider);
    if (!authState.initialized) throw Exception('Not ready');

    final api  = ref.watch(apiClientProvider);
    final resp = await api.get(ApiConstants.questions, params: {'limit': 30});
    // ... rest unchanged
  ```

  Verify: `flutter analyze lib/presentation/screens/community/community_screen.dart`
  — zero errors. Then run the app and navigate to Community — questions load
  without a "Retry" error on first open.

---

- [ ] 3. Fix `courseResourcesProvider` response parsing + increase Dio timeout

  **3a.** Increase `receiveTimeout` from 15 s to 30 s in the web_app `ApiClient`
  so Render cold-start responses don't time out.

  Files:
  - `web_app/lib/core/network/api_client.dart`

  Change: `receiveTimeout: const Duration(seconds: 30),`

  **3b.** Fix the resources response parsing. `ResourcesService.findByCourse`
  returns a TypeORM tuple `[Resource[], number]`, which the `ResponseInterceptor`
  wraps as `{ success: true, data: [[...items], 123] }`. So `resp.data['data']`
  is a 2-element list: index 0 = items array, index 1 = count integer.
  The current code checks `if (data is List)` first, which matches, and then tries
  `data.cast<Map<String, dynamic>>()` — this throws because `data[1]` is an int.

  The fix is to reorder the guard: check the tuple shape (`data[0] is List`)
  before the flat-list shape.

  Files:
  - `web_app/lib/presentation/screens/courses/course_detail_screen.dart`

  Replace the `courseResourcesProvider` body:
  ```dart
  final courseResourcesProvider = FutureProvider.autoDispose
      .family<List<Map<String, dynamic>>, String>((ref, courseId) async {
    final api  = ref.watch(apiClientProvider);
    final resp = await api.get(ApiConstants.resources, params: {
      'courseId': courseId,
      'status':   'approved',
      'limit':    50,
    });
    final data = resp.data['data'];
    // TypeORM tuple: [[...items], count]
    if (data is List && data.isNotEmpty && data[0] is List) {
      return (data[0] as List).cast<Map<String, dynamic>>();
    }
    // Shaped object: { items: [...] } or { data: [...] }
    if (data is Map) {
      final items = data['items'] ?? data['data'] ?? data['resources'];
      if (items is List) return items.cast<Map<String, dynamic>>();
    }
    // Flat list fallback
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  });
  ```

  Also change `ref.read(apiClientProvider)` → `ref.watch(apiClientProvider)`
  inside this provider.

  Verify: `flutter analyze lib/presentation/screens/courses/course_detail_screen.dart`
  — zero errors. Open a course detail and switch to Resources tab — either items
  appear or the empty-state "No resources uploaded" message shows (never infinite
  skeleton or blank).

---

- [ ] 4. Wire the "Ask AI Tutor" button to navigate to the AI screen

  `_OverviewTab` in `course_detail_screen.dart` has `onPressed: () {}`.
  Replace with `onPressed: () => context.go('/ai')`.
  The `BuildContext` is already available (the widget is a `StatelessWidget`
  and `context` is a method parameter from `build(BuildContext context)`).

  Files:
  - `web_app/lib/presentation/screens/courses/course_detail_screen.dart`

  Change (inside `_OverviewTab.build`, the `OutlinedButton.icon`):
  ```dart
  onPressed: () => context.go('/ai'),
  ```

  Verify: `flutter analyze lib/presentation/screens/courses/course_detail_screen.dart`
  — zero errors. Tap "Ask AI Tutor" — app navigates to `/ai` route.

---

- [ ] 5. Replace the hardcoded growth chart with a real-data bar chart (admin dashboard)

  Remove the `_UserGrowthChart` StatelessWidget entirely. Replace the `Row`
  in `DashboardScreen.build` that contains `_UserGrowthChart` and
  `_RoleBreakdownChart` side-by-side with a single full-width
  `_UsersByRoleBarChart` widget that uses `byRole` data already loaded by
  `statsProvider`.

  Files:
  - `admin_dashboard/lib/presentation/screens/dashboard/dashboard_screen.dart`

  **5a.** Remove the `_UserGrowthChart` class and its `const _UserGrowthChart()`
  call in the build method.

  **5b.** Replace the `Row(children: [Expanded(child: _UserGrowthChart()), ..., _RoleBreakdownChart(...)])` with:
  ```dart
  _UsersByRoleBarChart(byRole: byRole),
  ```

  **5c.** Add the `_UsersByRoleBarChart` widget after `_RoleBreakdownChart`:
  ```dart
  class _UsersByRoleBarChart extends StatelessWidget {
    final List byRole;
    const _UsersByRoleBarChart({required this.byRole});

    @override
    Widget build(BuildContext context) {
      const roleColors = {
        'student':   AdminColors.primary,
        'moderator': AdminColors.accent,
        'lecturer':  AdminColors.info,
        'admin':     AdminColors.grey600,
      };

      final groups = <BarChartGroupData>[];
      final labels = <String>[];
      for (int i = 0; i < byRole.length; i++) {
        final r     = byRole[i] as Map;
        final role  = r['role']?.toString() ?? '';
        final count = double.tryParse(r['count'].toString()) ?? 0;
        final color = roleColors[role] ?? AdminColors.grey300;
        labels.add('${role.isNotEmpty ? role[0].toUpperCase() : '?'}${role.length > 1 ? role.substring(1) : ''}');
        groups.add(BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: count, color: color, width: 28, borderRadius: BorderRadius.circular(4)),
          ],
        ));
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Users by Role',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AdminColors.grey900),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: groups.isEmpty
                    ? const Center(child: Text('No data', style: TextStyle(color: AdminColors.grey600)))
                    : BarChart(BarChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(labels[idx],
                                      style: const TextStyle(fontSize: 11, color: AdminColors.grey600)),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (v, _) => Text(
                                v.toInt().toString(),
                                style: const TextStyle(fontSize: 10, color: AdminColors.grey600),
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        barGroups: groups,
                      )),
              ),
            ],
          ),
        ),
      );
    }
  }
  ```

  Verify: `cd admin_dashboard && flutter analyze lib/presentation/screens/dashboard/dashboard_screen.dart`
  — zero errors. Open dashboard — the chart shows four bars (student, moderator,
  lecturer, admin) with real counts from the API, using `AdminColors`.

---

- [ ] 6. Add a keep-alive ping timer to web_app main.dart

  After `runApp(...)` fires, start a `Timer.periodic` that GETs
  `https://campuscore-bfrq.onrender.com/api/v1/departments` every 10 minutes
  using Dio. Failures are swallowed silently. The timer is started at the top
  level (not inside a widget) so it lives for the entire app session.

  Files:
  - `web_app/lib/main.dart`

  Change: add imports and the timer after `runApp`:
  ```dart
  import 'dart:async';
  import 'package:dio/dio.dart';
  // ... existing imports ...

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await Supabase.initialize( /* existing */ );
    runApp(const ProviderScope(child: CampusCoreWebApp()));

    // Keep Render backend alive — ping every 10 minutes
    const _pingUrl = 'https://campuscore-bfrq.onrender.com/api/v1/departments';
    final _pinger = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10),
                                    receiveTimeout: const Duration(seconds: 10)));
    Timer.periodic(const Duration(minutes: 10), (_) async {
      try { await _pinger.get(_pingUrl); } catch (_) {}
    });
  }
  ```

  Verify: `flutter analyze lib/main.dart` — zero errors.

---

- [ ] 7. Add a keep-alive ping timer to admin_dashboard main.dart

  Same pattern as item 6, applied to the admin dashboard.

  Files:
  - `admin_dashboard/lib/main.dart`

  Change: same imports + `Timer.periodic` block after `runApp(...)`.

  ```dart
  import 'dart:async';
  import 'package:dio/dio.dart';
  // ... existing imports ...

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await Supabase.initialize( /* existing */ );
    runApp(const ProviderScope(child: CampusCoreAdminApp()));

    // Keep Render backend alive — ping every 10 minutes
    const _pingUrl = 'https://campuscore-bfrq.onrender.com/api/v1/departments';
    final _pinger = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10),
                                    receiveTimeout: const Duration(seconds: 10)));
    Timer.periodic(const Duration(minutes: 10), (_) async {
      try { await _pinger.get(_pingUrl); } catch (_) {}
    });
  }
  ```

  Verify: `flutter analyze lib/main.dart` — zero errors.

---

## Execution order summary

1 → (unlocks web_app build) → 2 → 3 → 4 → (all in web_app, independent of each other after 1 is done) → 5 → (admin_dashboard, independent of web_app) → 6 → 7 (independent of each other).

Items 2, 3, 4 can be done in any order after item 1. Items 5, 6, 7 are independent of items 1–4.

---

## Notes / assumptions

- `authStateProvider` already exists and exposes `AuthState` with an `initialized` bool — confirmed in `auth_provider.dart`. The import `'../../../core/providers/auth_provider.dart'` is not yet in `community_screen.dart` and must be added.
- `fl_chart`'s `BarChart` / `BarChartData` / `BarChartGroupData` / `BarChartRodData` are already available (the package is used for `LineChart` and `PieChart` in the same file). No pubspec change needed.
- The `AdminColors` class has no `cyan` — `AdminColors.info` (blue) is used for lecturer in the bar chart.
- `AdminColors.grey300` is defined in `admin_theme.dart`; used as fallback color for unknown roles.
- The duplicate-`body` build error (message index 11) may already be fixed in the current working copy — the file as read has `body` in `updateProfile`'s try block and `respBody` for the response. If `flutter analyze` passes cleanly, item 1 can be skipped.
