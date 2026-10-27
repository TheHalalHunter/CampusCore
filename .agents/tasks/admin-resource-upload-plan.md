# Implementation Plan — Admin Resource Upload

## Summary

Admins can upload resources directly from the admin dashboard.
When submitted by an admin, the resource is immediately `approved` and `isOfficial = true`
— no moderation queue, no separate review step needed.

---

## What the exploration found

### Backend
- `resources.service.ts` → `submit()` always hard-codes `status: PENDING`. No role check.
- `resources.controller.ts` → `POST /resources` calls `submit(user.id, body)` — the full
  `User` object is already available on the request via `@CurrentUser()`, so the role is
  reachable without an extra DB lookup.
- `resources.module.ts` → already imports `UsersModule`; `UsersService` is already
  injectable. **No module change needed** — `UsersService` does not need to be injected
  into `ResourcesService` at all; the role is on the `User` already passed to `submit()`.
- `resource.entity.ts` → has `status` (`pending/approved/rejected`) and `isOfficial`
  (`boolean`, default `false`). Both fields exist — no migration needed.
- `UserRole` enum is in `backend/src/modules/users/enums/user-role.enum.ts`.

### Admin Dashboard (Flutter Web)
- `pubspec.yaml` — has `firebase_core: ^3.13.0` and `firebase_auth: ^5.5.0`.
  Neither `firebase_storage` nor `file_picker` is present. They must be added.
  **Version correction:** the task requested `firebase_storage: ^11.0.0` but that
  version is incompatible with `firebase_core: ^3.x`. The FlutterFire BoM for
  `firebase_core ^3.x` ships with `firebase_storage ^13.x`. Use
  `firebase_storage: ^13.4.1` (pinned patch, compatible with `firebase_core: ^3.13.0`).
  Use `file_picker: ^8.0.0` as specified.
- `firebase_options.dart` → `storageBucket` is already configured
  (`campuscore-5658f.firebasestorage.app`). Firebase Storage is initialised on every app
  start via `firebase_core`. No extra init step is needed.
- `admin_dashboard/lib/core/utils/api_client.dart` → `AdminApiClient` wraps Dio and
  exposes `get`, `post`, `patch`, `delete`. The `adminApi` singleton is imported by every
  screen. The upload dialog will use it directly.
- Existing provider pattern: `FutureProvider` (stateless) and `StateNotifierProvider`
  (stateful) defined inline in the screen file or in
  `lib/core/providers/`. The courses dropdown data already exists as
  `adminCoursesProvider(departmentId)` in `courses_management_screen.dart`.
  The departments list is in `adminDepartmentsSharedProvider`
  (`admin_departments_provider.dart`).
- `AdminColors` constants for all colours — never hardcode hex.
- Dialogs follow the `AlertDialog` + `StatefulWidget` pattern used throughout (see
  `_CourseFormDialog` in `courses_management_screen.dart`).

---

## Implementation Plan

- [ ] 1. **Backend — update `submit()` to auto-approve admin/lecturer uploads**

  Change `resources.service.ts` so that when the calling user's role is `ADMIN` or
  `LECTURER`, the resource is saved with `status: APPROVED` and `isOfficial: true`.
  The controller already passes only `uploaderId` (string) — **change the controller**
  to pass the full `User` to `submit()` so the service can read the role without an
  extra DB hit.

  Files to modify:
  - `backend/src/modules/resources/resources.service.ts`
  - `backend/src/modules/resources/resources.controller.ts`

  Exact changes:

  **`resources.controller.ts`** — change `POST /` handler:
  ```ts
  @Post()
  submit(@CurrentUser() user: User, @Body() body: any) {
    return this.service.submit(user, body);   // pass full User, not user.id
  }
  ```

  **`resources.service.ts`** — change `submit()` signature and body:
  ```ts
  async submit(uploader: User, data: Partial<Resource>): Promise<Resource> {
    const isPrivileged =
      uploader.role === UserRole.ADMIN || uploader.role === UserRole.LECTURER;
    const resource = this.repo.create({
      ...data,
      uploaderId: uploader.id,
      status: isPrivileged ? ResourceStatus.APPROVED : ResourceStatus.PENDING,
      isOfficial: isPrivileged,
    });
    return this.repo.save(resource);
  }
  ```

  No module changes needed — `UsersModule` is already imported.

  Verify: `cd backend && npm run lint` — passes with no new errors.
  Also run `npm run build` — TypeScript compiles cleanly.

---

- [ ] 2. **Admin Dashboard pubspec — add `firebase_storage` and `file_picker`**

  Add two dependencies to `admin_dashboard/pubspec.yaml` under `dependencies:`:
  ```yaml
  firebase_storage: ^13.4.1
  file_picker: ^8.0.0
  ```

  File to modify:
  - `admin_dashboard/pubspec.yaml`

  Verify: `cd admin_dashboard && flutter pub get` — resolves without version conflicts.
  (If pub solver rejects `^13.4.1` alongside `firebase_core: ^3.13.0`, bump to the
  highest compatible patch listed in the FlutterFire BoM for that `firebase_core`
  version. Do NOT downgrade `firebase_core`.)

