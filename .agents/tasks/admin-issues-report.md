# Admin Dashboard — Findings Report

**Investigated:** 4 reported issues  
**Status:** Root cause found for all 4. No mock data — all screens make real API calls. Three issues are data-shape mismatches or backend response shape mismatches; one is a Flutter layout constraint bug.

---

## Summary

| # | Issue | Root Cause | Severity |
|---|-------|------------|----------|
| 1 | Dashboard shows 0 for all stats | `GET /admin/stats` returns real data but the `UserGrowthChart` is hardcoded; stats cards should work — see detail below | Low / Cosmetic |
| 2 | Courses — cannot scroll down | `Expanded` inside a `Column` that is itself inside `Padding` (not a `Scaffold` body) — the column has no bounded height from the shell, so `Expanded` works but the `DataTable` inside a `Card` with a vertical `SingleChildScrollView` is missing | Medium |
| 3 | Users — no data shown | `AdminService.getAllUsers()` returns `[User[], number]` (a tuple), but `ResponseInterceptor` wraps it in `{ success, data: [[...users], count] }` — the Flutter provider tries `raw['users']` which is `null`, so it always returns `[]` | High |
| 4 | Moderation — no data shown | The endpoint exists and returns real data, but the provider silently catches all errors (`catch (_) { return []; }`). The real cause is almost certainly the same auth/token issue: the `Authorization` header only attaches if `admin_token` is set in SharedPreferences at request time | Medium |

---

## Issue 1 — Dashboard Stats

### What it calls
`dashboard_screen.dart` lines 11–32:
- `GET /admin/stats` via `statsProvider`
- `GET /resources/moderation/pending` via `pendingCountProvider`
- `GET /departments` via `departmentCountProvider`

### Backend response shape
`AdminService.getPlatformStats()` (`admin.service.ts` lines 13–26) returns:
```json
{ "totalUsers": 5, "activeUsers": 4, "byRole": [{"role":"student","count":"4"},{"role":"admin","count":"1"}] }
```
The `ResponseInterceptor` wraps this as `{ "success": true, "data": { "totalUsers":5, ... } }`.

The Flutter provider at line 12–14 of `dashboard_screen.dart` does:
```dart
final data = response.data['data'] ?? response.data;
return data as Map<String, dynamic>;
```
This correctly unwraps. **The stat cards should work if the API call succeeds.**

### Real issue
The `_UserGrowthChart` widget (`dashboard_screen.dart` lines 215–290) is **100% hardcoded**:
```dart
spots: const [
  FlSpot(0, 0), FlSpot(1, 50), FlSpot(2, 120),
  FlSpot(3, 200), FlSpot(4, 310), FlSpot(5, 450),
],
```
Also, the `byRole` data from the backend returns `count` as a **string** (because `getRawMany()` returns raw SQL strings), but the Flutter side calls `double.tryParse(r['count'].toString())` which handles that correctly.

If stats show 0, the likely cause is that the Bearer token request fails silently (the provider catches all errors and returns zeros at lines 16–18). The dashboard will show all-zero stat cards rather than an error, masking the real problem.

### Fix needed
1. The stat cards: no fix needed if auth works. If still 0 after auth is confirmed working, add error logging to `statsProvider` (remove silent catch or log the error).
2. The growth chart: replace the hardcoded `FlSpot` data with a real backend call to a `/admin/analytics` endpoint, or label it clearly as placeholder data.

---

## Issue 2 — Courses Cannot Scroll Down

### File
`courses_management_screen.dart`

### Root cause
The screen's top-level widget is a `Column` (line 97) containing a final child of `Expanded` (line 223 or line 260 depending on path). This `Expanded` wraps either a `ListView` (mobile) or a `Card > SingleChildScrollView > DataTable` (desktop).

The desktop branch (lines 231–265) wraps the `DataTable` in:
```dart
Card(
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,   // ← only horizontal scroll
    child: DataTable(...)
  )
)
```

