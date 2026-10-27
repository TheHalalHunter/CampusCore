# Five-fix patch: community parsing, resources tab, AI nav, admin chart, keep-alive ping

This patch addresses five user-reported issues: the community Q&A screen returning a
blank "Retry" state, the course resources tab showing an error instead of a skeleton
loader, the "Ask AI Tutor" button doing nothing, the admin dashboard growth chart
displaying hardcoded fake data, and both web apps cold-starting on Render after
inactivity. This is review-iteration 2; both blocking findings from iteration 1
(community cold-load retry, dead `_RoleBreakdownChart`) have been resolved.

**Watch for:** nothing new — all prior findings addressed, release build passes.

**Verdict**: APPROVED

---

## High-level view

The community provider's auth guard now returns `[]` (empty list) when Firebase hasn't
finished initialising, so the screen shows the loading skeleton on cold render instead
of the Retry widget. The shaped `{ questions, total }` response is unwrapped correctly
before the flat-list fallback, and a tuple fallback for TypeORM array results is also
present.

The course resources tab uses `ref.watch` (not `ref.read`) so the provider re-evaluates
on cache eviction, and the tuple check is ordered ahead of the flat-list branch. The
`_ResourcesTab` receives the `AsyncValue` from the parent `ConsumerStatefulWidget`,
avoiding a redundant provider watch inside a plain `StatelessWidget`.

The "Ask AI Tutor" button in `course_detail_screen.dart` calls `context.go('/ai')`, and
`/ai` is confirmed registered in `app_router.dart` under the `ShellRoute`. The same
route is also reachable from the Quick Actions chip on the home dashboard.

The admin growth chart is driven entirely by `/admin/stats` → `byRole` list. The old
`_RoleBreakdownChart` dead-code class is gone (no matches anywhere in the tree). The
`_UsersByRoleBarChart` widget gracefully renders a "No data" placeholder when `byRole` is
empty, and uses `AdminColors` throughout.

Both `main.dart` files (web_app and admin_dashboard) install an identical keep-alive
`Timer.periodic` after `runApp`, using a dedicated `Dio` instance with 10-second
timeouts targeting the lightweight `/api/v1/departments` endpoint. Errors are swallowed,
which is correct for a silent background pinger.

---

<details>
<summary>Issues (0)</summary>

No blocking or non-blocking concerns remain.

</details>

<details>
<summary>Details</summary>

### Community auth guard: return vs throw

The iteration-1 finding was that `throw Exception('Auth not ready')` caused
`questionsProvider` to land in `AsyncError` on every cold render. The fix replaces it
with `return []`, confirmed at line 18 of `community_screen.dart`:

```dart
if (!authState.initialized) return [];
```

The provider now emits `AsyncData([])` before auth resolves, the loading skeleton renders
while Riverpod re-evaluates once `authState.initialized` flips true, and the full
question list loads without user interaction.

### Course resources tab: loading state

`_ResourcesTab.loading` now returns `const Center(child: CircularProgressIndicator())`
rather than an infinite skeleton list, which is consistent with the rest of the app's
loading patterns. The error path shows a Retry button; the empty path shows a folder
icon with copy. All three states are handled.

### Keep-alive ping lifecycle

The `Timer` is created after `runApp` returns, so it doesn't block app startup. The
`Dio` instance used for pinging is separate from the app's `ApiClient` to avoid
interfering with auth interceptors or response parsing. No cancellation mechanism exists
for the timer (it runs for the lifetime of the app process), which is acceptable for a
web app where the process terminates with the tab.

</details>

---

## File map

<details>
<summary>Changed files</summary>

| File | What changed |
|------|-------------|
| `web_app/lib/presentation/screens/community/community_screen.dart` | Auth guard changed from `throw` to `return []`; dead code class removed |
| `admin_dashboard/lib/presentation/screens/dashboard/dashboard_screen.dart` | `_RoleBreakdownChart` dead-code class removed; `const` added to static `ListTile` |
| `web_app/lib/presentation/screens/courses/course_detail_screen.dart` | "Ask AI Tutor" button wired to `context.go('/ai')` |
| `web_app/lib/main.dart` | Keep-alive `Timer.periodic` ping |
| `admin_dashboard/lib/main.dart` | Keep-alive `Timer.periodic` ping (same pattern) |

</details>
