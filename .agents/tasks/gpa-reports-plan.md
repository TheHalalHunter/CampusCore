# Implementation Plan: GPA Calculator + Admin Reports Fix

---

## Findings from codebase exploration

### Fix 1 — GPA screen
- **Backend is complete.** `GET /gpa/cgpa`, `GET /gpa/semesters`, `POST /gpa/semesters`, `DELETE /gpa/semesters/:id` all exist in `backend/src/modules/gpa/gpa.controller.ts`.
- The current `progress_screen.dart` calls `ApiConstants.gpa` (`/gpa`) which is not a real endpoint. The entire screen needs to be replaced.
- `api_constants.dart` only has `static const String gpa = '/gpa'` — three new entries are needed.
- Style reference: `connections_screen.dart` uses `ConsumerStatefulWidget`, `TabController`, `FutureProvider.autoDispose`, `AppColors`, `Nunito`, card-based list tiles. The GPA screen will follow the same pattern.
- The `SaveSemesterDto` requires: `academicLevel` (string, e.g. "100L"), `semester` (int 1–2), `academicYear` (optional string), `courses` (array of `{name, creditUnits, grade, gradePoints}`), `gpa` (number), `totalUnits` (number). Grade points must be calculated client-side before posting.

### Fix 2 — Admin Reports screen
- **No `GET /community/flagged` endpoint exists.** The controller has `POST /community/flag/:type/:id` to flag content but no endpoint to _fetch_ flagged content.
- **No resolve endpoint exists.** The controller has `PATCH /community/questions/:id/resolve` but that marks a question as resolved by its author, not an admin unflag action.
- Both `Question` and `Answer` entities have `isFlagged: boolean` field.
- The `CommunityService.findQuestions()` already filters `isFlagged: false` so flagged content is invisible to students — correct behaviour.
- Two new backend methods and two new controller endpoints are needed: `GET /community/flagged` and `PATCH /community/flagged/:type/:id/resolve`.
- The admin dashboard uses `AdminApiClient` (a plain Dio wrapper at `admin_dashboard/lib/core/utils/api_client.dart`). There is no shared constants file — API paths are used inline. The reports screen is a `StatelessWidget` importing only `admin_theme.dart`. It needs to be converted to `ConsumerStatefulWidget` with Riverpod.
- The admin dashboard `pubspec.yaml` already has `flutter_riverpod`.

---

## Implementation Plan

- [ ] 1. **Add GPA constants to `api_constants.dart`**

  Three new entries under the `// Progress / GPA` section. The old `gpa` and `progress` constants can remain (they are referenced elsewhere potentially) — add the three new specific ones below them.

  File: `web_app/lib/core/constants/api_constants.dart`

  Add:
  ```dart
  static const String gpaCgpa      = '/gpa/cgpa';
  static const String gpaSemesters = '/gpa/semesters';
  static String deleteSemester(String id) => '/gpa/semesters/$id';
  ```

  Verify: `flutter analyze web_app` — no new errors.

---

