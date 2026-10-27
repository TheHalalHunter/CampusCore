# Implementation Plan — CampusCore Remaining Features

Workspace root: `c:\Users\USER\Documents\CampusCoreNew`

## Key findings from codebase exploration

- **AppUser** already maps `avatarUrl` from `json['avatarUrl'] ?? json['avatar']` — no model change needed; only AuthNotifier needs an `updateAvatar` method.
- **SupabaseStorageService** is in `web_app/lib/core/storage/supabase_storage.dart` — upload to bucket `Resources`, path `avatars/{userId}/{timestamp}.{ext}`.
- **file_picker ^8.1.2** is already in `web_app/pubspec.yaml` — no new dependency.
- **shared_preferences ^2.2.3** is already in `web_app/pubspec.yaml` — no new dependency.
- **NestJS module pattern**: `entities/`, `dto/`, service, controller, module files. TypeORM entity glob auto-discovers new entities; only the module import in `app.module.ts` is required.
- **AdminApi**: singleton `adminApi` from `admin_dashboard/lib/core/utils/api_client.dart` — used directly (not via provider).
- **Admin sidebar** uses a `const _navItems` list of `_NavItem` objects in `_AdminSidebar` class.
- **Community controller** already has `PATCH community/answers/:id/verify` endpoint — admin moderation screen only needs a Flutter UI.
- **Backend lint**: `npm run lint` in `backend/`. **Flutter analysis**: `flutter analyze` in respective app directories.

---

## FEAT-001 — Profile Picture Upload

- [ ] 1. Add `updateAvatar(String avatarUrl)` method to `AuthNotifier` in `web_app/lib/core/providers/auth_provider.dart`.
      Calls `PATCH /users/me` with body `{ 'avatar': avatarUrl }`, parses response into a new `AppUser` using `AppUser.fromJson`, saves to `TokenStorage`, updates state with `state.copyWith(user: updated, isLoading: false)`.
      Files: `web_app/lib/core/providers/auth_provider.dart`
      Verify: `cd web_app && flutter analyze`

- [ ] 2. Replace the plain `CircleAvatar` in the avatar card section of `_ProfileScreenState.build` with a `GestureDetector → Stack` that shows `Image.network` when `user.avatarUrl` is set (wrapped in `ClipOval`), otherwise initials. Add a bottom-right camera icon overlay using `Positioned`. Add `_pickAndUploadAvatar()` async method that calls `FilePicker.platform.pickFiles` (jpg/jpeg/png only, `withData: true`), builds path `avatars/${user.id}/${timestamp}.{ext}`, calls `SupabaseStorageService.uploadFile`, then `ref.read(authProvider.notifier).updateAvatar(downloadUrl)`.
      Files: `web_app/lib/presentation/screens/profile/profile_screen.dart`
      Verify: `cd web_app && flutter analyze`

---

## FEAT-002 — Study Groups (Backend + Flutter)

Dependencies: none — independent of FEAT-001.

### Backend

- [ ] 3. Create `backend/src/modules/study-groups/entities/study-group.entity.ts`.
      `@Entity('study_groups')` with fields: `id` (uuid PK), `name` (varchar 200), `description` (text nullable), `departmentId` (column `department_id`, nullable), `createdBy` (column `created_by`), `maxMembers` (default 50), `isActive` (default true), `createdAt` (@CreateDateColumn).
      Files: `backend/src/modules/study-groups/entities/study-group.entity.ts`

- [ ] 4. Create `backend/src/modules/study-groups/entities/study-group-member.entity.ts`.
      `@Entity('study_group_members') @Unique(['groupId','userId'])` with fields: `id` (uuid PK), `groupId` (column `group_id`), `userId` (column `user_id`, @Index), `joinedAt` (@CreateDateColumn `joined_at`).
      Files: `backend/src/modules/study-groups/entities/study-group-member.entity.ts`

- [ ] 5. Create DTOs in `backend/src/modules/study-groups/dto/`.
      `create-study-group.dto.ts`: `@IsString() @MaxLength(200) name`; `@IsOptional() @IsString() description?`; `@IsOptional() @IsInt() @Min(2) @Max(200) maxMembers?`.
      `query-study-groups.dto.ts`: `@IsOptional() @IsUUID() departmentId?`.
      Files: `backend/src/modules/study-groups/dto/create-study-group.dto.ts`, `backend/src/modules/study-groups/dto/query-study-groups.dto.ts`

