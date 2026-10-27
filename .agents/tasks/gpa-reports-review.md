# GPA Calculator and Admin Reports Screens

The change introduces a full GPA/CGPA calculator tab in the student web app, wires the admin reports screen to real flagged-content data, and adds two new backend endpoints (`GET /community/flagged` and `PATCH /community/flagged/:type/:id/resolve`) with their service methods. The Flutter side uses `FutureProvider.autoDispose`, `ConsumerStatefulWidget`, and `TabController` to tie everything together. The backend additions follow project conventions exactly.

Watch for: (1) **confirmed** — `unflagContent` in the service has an unvalidated `type` parameter at the controller level, making a non-admin path injection possible; (2) **confirmed** — `downvoteQuestion` and `downvoteAnswer` use raw SQL via `createQueryBuilder`, a pre-existing convention deviation (out of scope but worth noting); (3) **possible** — the `_resolve` action in the admin screen silently swallows errors for non-mounted state, which could leave `_actionLoading` permanently set for the affected item id.

**Verdict**: APPROVED

---

## High-level view

The GPA calculator correctly implements the Nigerian 5-point scale (`A=5.0` down to `F=0.0`) using a const map, and the live GPA formula (`Σ(gradePoints × creditUnits) / Σ(creditUnits)`) is computed purely client-side on every `build` call before being posted to the backend. All three new `ApiConstants` entries (`gpaCgpa`, `gpaSemesters`, `deleteSemester(id)`) are present and used throughout `progress_screen.dart` — no hardcoded path strings appear anywhere in the file.

Tab switching is wired correctly in both directions: the FAB on Tab 0 and the "Go to Calculator" button in the empty state both call `tabController.animateTo(1)`, and `_saveSemester` calls `widget.tabController.animateTo(0)` on success. Both `semestersProvider` and `cgpaProvider` are invalidated after a successful POST and after every DELETE, keeping the CGPA overview in sync.

The backend `getFlaggedContent` and `unflagContent` methods use TypeORM repositories cleanly, with no raw SQL. Both controller routes carry `@UseGuards(RolesGuard)` and `@Roles(UserRole.ADMIN)`, and the controller class-level `@UseGuards(JwtAuthGuard)` applies to all routes including these two, so the auth stack is `JwtAuthGuard → RolesGuard`.

The admin reports screen correctly uses `AdminColors` throughout — no hardcoded hex values. The student app `progress_screen.dart` uses `AppColors` throughout — no hardcoded hex values. Both screens use `Nunito` exclusively.

<details>
<summary>Issues (2)</summary>

1. **`type` param not validated at controller boundary** — `unflagContent` throws a `BadRequestException` for invalid `type` values, but this guard only fires at the service layer. Any string can reach the service. Add a `@IsIn(['question', 'answer'])` pipe or a union type check at the controller param level so malformed requests are rejected before entering service logic.

2. **Silent error drop in `_resolve` after unmount** — in `_ReportsScreenState._resolve`, the `catch` block only shows the snackbar `if (mounted)`. If the widget unmounts mid-request, `_actionLoading[item.id]` is never cleared (the `finally` block correctly guards with `if (mounted)` before clearing). This is a minor resource concern rather than a data correctness issue, but a stuck loading state could appear on re-mount if the state object is reused. The pattern used in `connections_screen.dart` (which the plan cites as the reference) removes the key unconditionally in `finally`. Align with that pattern.

</details>

<details>
<summary>Details</summary>

### `type` parameter validation gap — confirmed

`unflagContent` in the service rejects invalid types via `BadRequestException`:

```typescript
if (type !== "question" && type !== "answer") {
  throw new BadRequestException("type must be question or answer");
}
```

However, the controller receives `type` as a raw `@Param('type') type: 'question' | 'answer'` string. TypeScript union types are erased at runtime, so any string reaching the handler passes the TypeScript type check and lands in the service unchecked. Because this is an admin-only route behind JWT + RolesGuard, the blast radius is limited to admin accounts, but it's still better to validate at the boundary. Adding a custom pipe or a `@IsIn` validation step on the param would reject malformed requests at the HTTP layer with a consistent 400 before service logic runs.

### Silent loading-state persistence in `_resolve` — possible

```dart
} catch (_) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(/* … */);
  }
} finally {
  if (mounted) setState(() => _actionLoading.remove(item.id));
}
```

If `mounted` is false at the time `finally` runs, the `_actionLoading` entry for `item.id` is never removed. In practice this matters only if the widget is disposed while a PATCH is in flight and then re-created within the same session — unlikely but the reference implementation (`connections_screen.dart`) removes the key unconditionally in `finally` to avoid it.

### Raw-SQL downvote methods (pre-existing, out of scope)

`downvoteQuestion` and `downvoteAnswer` use `createQueryBuilder` with a raw SQL expression (`GREATEST(upvote_count - 1, 0)`). These are untouched by this PR and are noted only for completeness.

</details>

---

## File map

<details>
<summary>Changed files</summary>

- `web_app/lib/core/constants/api_constants.dart` — added `gpaCgpa`, `gpaSemesters`, `deleteSemester(id)` constants
- `web_app/lib/presentation/screens/progress/progress_screen.dart` — full rewrite: two-tab GPA calculator with live formula, CGPA overview, semester management
- `admin_dashboard/lib/presentation/screens/reports/reports_screen.dart` — full rewrite: fetches real flagged content, Resolve/Dismiss actions wired
- `backend/src/modules/community/community.service.ts` — added `getFlaggedContent()` and `unflagContent()` methods
- `backend/src/modules/community/community.controller.ts` — added `GET /community/flagged` and `PATCH /community/flagged/:type/:id/resolve` admin-only routes

</details>