- [ ] 2. **Rewrite `progress_screen.dart` as a full GPA calculator**

  Replace the entire file. The new screen must:

  **Providers (file-top, autoDispose FutureProviders):**
  - `cgpaProvider` — calls `GET ApiConstants.gpaCgpa`, returns `Map<String, dynamic>` with `{cgpa, totalUnits, semesterCount, classification}`.
  - `semestersProvider` — calls `GET ApiConstants.gpaSemesters`, returns `List<Map<String, dynamic>>`, each with `{id, academicLevel, semester, academicYear, courses: [{name, creditUnits, grade, gradePoints}], gpa, totalUnits, createdAt}`.

  **Screen class:** `ProgressScreen extends ConsumerStatefulWidget`

  State holds:
  - `TabController _tabController` (length 2)
  - No other top-level state; calculator state lives in the child widget.

  **Tab 0 — CGPA Overview:**
  - Top CGPA card: circular badge (same pattern as existing code, styled with `_gpaColor(cgpa)`), shows CGPA to 2 decimal places, classification label, total units, semester count.
  - "Add Semester" FAB (`FloatingActionButton.extended`) — switches to Tab 1 via `_tabController.animateTo(1)`.
  - Semester list: `semestersProvider.when(...)`. Each saved semester shown in an `ExpansionTile`-based card:
    - Header: level + semester label (e.g. "200L — Semester 1"), GPA chip, total units chip, delete `IconButton` (calls `DELETE ApiConstants.deleteSemester(id)` then `ref.invalidate(semestersProvider)` and `ref.invalidate(cgpaProvider)`).
    - Expanded body: `ListView` of courses showing name, credit units, grade badge (use `_gradeColor(grade)` helper — copy from existing screen), grade points.
  - If semesters list is empty: centred empty state icon + "No semesters saved yet. Use the GPA Calculator tab to add one."
  - Loading/error states follow the same pattern as `connections_screen.dart`.

  **Tab 1 — GPA Calculator:**

  This tab is a `ConsumerStatefulWidget` subwidget `_GpaCalculatorTab` with its own local state:
  - `String _selectedLevel` (default `'100L'`, values: `['100L','200L','300L','400L','500L']`)
  - `int _selectedSemester` (default `1`, values: `[1, 2]`)
  - `String _academicYear` (text field, optional)
  - `List<_CourseRow>` `_courses` (starts with one empty row)
  - `bool _isSaving`

  `_CourseRow` is a small data class with: `TextEditingController nameCtrl`, `int creditUnits` (default 3), `String grade` (default `'A'`).

  **Grade points map** (const):
  ```dart
  static const Map<String, double> _gradePoints = {
    'A': 5.0, 'B': 4.0, 'C': 3.0, 'D': 2.0, 'E': 1.0, 'F': 0.0,
  };
  ```

  **Live GPA computation** — pure function, called from `build`:
  ```
  gpa = sum(gradePoints[grade] * creditUnits) / sum(creditUnits)
  ```
  Show result in a sticky bottom summary bar: "GPA: X.XX — Total Units: N".

  **Course row widget** (inline `_buildCourseRow(int index)`):
  - `TextField` for course name (flex: 3)
  - `DropdownButton<int>` for credit units 1–6 (flex: 1)
  - `DropdownButton<String>` for grade A/B/C/D/E/F, with auto-shown grade points as subtitle (flex: 1)
  - `IconButton(Icons.delete_outline)` — disabled when only 1 row remains.

  **"Add Course" button** — adds a new `_CourseRow` to the list.

  **"Save Semester" button** (full-width `ElevatedButton`):
  1. Validate: every course name non-empty. Show `ScaffoldMessenger` snackbar if invalid.
  2. Compute final `gpa` and `totalUnits`.
  3. Build DTO and `POST ApiConstants.gpaSemesters`.
  4. On success: `ref.invalidate(semestersProvider)`, `ref.invalidate(cgpaProvider)`, reset form, switch tab to 0.
  5. On error: show error snackbar.
  6. `_isSaving` guards a `CircularProgressIndicator` on the button.

  **Helper methods to keep** (from existing screen):
  - `_gpaColor(double gpa)` — returns `AppColors.*` based on classification thresholds.
  - `_gpaClass(double gpa)` — returns classification string.
  - `_gradeColor(String grade)` — returns colour per letter grade.

  File: `web_app/lib/presentation/screens/progress/progress_screen.dart`

  Verify: `flutter analyze web_app` — zero errors.

---

- [ ] 3. **Add `getFlaggedContent` and `unflagContent` methods to `CommunityService`**

  Add two methods to `backend/src/modules/community/community.service.ts`:

  ```typescript
  async getFlaggedContent(): Promise<{ questions: Question[]; answers: Answer[] }> {
    const [questions, answers] = await Promise.all([
      this.questionsRepo.find({ where: { isFlagged: true }, order: { createdAt: 'DESC' } }),
      this.answersRepo.find({ where: { isFlagged: true }, order: { createdAt: 'DESC' } }),
    ]);
    return { questions, answers };
  }

  async unflagContent(type: 'question' | 'answer', id: string): Promise<void> {
    if (type === 'question') {
      await this.questionsRepo.update(id, { isFlagged: false });
    } else {
      await this.answersRepo.update(id, { isFlagged: false });
    }
  }
  ```

  File: `backend/src/modules/community/community.service.ts`

  Verify: `cd backend && npm run build` — compiles without errors.