---

- [ ] 3. **Admin Dashboard — add `adminResourcesCoursesProvider` and upload dialog**

  All new code lives inside `moderation_screen.dart` to keep the pattern consistent
  with the rest of the codebase (providers and widgets co-located in their screen file).

  **3a. Imports** — add at the top:
  ```dart
  import 'package:firebase_storage/firebase_storage.dart';
  import 'package:file_picker/file_picker.dart';
  ```

  **3b. New provider — courses for the resource upload dialog**

  The upload dialog needs a department ID to fetch courses.
  Reuse `adminDepartmentsSharedProvider` (already in `admin_departments_provider.dart`)
  for the department dropdown, and add a new family provider for courses:
  ```dart
  final adminResourceCoursesProvider =
      FutureProvider.family<List<Map<String, dynamic>>, String>(
          (ref, departmentId) async {
    try {
      final response =
          await adminApi.get('/courses', params: {'departmentId': departmentId});
      final data = (response.data['data'] ?? response.data) as List;
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  });
  ```

  This avoids importing `AdminCourseModel` from the courses screen — a raw map is
  sufficient for id/title lookup inside the dialog.

  **3c. Upload button in `ModerationScreen`**

  Modify `ModerationScreen.build()` — replace the current `_PageHeader` row with a `Row`
  that puts the header on the left and an "Upload Resource" button on the right:
  ```dart
  Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Expanded(
        child: _PageHeader(
          title: 'Resource Moderation',
          subtitle: 'Review and approve student submissions',
        ),
      ),
      ElevatedButton.icon(
        icon: const Icon(Icons.upload_file_outlined, size: 18),
        label: const Text('Upload Resource'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => ProviderScope(
            parent: ProviderContainer(
              parent: ref.container,
            ),
            child: const _UploadResourceDialog(),
          ),
        ).then((_) => ref.invalidate(pendingResourcesProvider)),
      ),
    ],
  ),
  ```

  Actually — `ProviderScope` wrapping is unnecessary because `ModerationScreen` is
  already a `ConsumerWidget`. Pass `ref` into the dialog instead. The correct pattern
  (matching the project) is a `ConsumerStatefulWidget` dialog:

  ```dart
  onPressed: () async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: const _UploadResourceDialog(),
      ),
    );
    ref.invalidate(pendingResourcesProvider);
  },
  ```

  **3d. `_UploadResourceDialog` widget**

  A `ConsumerStatefulWidget` dialog with the following fields:

  | Field | Widget | Validation |
  |---|---|---|
  | Title | `TextFormField` | Required |
  | Description | `TextFormField` (3 lines) | Optional |
  | Resource Type | `DropdownButtonFormField<String>` | Required |
  | Department | `DropdownButtonFormField<String>` | Required (drives course list) |
  | Course | `DropdownButtonFormField<String>` | Required |
  | Academic Year | `TextFormField` (hint: 2024/2025) | Optional |
  | File | File picker button + filename chip | Required |

  State fields:
  ```dart
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  String? _selectedType;     // 'lecture_note', 'past_question', etc.
  String? _selectedDeptId;
  String? _selectedCourseId;
  PlatformFile? _pickedFile;
  double? _uploadProgress;   // null = not uploading
  bool _submitting = false;
  ```

  Resource type options (match `ResourceType` enum):
  ```
  lecture_note → Lecture Note
  past_question → Past Question
  slide → Slide
  practical_manual → Practical Manual
  assignment → Assignment
  other → Other
  ```

  **Pick file logic:**
  ```dart
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'pptx', 'ppt', 'docx', 'doc', 'xlsx', 'png', 'jpg'],
      withData: true,  // required for web — loads bytes into memory
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }
  ```

  **Upload and submit logic:**
  ```dart
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFile == null) {
      // show snackbar "Please select a file"
      return;
    }
    setState(() { _submitting = true; _uploadProgress = 0; });
    try {
      // 1. Upload file to Firebase Storage
      final ext = _pickedFile!.extension ?? 'bin';
      final filename = '${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.name}';
      final ref = FirebaseStorage.instance
          .ref('resources/$_selectedCourseId/$filename');

      final uploadTask = ref.putData(
        _pickedFile!.bytes!,
        SettableMetadata(contentType: _mimeType(ext)),
      );
      uploadTask.snapshotEvents.listen((snap) {
        final progress =
            snap.bytesTransferred / snap.totalBytes;
        if (mounted) setState(() => _uploadProgress = progress);
      });
      await uploadTask;
      final fileUrl = await ref.getDownloadURL();

      // 2. POST to /resources
      await adminApi.post('/resources', data: {
        'title': _titleCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty)
          'description': _descCtrl.text.trim(),
        'type': _selectedType,
        'courseId': _selectedCourseId,
        'fileUrl': fileUrl,
        'fileType': ext,
        'fileSize': _pickedFile!.size,
        if (_yearCtrl.text.trim().isNotEmpty)
          'academicYear': _yearCtrl.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Resource uploaded and published!'),
          backgroundColor: AdminColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AdminColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() { _submitting = false; _uploadProgress = null; });
    }
  }
  ```

  **`_mimeType` helper:**
  ```dart
  String _mimeType(String ext) {
    const map = {
      'pdf': 'application/pdf',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'ppt': 'application/vnd.ms-powerpoint',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'doc': 'application/msword',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'png': 'image/png',
      'jpg': 'image/jpeg',
    };
    return map[ext.toLowerCase()] ?? 'application/octet-stream';
  }
  ```

  **Progress indicator in the dialog actions:**
  While `_uploadProgress != null`, replace the Submit button with a
  `LinearProgressIndicator` + percentage label. The Cancel button is disabled while
  uploading.

  **Dialog layout (width: 520, scrollable):**
  ```
  AlertDialog
  ├── title: "Upload Resource"
  └── content: SizedBox(width: 520)
      └── Form(key: _formKey)
          └── SingleChildScrollView
              ├── TextFormField (Title) *required
              ├── SizedBox(height: 12)
              ├── TextFormField (Description, maxLines: 3) optional
              ├── SizedBox(height: 12)
              ├── DropdownButtonFormField (Resource Type) *required
              ├── SizedBox(height: 12)
              ├── DropdownButtonFormField (Department) *required
              ├── SizedBox(height: 12)
              ├── [if _selectedDeptId != null]
              │   DropdownButtonFormField (Course) *required — watches adminResourceCoursesProvider(_selectedDeptId!)
              ├── SizedBox(height: 12)
              ├── TextFormField (Academic Year, hint: 2024/2025) optional
              ├── SizedBox(height: 16)
              └── Row
                  ├── OutlinedButton.icon (Pick File)
                  └── if _pickedFile != null: Chip(label: Text(filename), onDeleted: clear)
  └── actions:
      ├── TextButton (Cancel) — disabled while _submitting
      └── if _uploadProgress == null:
              ElevatedButton (Upload) — calls _submit()
          else:
              Column [
                LinearProgressIndicator(value: _uploadProgress)
                Text('${(_uploadProgress! * 100).toStringAsFixed(0)}%')
              ]
  ```

  File to modify:
  - `admin_dashboard/lib/presentation/screens/resources/moderation_screen.dart`

  Verify: `cd admin_dashboard && flutter analyze` — no errors or warnings.
  Also do a manual web build: `flutter build web --dart-define=API_BASE_URL=https://campuscore-bfrq.onrender.com/api/v1`
  and confirm the build succeeds.