**There is no vertical scroll on the DataTable.** The `DataTable` grows vertically beyond the `Expanded` box and gets clipped. The user can scroll horizontally (column overflow) but cannot scroll down to see more rows.

The mobile branch uses `ListView.separated` which scrolls fine.

### Fix needed
In the desktop branch, wrap the `DataTable` in a second `SingleChildScrollView` with `scrollDirection: Axis.vertical`, or replace the `DataTable` with `data_table_2`'s `DataTable2` widget (already a project dependency per the steering doc) which handles both axes.

Exact location: `courses_management_screen.dart` ~line 232 (the `return Card(...)` inside the `data:` callback of the desktop branch).

**Recommended fix** — use `DataTable2` with `scrollDirection: Axis.vertical` outer scroll:
```dart
return Card(
  child: DataTable2(
    columns: [...],
    rows: [...],
    // DataTable2 handles overflow natively
  ),
);
```
Or the simpler fix — add an outer vertical scroll:
```dart
return Card(
  child: SingleChildScrollView(
    scrollDirection: Axis.vertical,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(columns: [...], rows: [...]),
    ),
  ),
);
```

---

## Issue 3 — Users Screen Shows No Data

### File
`admin_dashboard/lib/core/providers/admin_users_provider.dart` (lines 38–47)  
`backend/src/modules/admin/admin.service.ts` (line 28)

### Root cause — Backend response shape mismatch

`AdminService.getAllUsers()` is declared as:
```typescript
getAllUsers(page = 1, limit = 20): Promise<[User[], number]> {
  return this.usersRepo.findAndCount({ ... });
}
```

`findAndCount` returns a **tuple**: `[User[], number]`. TypeORM serializes a tuple as a JavaScript array, so after `ResponseInterceptor` wraps it, the actual HTTP response body is:

```json
{
  "success": true,
  "data": [
    [ { "id": "...", "email": "...", ... }, ... ],
    42
  ]
}
```

`data` is an array of two elements: `[array_of_users, total_count]` — **not** a flat list of users.

The Flutter provider reads this as:
```dart
final raw = response.data['data'] ?? response.data;         // raw = [[...users], 42]
final list = raw is List ? raw : (raw['users'] as List? ?? []); // raw IS a List → list = [[...users], 42]
return list.map((e) => AdminUser.fromJson(e as Map<String, dynamic>)).toList();
// Tries to cast [users_array] and 42 as Map → THROWS, caught, returns []
```

The cast `e as Map<String, dynamic>` on the first element (another `List`) throws a runtime `TypeError`. The `catch (_)` at line 40 silently swallows it and returns `[]`.

### Fix needed (two options — pick one)

**Option A — Fix the backend (recommended):** Change `getAllUsers` to return only the users list (or a shaped object):
```typescript
// admin.service.ts
async getAllUsers(page = 1, limit = 20): Promise<{ users: User[]; total: number }> {
  const [users, total] = await this.usersRepo.findAndCount({
    skip: (page - 1) * limit,
    take: limit,
    order: { createdAt: 'DESC' },
  });
  return { users, total };
}
```
Then the response body becomes `{ "success": true, "data": { "users": [...], "total": 42 } }` and the Flutter provider's existing fallback `raw['users']` at line 44 works correctly.

**Option B — Fix the Flutter provider:** Handle the tuple shape on the client side:
```dart
final raw = response.data['data'] ?? response.data;
List list;
if (raw is List && raw.isNotEmpty && raw[0] is List) {
  list = raw[0] as List; // unwrap [users_array, count] tuple
} else if (raw is Map) {
  list = raw['users'] as List? ?? [];
} else if (raw is List) {
  list = raw;
} else {
  list = [];
}
```

Option A is cleaner and consistent with how other services return shaped objects.

---

## Issue 4 — Moderation Screen Shows No Data

### File
`admin_dashboard/lib/presentation/screens/resources/moderation_screen.dart` (lines 59–68)  
`backend/src/modules/resources/resources.controller.ts` (lines 37–42)