---

- [ ] 4. **Add `GET /community/flagged` and `PATCH /community/flagged/:type/:id/resolve` endpoints to `CommunityController`**

  Both routes are admin-only: decorated with `@UseGuards(RolesGuard)` and `@Roles(UserRole.ADMIN)`.

  Add to `backend/src/modules/community/community.controller.ts`:

  ```typescript
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @Get('flagged')
  @ApiOperation({ summary: 'Get all flagged questions and answers (admin only)' })
  getFlagged() {
    return this.service.getFlaggedContent();
  }

  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @Patch('flagged/:type/:id/resolve')
  @ApiOperation({ summary: 'Unflag (resolve) a flagged question or answer (admin only)' })
  resolveFlag(
    @Param('type') type: 'question' | 'answer',
    @Param('id') id: string,
  ) {
    return this.service.unflagContent(type, id);
  }
  ```

  File: `backend/src/modules/community/community.controller.ts`

  Verify: `cd backend && npm run build` — compiles without errors.

---

- [ ] 5. **Rewrite `reports_screen.dart` to fetch and display real flagged content**

  Replace the entire file. The screen must become a `ConsumerStatefulWidget`.

  **Provider (file-top):**
  ```dart
  final flaggedContentProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
    final resp = await adminApi.get('/community/flagged');
    final data = resp.data['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'questions': [], 'answers': []};
  });
  ```

  **Screen structure:**
  - `Padding(padding: const EdgeInsets.all(28), child: Column(...))`
  - Header: `Text('Reports')` + subtitle `Text('Review flagged content and misconduct reports')`
  - `flaggedContentProvider.when(loading, error, data)`:
    - Loading: centred `CircularProgressIndicator`
    - Error: centred error text + retry button (`ref.invalidate(flaggedContentProvider)`)
    - Data: build combined list from `data['questions']` and `data['answers']`

  **Combined list building:**
  - Map each question to a `_FlaggedItem(type: 'question', id, title: q['title'], body: q['body'], createdAt: q['createdAt'])`.
  - Map each answer to a `_FlaggedItem(type: 'answer', id, title: 'Answer', body: a['body'], createdAt: a['createdAt'])`.
  - Sort combined list by `createdAt` descending.
  - If empty: centred empty state icon + "No flagged content. Everything looks clean."

  **`_FlaggedItem` data class** (private, in same file):
  ```dart
  class _FlaggedItem {
    final String type; // 'question' or 'answer'
    final String id;
    final String title;
    final String body;
    final String createdAt;
  }
  ```

  **`_FlagItem` card widget** — mirrors the existing `_ReportCard` layout but with real data:
  - Left icon: `Icons.flag` in `AdminColors.error` tinted container.
  - Type badge chip: "Question" or "Answer" in `AdminColors.warning` tint.
  - Date: formatted `createdAt`.
  - Title + truncated body (1 line, overflow ellipsis).
  - Action buttons:
    - **Resolve** (`ElevatedButton`, `AdminColors.primary`) — calls `PATCH /community/flagged/{type}/{id}/resolve`, then `ref.invalidate(flaggedContentProvider)`. Show loading indicator in button while in-flight.
    - **Dismiss** (`TextButton`) — same API call as Resolve (both just unflag; "dismiss" means "this isn't a real problem, unflag it"). Both call the same endpoint.
  - Loading state: replace both buttons with a `SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth:2))`.

  **State for action loading:**
  Use a `Map<String, bool> _actionLoading` in the screen's `State` class (key = item id), same pattern as `connections_screen.dart`.

  File: `admin_dashboard/lib/presentation/screens/reports/reports_screen.dart`

  Imports needed: `flutter_riverpod`, `admin_theme.dart`, `../../../core/utils/api_client.dart`

  Verify: `flutter analyze admin_dashboard` — zero errors.

---

## Verification summary

After all items are done, run these commands from the repo root:

```
cd backend && npm run build
cd web_app && flutter analyze
cd admin_dashboard && flutter analyze
```

All three must exit clean (zero errors).