- [ ] 6. Create `backend/src/modules/study-groups/study-groups.service.ts`.
      `@Injectable() StudyGroupsService`. Inject `@InjectRepository(StudyGroup)` and `@InjectRepository(StudyGroupMember)`. Methods: `findByDepartment(departmentId)` (active groups + member count via QueryBuilder); `createGroup(userId, dto, departmentId?)` (auto-sets createdBy, auto-joins creator); `joinGroup(userId, groupId)` (throws ConflictException if member, NotFoundException if not found, ForbiddenException if at capacity); `leaveGroup(userId, groupId)`; `findUserGroups(userId)`.
      Files: `backend/src/modules/study-groups/study-groups.service.ts`

- [ ] 7. Create `backend/src/modules/study-groups/study-groups.controller.ts`.
      `@Controller('study-groups') @UseGuards(JwtAuthGuard)`. Routes: `GET /` (list by dept); `POST /` (create); `POST /:id/join`; `DELETE /:id/leave`; `GET /my`. Use `@CurrentUser() user: User` and `@Query()` / `@Body()` patterns from `community.controller.ts`.
      Files: `backend/src/modules/study-groups/study-groups.controller.ts`

- [ ] 8. Create `backend/src/modules/study-groups/study-groups.module.ts`.
      `TypeOrmModule.forFeature([StudyGroup, StudyGroupMember])`, providers + controllers + exports.
      Files: `backend/src/modules/study-groups/study-groups.module.ts`

- [ ] 9. Register `StudyGroupsModule` in `backend/src/app.module.ts`. Add import statement and add to `imports` array.
      Files: `backend/src/app.module.ts`
      Verify: `cd backend && npm run lint`

### Database

- [ ] 10. Append study_groups DDL to `database/schema.sql`:
      ```sql
      CREATE TABLE IF NOT EXISTS study_groups ( ... );
      CREATE TABLE IF NOT EXISTS study_group_members ( ... );
      CREATE INDEX IF NOT EXISTS idx_study_groups_department ON study_groups(department_id);
      CREATE INDEX IF NOT EXISTS idx_study_group_members_group ON study_group_members(group_id);
      CREATE INDEX IF NOT EXISTS idx_study_group_members_user ON study_group_members(user_id);
      ```
      Full DDL is in the task description.
      Files: `database/schema.sql`

### Flutter

- [ ] 11. Add study groups API constants to `web_app/lib/core/constants/api_constants.dart`:
      `studyGroups = '/study-groups'`, `studyGroupsMy = '/study-groups/my'`, `joinStudyGroup(id)`, `leaveStudyGroup(id)`.
      Files: `web_app/lib/core/constants/api_constants.dart`

- [ ] 12. Create `web_app/lib/presentation/screens/study_groups/study_groups_screen.dart`.
      `ConsumerStatefulWidget` with `DefaultTabController(length:2)`. Two `FutureProvider`s for discover/my-groups. Group cards show name, description, member count, Join/Leave button. FAB opens create-group dialog. All colors via `AppColors`, Nunito font.
      Files: `web_app/lib/presentation/screens/study_groups/study_groups_screen.dart`

- [ ] 13. Add route `/study-groups` to `web_app/lib/app/router/app_router.dart`.
      Import `StudyGroupsScreen`, add `GoRoute(path: '/study-groups', name: 'study-groups', ...)` inside `ShellRoute`.
      Files: `web_app/lib/app/router/app_router.dart`

- [ ] 14. Add Study Groups nav item to `web_app/lib/app/shell/app_shell.dart` `_navItems` list between Library (index 8) and Profile (index 9):
      `(label: 'Study Groups', route: '/study-groups', icon: Icons.groups_outlined)`
      Files: `web_app/lib/app/shell/app_shell.dart`
      Verify: `cd web_app && flutter analyze`

---

## FEAT-003 — Recent Activity

Dependencies: none — independent of FEAT-001 and FEAT-002.

- [ ] 15. Create `web_app/lib/core/storage/activity_storage.dart`.
      `class ActivityStorage` with static methods: `addResourceView({id, title, type})`, `addQuestionView({id, title})`, `getRecentActivity()`. Uses `SharedPreferences` with keys `'recent_resources'` and `'recent_questions'`. Each item is `{id, title, type?, itemType, timestamp}`. `getRecentActivity` merges both lists, sorts by timestamp descending, returns first 8 items.
      Files: `web_app/lib/core/storage/activity_storage.dart`