---

- [ ] 4. **(Optional) Add Pending/All tabs to `ModerationScreen`**

  Convert `ModerationScreen` to a `ConsumerStatefulWidget` and wrap the content in
  a `DefaultTabController(length: 2)` with tabs "Pending" and "All Resources".

  - "Pending" tab: existing `pendingResourcesProvider` list.
  - "All Resources" tab: add a new `allResourcesProvider` using
    `GET /resources?courseId=<all>` — however the current API requires a `courseId`.
    Since there is no "all resources" endpoint today, the "All Resources" tab should
    call `GET /resources/moderation/pending` with a status filter once the backend
    exposes it, OR be scoped to "all pending + approved resources for the department".
    **Decision:** skip this tab in the initial implementation — it requires a backend
    endpoint change. Leave a `// TODO: all-resources tab` comment in the file.
    The "Pending" count stat card and list are sufficient for Phase 1.

  This item is optional — implement only if items 1–3 are complete.

---

## Key decisions recorded

1. **No `UsersService` injection** — the controller already has the full `User` from
   `@CurrentUser()`. Pass the `User` to `submit()` instead of passing just `uploaderId`.
   This is cleaner and avoids adding a new constructor dependency to `ResourcesService`.

2. **firebase_storage version** — the task brief says `^11.0.0` but that is incompatible
   with `firebase_core: ^3.x` (which the project already uses). The correct version is
   `^13.4.1` (FlutterFire BoM-aligned with `firebase_core: ^3.13.0`).

3. **file_picker `withData: true`** — required for Flutter Web because web cannot
   provide a file path; bytes must be loaded into memory for `putData()`.

4. **Upload path** — `resources/{courseId}/{timestamp}_{filename}`. This mirrors the
   path format used in the mobile app and keeps files organised by course.

5. **No "All Resources" tab in this iteration** — the existing `GET /resources` endpoint
   requires a `courseId` filter. Adding a tab without a matching backend endpoint would
   need a new admin-only "list all" endpoint. Defer to a separate task.