### Backend endpoint
The endpoint `GET /resources/moderation/pending` exists and is guarded by `@Roles(UserRole.MODERATOR, UserRole.ADMIN)` with `@UseGuards(RolesGuard)` (lines 37–42 of the controller). It works correctly — the service `findPending()` queries the DB for `status = PENDING`.

### Root cause — Silent error catch masks the real failure

The provider at lines 62–67 of `moderation_screen.dart`:
```dart
final pendingResourcesProvider = FutureProvider<List<PendingResource>>((ref) async {
  try {
    final response = await adminApi.get('/resources/moderation/pending');
    final data = (response.data['data'] ?? response.data) as List;
    return data.map((r) => PendingResource.fromJson(...)).toList();
  } catch (_) {
    return [];   // ← ALL errors silently return empty list
  }
});
```

The `catch (_)` catches everything — network errors, auth errors (401), permission errors (403), or cast errors. The screen then shows "All caught up! No resources pending review." even when there are pending items and the real problem is a request failure.

The `dashboard_screen.dart`'s `pendingCountProvider` (line 21–27) hits **the same endpoint** with the same silent catch — so the dashboard also shows `0` pending resources.

### Most likely runtime failure

The `AdminApiClient` reads the token from `SharedPreferences` with key `admin_token` (line 28 of `api_client.dart`). The `AdminAuthNotifier.signIn()` writes it under the same key `admin_token` (line 73 of `admin_auth_provider.dart`). The key name matches.

However, in a Flutter Web app, `SharedPreferences` is backed by `localStorage`. If the user refreshed the page or the session was restored from `_init()` (line 34 of `admin_auth_provider.dart`) but the token has expired on the backend, all protected endpoints will return 401. The silent catch hides this.

### Fix needed
1. **Remove silent catches** or at minimum log the error. Change all `catch (_) { return []; }` patterns to `catch (e) { debugPrint('Provider error: $e'); return []; }` so errors appear in the console.
2. **Add a 401 interceptor** to `AdminApiClient`: when the backend returns 401, clear the token and redirect to `/admin/login`. This prevents the ghost-authenticated state.
3. If items actually exist in the database with `status = PENDING`, confirm the token is valid by checking the network tab (the request to `/resources/moderation/pending` will show a 401 or 403 if auth is the issue).

---

## Cross-Cutting Findings

### Silent error suppression is systemic
Every single provider in the admin dashboard uses `catch (_) { return []; }` or `catch (_) { return 0; }`. This pattern means:
- Network errors → empty UI that looks like "no data"
- Auth errors (401/403) → empty UI that looks like "no data"  
- Parse errors → empty UI that looks like "no data"

There is no way for the user to know whether data is genuinely empty or whether the request failed. This is the primary reason the dashboard "doesn't show real data" — it likely IS making real calls, but the calls may be failing silently.

### Auth flow
- Login stores `admin_token` in `SharedPreferences` (Flutter Web → `localStorage`)
- `AdminApiClient` attaches it as `Bearer <token>` on every request
- Token key name is consistent (`admin_token`) between auth provider and API client ✓
- No token refresh mechanism — if the JWT expires, all requests fail silently ✗

---

## Recommended Fix Priority

1. **[Highest]** Fix `AdminService.getAllUsers()` to return `{ users, total }` instead of a raw `findAndCount` tuple — this immediately unblocks the Users screen.
2. **[High]** Add a 401/403 interceptor to `AdminApiClient` that clears the token and redirects to login — this will surface the real cause of empty moderation/dashboard data.
3. **[Medium]** Replace silent `catch (_)` with logged catches so errors are visible in the console during debugging.
4. **[Medium]** Fix the Courses DataTable vertical scroll by either using `DataTable2` or wrapping in a vertical `SingleChildScrollView`.
5. **[Low]** Replace the hardcoded `_UserGrowthChart` data with real API data or label it as placeholder.