- [ ] 16. Add `recentActivityProvider` and 'Recent Activity' section to `web_app/lib/presentation/screens/home/home_screen.dart`.
      `recentActivityProvider = FutureProvider.autoDispose<List<Map<String,dynamic>>>` that calls `ActivityStorage.getRecentActivity()`. In `build`, insert the section **after** Quick Actions and **before** Recent Questions. Each item: `ListTile` in a `Card` with `Icons.description_outlined` (AppColors.primary) for resources or `Icons.forum_outlined` (AppColors.cyan) for questions; tapping navigates to `/resources` or `/community/{id}`. Show up to 3 items.
      Files: `web_app/lib/presentation/screens/home/home_screen.dart`
      Verify: `cd web_app && flutter analyze`

- [ ] 17. Call `ActivityStorage.addResourceView` in `web_app/lib/presentation/screens/courses/course_detail_screen.dart`.
      In `_ResourceTile.build`, inside the trailing `IconButton.onPressed` (the download button), call `ActivityStorage.addResourceView(id: resource['id']?.toString() ?? '', title: title, type: type ?? 'other')` before `launchUrl`. Add import for `activity_storage.dart`.
      Files: `web_app/lib/presentation/screens/courses/course_detail_screen.dart`

- [ ] 18. Call `ActivityStorage.addQuestionView` in `web_app/lib/presentation/screens/community/question_detail_screen.dart`.
      In `_QuestionDetailScreenState.build`, inside the `data:` branch of `questionAsync.when`, before building `_QuestionDetailBody`, fire-and-forget `ActivityStorage.addQuestionView(id: widget.questionId, title: question['title']?.toString() ?? '')`. Add import for `activity_storage.dart`.
      Files: `web_app/lib/presentation/screens/community/question_detail_screen.dart`
      Verify: `cd web_app && flutter analyze`

---

## FEAT-004 — Admin Answer Moderation

Dependencies: none — independent of FEAT-001, FEAT-002, FEAT-003. Backend endpoint `PATCH community/answers/:id/verify` already exists.

- [ ] 19. Create `admin_dashboard/lib/presentation/screens/community/community_moderation_screen.dart`.
      Two providers: `adminQuestionsProvider` (GET `/community/questions?limit=50` via `adminApi`) and `adminQuestionAnswersProvider` (family, GET `/community/questions/:id` to get answers). Screen: `ConsumerWidget`, `Padding(28)` wrapping a `Column` with `_PageHeader` + `ListView` of `ExpansionTile` per question. Each expansion fetches and lists `_AnswerModerationCard` widgets. `_AnswerModerationCard` shows author name, body, 'Verify' button (calls `adminApi.patch('/community/answers/:id/verify')`, then invalidates provider) or green 'Verified' badge. All colors via `AdminColors`.
      Files: `admin_dashboard/lib/presentation/screens/community/community_moderation_screen.dart`

- [ ] 20. Add `community = '/community'` to `AdminRoutes` and register `GoRoute` in `admin_dashboard/lib/app/router/admin_router.dart`.
      Import `CommunityModerationScreen`, add `static const String community = '/community'` to `AdminRoutes`, add `GoRoute(path: AdminRoutes.community, builder: (_, __) => const CommunityModerationScreen())` inside the `ShellRoute` routes list.
      Files: `admin_dashboard/lib/app/router/admin_router.dart`

- [ ] 21. Add Community sidebar item to `admin_dashboard/lib/presentation/shell/admin_shell.dart`.
      In `_AdminSidebar._navItems` const list, insert `_NavItem(icon: Icons.forum_outlined, label: 'Community', route: AdminRoutes.community)` after the existing Moderation item and before Departments.
      Files: `admin_dashboard/lib/presentation/shell/admin_shell.dart`
      Verify: `cd admin_dashboard && flutter analyze`

---

## Ordering constraints

- Items 3–9 (backend) must be done in order (entities before service before controller before module before app.module).
- Items 11–14 (Flutter study groups) can be done after item 9 but are independent of items 1–2.
- Items 15–18 (recent activity) are fully independent.
- Items 19–21 (admin moderation) are fully independent.
- FEAT-001, FEAT-003, FEAT-004 have no inter-dependencies.
- FEAT-002 has no dependencies on the other FEATs.

## Verification summary

| Step | Command |
|------|---------|
| After FEAT-001 | `cd web_app && flutter analyze` |
| After backend (FEAT-002) | `cd backend && npm run lint` |
| After Flutter web_app (FEAT-002, 003) | `cd web_app && flutter analyze` |
| After admin (FEAT-004) | `cd admin_dashboard && flutter analyze` |
