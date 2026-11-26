# Multi-University Feature — Code Review

**Commits reviewed:** `8a710de` (feat) + `d3b6dae` (fix/review-pass)  
**Diff base:** `main` (7848912)  
**Files changed:** 19

---

## Evidence Summary

### Backend

**universities module** — entity, service, controller, module, DTOs all present and correct.

- `university.entity.ts`: UUID PK, snake_case column names, `is_active` default true, timestamps. Correct.
- `create-university.dto.ts`: `@IsNotEmpty() @IsString() @MaxLength(200)` on `name`; optional fields carry `@IsOptional()`. All class-validator decorators present (BLK-01 from first review pass was fixed).
- `update-university.dto.ts`: extends `PartialType(CreateUniversityDto)` + explicit `@IsOptional() @IsBoolean() isActive`. `whitelist:true` ValidationPipe will not strip the field (BLK-02 fixed).
- `universities.service.ts`: TypeORM repository only, `findAll()` filters `isActive:true`, `findOne()` throws `NotFoundException` on miss, `create/update` follow existing pattern.
- `universities.controller.ts`: `GET /universities` and `GET /universities/:id` are `@Public()`. `POST` and `PATCH` are guarded by `JwtAuthGuard + RolesGuard + @Roles(ADMIN)`. No delete endpoint — intentional (soft-deactivate via `isActive`).
- `universities.module.ts`: imports `TypeOrmModule.forFeature([University])`, exports `UniversitiesService`. Registered in `app.module.ts` line 100.

**departments module changes**

- `department.entity.ts`: added `@Column({ name: 'university_id', nullable: true }) universityId: string`. Nullable — existing rows are unaffected. No TypeORM `@ManyToOne` decorator, so no synchronize-time schema generation concern (`synchronize: false` confirmed in app.module.ts). The DB migration handles the FK constraint.
- `departments.service.ts` `findAll()`: accepts optional `{ universityId?, universityName? }` filter; when both are absent returns all active departments (backward-compatible). `where: any` typing is acceptable given no TypeORM `FindOptionsWhere` complexity here.
- `departments.controller.ts`: `@ApiQuery` decorators added, `@Query` params forwarded to service. Existing callers that pass no query string continue to receive all departments.

**Migration SQL** (in commit body): creates `universities` table, inserts LAUTECH seed row (`ON CONFLICT DO NOTHING`), adds `university_id UUID REFERENCES universities(id) ON DELETE SET NULL` to departments, back-fills LAUTECH's departments. Non-destructive.

**app.module.ts**: `UniversitiesModule` import line is directly adjacent to `@Module({` with no blank line. ESLint reported 0 errors on changed files (commit evidence). Cosmetic only.

---

### Web App (`login_screen.dart`)

- `universitiesProvider`: calls `GET /universities`, falls back to a hardcoded LAUTECH entry (`id: 'lautech'`, BLK-03 fixed — was `null` in first commit).
- `departmentsByUniversityProvider`: family provider, calls `GET /departments?universityId=<id>` when id is non-null; fallback returns `[{'id': 'fisheries-lautech', ...}]` with a valid non-null id.
- University dropdown renders before department dropdown in `_SignUpFormState`. Selecting a university resets `_selectedDeptId = null`. Department dropdown only renders when `_selectedUniversityId != null`.
- `_submit()` has an explicit guard `if (_selectedDeptId == null)` (line 581) that sets `_error` and returns, so form submission cannot proceed without a department even when the department `FormField` is not in the widget tree (e.g., during async load).
- All colors use `AppColors.*`; `Nunito` font specified on all `TextStyle` instances. No hardcoded hex values.
- `flutter analyze web_app`: 9 issues, all pre-existing per commit evidence.

---

### Mobile App (`register_screen.dart`, `university_provider.dart`)

- `universitiesProvider` and `departmentsByUniversityProvider` defined in `university_provider.dart`; imported in `register_screen.dart` (replaces `department_provider.dart` import).
- `departmentsByUniversityProvider` returns `List<DepartmentModel>`. Register screen accesses `d.id` and `d.name` — both fields exist on `DepartmentModel`.
- University dropdown → department dropdown flow mirrors web. `_selectedDepartmentId` is reset to null when university changes.
- Mobile `universitiesProvider` returns empty list `[]` on error (no LAUTECH fallback). When empty, `DropdownButtonFormField` has no items and the validator fires on submit — registration is blocked until backend is reachable. This matches the original `primaryDepartmentProvider` behavior and is acceptable.
- `departmentId` is `@IsOptional()` on the backend `FirebaseAuthDto`, so sending `null` causes no data failure.
- `_register()` does not have an explicit null-guard for `_selectedDepartmentId` (unlike the web's explicit guard for `_selectedDeptId`). However: (a) the department `FormField` validator runs when the widget is in the tree and department is `null`; (b) the department widget is hidden during loading/error states, but in those states the university provider is also loading/error, so the university validator fires first. The only scenario where both pass and `_selectedDepartmentId` is null at submission is if the user somehow has a university selected but the department widget is in an error/loading state — in which case a null `departmentId` is sent, which the backend accepts. This is a UX imperfection (user registered without a department) but is not a data corruption — the app's profile-edit flow can supply it later, matching existing behavior.
- All colors use `AppColors.*`; font set at theme level.
- `flutter analyze mobile_app`: 15 issues, all pre-existing.

---

### Admin Dashboard

- `universities_screen.dart`: lists universities in a `DataTable` (Flutter material, not `data_table_2`). The `data_table_2` package is not in `admin_dashboard/pubspec.yaml` and no existing admin screen uses it, so this is consistent with existing convention in the actual codebase.
- Add/Edit dialog posts to `POST /universities` and `PATCH /universities/:id` — both admin-only endpoints. `onSaved()` calls `ref.invalidate(_universitiesProvider)` to refresh the list.
- All colors use `AdminColors.*`. `Colors.white` used for button foreground — consistent with `departments_screen.dart`.
- Route `/universities` registered in `admin_router.dart` under `AdminRoutes.universities`. Nav item added to sidebar after Departments.
- `flutter analyze admin_dashboard`: 2 issues, all pre-existing.

---

### API Constants

`ApiConstants.universities = '/universities'` added in both `web_app` and `mobile_app`. Correct path, matches controller route.

---

## Verdict

No blockers. All requirements are met. Prior review findings (BLK-01, BLK-02, BLK-03) have been resolved and verified in `d3b6dae`. Build/analyze evidence recorded in commit messages confirms no new errors.
