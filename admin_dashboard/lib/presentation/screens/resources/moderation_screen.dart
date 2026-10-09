import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/admin_theme.dart';
import '../../../core/providers/admin_departments_provider.dart';
import '../../../core/utils/api_client.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class PendingResource {
  final String id;
  final String title;
  final String? description;
  final String fileUrl;
  final String? fileType;
  final String type;
  final String uploaderId;
  final String? academicYear;

  const PendingResource({
    required this.id,
    required this.title,
    this.description,
    required this.fileUrl,
    this.fileType,
    required this.type,
    required this.uploaderId,
    this.academicYear,
  });

  factory PendingResource.fromJson(Map<String, dynamic> json) =>
      PendingResource(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        fileUrl: json['fileUrl'] as String? ?? json['file_url'] as String? ?? '',
        fileType: json['fileType'] as String? ?? json['file_type'] as String?,
        type: json['type'] as String? ?? 'other',
        uploaderId:
            json['uploaderId'] as String? ?? json['uploader_id'] as String? ?? '',
        academicYear:
            json['academicYear'] as String? ?? json['academic_year'] as String?,
      );

  String get typeLabel {
    switch (type) {
      case 'lecture_note':
        return 'Lecture Note';
      case 'past_question':
        return 'Past Question';
      case 'slide':
        return 'Slide';
      case 'practical_manual':
        return 'Practical Manual';
      case 'assignment':
        return 'Assignment';
      default:
        return 'Resource';
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final pendingResourcesProvider =
    FutureProvider<List<PendingResource>>((ref) async {
  try {
    final response = await adminApi.get('/resources/moderation/pending');
    final data = (response.data['data'] ?? response.data) as List;
    return data
        .map((r) => PendingResource.fromJson(r as Map<String, dynamic>))
        .toList();
  } catch (e) {
    // ignore: avoid_print
    print('pendingResourcesProvider error: $e');
    return [];
  }
});

/// FutureProvider.family for courses by departmentId (used inside the upload dialog).
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

// ─── Screen ───────────────────────────────────────────────────────────────────

class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingResourcesProvider);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title/subtitle on the left, Upload button on the right
          Row(
            children: [
              const Expanded(
                child: _PageHeader(
                  title: 'Resource Moderation',
                  subtitle: 'Review and approve student submissions',
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => UncontrolledProviderScope(
                      container: ProviderScope.containerOf(context),
                      child: const _UploadResourceDialog(),
                    ),
                  );
                  ref.invalidate(pendingResourcesProvider);
                },
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload Resource'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats row
          pendingAsync.when(
            data: (resources) => Row(children: [
              _MiniStat(
                  label: 'Pending',
                  value: '${resources.length}',
                  color: AdminColors.warning),
            ]),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          const Text('Pending Submissions',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),

          Expanded(
            child: pendingAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                  child: Text('Could not load pending resources.')),
              data: (resources) {
                if (resources.isEmpty) {
                  return const Center(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 56, color: AdminColors.success),
                          SizedBox(height: 16),
                          Text('All caught up!',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          SizedBox(height: 8),
                          Text('No resources pending review.',
                              style:
                                  TextStyle(color: AdminColors.grey600)),
                        ]),
                  );
                }
                return ListView.builder(
                  itemCount: resources.length,
                  itemBuilder: (_, i) => _PendingCard(
                    resource: resources[i],
                    onReview: (approved, note) async {
                      try {
                        await adminApi.patch(
                          '/resources/${resources[i].id}/review',
                          data: {
                            'status': approved ? 'approved' : 'rejected',
                            if (note != null && note.isNotEmpty)
                              'reviewNote': note,
                          },
                        );
                        ref.invalidate(pendingResourcesProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(approved
                                ? '✅ Resource approved!'
                                : '❌ Resource rejected.'),
                            backgroundColor: approved
                                ? AdminColors.success
                                : AdminColors.error,
                          ));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: AdminColors.error,
                          ));
                        }
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upload Resource Dialog ───────────────────────────────────────────────────

class _UploadResourceDialog extends ConsumerStatefulWidget {
  const _UploadResourceDialog();

  @override
  ConsumerState<_UploadResourceDialog> createState() =>
      _UploadResourceDialogState();
}

class _UploadResourceDialogState
    extends ConsumerState<_UploadResourceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  String? _selectedType;
  String? _selectedDeptId;
  String? _selectedCourseId;
  PlatformFile? _pickedFile;
  double? _uploadProgress;
  bool _submitting = false;

  static const _typeOptions = <String, String>{
    'lecture_note': 'Lecture Note',
    'past_question': 'Past Question',
    'slide': 'Slide',
    'practical_manual': 'Practical Manual',
    'assignment': 'Assignment',
    'other': 'Other',
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'pptx', 'ppt', 'docx', 'doc', 'xlsx', 'png', 'jpg'
      ],
      withData: true, // mandatory for Flutter Web
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'doc':
        return 'application/msword';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please pick a file before uploading.'),
        backgroundColor: AdminColors.warning,
      ));
      return;
    }

    setState(() {
      _submitting = true;
      _uploadProgress = 0;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = _pickedFile!.name;
      final ext = filename.contains('.')
          ? filename.split('.').last.toLowerCase()
          : 'bin';
      final storagePath =
          'resources/$_selectedCourseId/${timestamp}_$filename';

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref(storagePath);
      final uploadTask = storageRef.putData(
        _pickedFile!.bytes!,
        SettableMetadata(contentType: _mimeType(ext)),
      );

      // Track progress
      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0 && mounted) {
          setState(() => _uploadProgress =
              snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });

      await uploadTask;
      final downloadUrl = await storageRef.getDownloadURL();

      // POST to backend /resources
      await adminApi.post('/resources', data: {
        'title': _titleCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty)
          'description': _descCtrl.text.trim(),
        'type': _selectedType,
        'courseId': _selectedCourseId,
        'fileUrl': downloadUrl,
        'fileType': ext,
        'fileSize': _pickedFile!.size,
        if (_yearCtrl.text.trim().isNotEmpty)
          'academicYear': _yearCtrl.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Resource uploaded successfully!'),
          backgroundColor: AdminColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadProgress = null;
          _submitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AdminColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deptsAsync = ref.watch(adminDepartmentsSharedProvider);

    return AlertDialog(
      title: const Text('Upload Resource'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // Description (optional)
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                // Resource Type
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration:
                      const InputDecoration(labelText: 'Resource Type'),
                  items: _typeOptions.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // Department
                deptsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) =>
                      const Text('Could not load departments.'),
                  data: (depts) => DropdownButtonFormField<String>(
                    initialValue: _selectedDeptId,
                    decoration:
                        const InputDecoration(labelText: 'Department'),
                    items: depts
                        .map((d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(d.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedDeptId = v;
                      _selectedCourseId = null; // reset course when dept changes
                    }),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Course (only shown when a department is selected)
                if (_selectedDeptId != null) ...[
                  ref.watch(adminResourceCoursesProvider(_selectedDeptId!)).when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) =>
                        const Text('Could not load courses.'),
                    data: (courses) => DropdownButtonFormField<String>(
                      initialValue: _selectedCourseId,
                      decoration:
                          const InputDecoration(labelText: 'Course'),
                      items: courses
                          .map((c) => DropdownMenuItem(
                                value: c['id'] as String,
                                child: Text(
                                    '${c['courseCode'] ?? c['course_code'] ?? ''} – ${c['title'] ?? ''}'),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedCourseId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Academic Year (optional)
                TextFormField(
                  controller: _yearCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Academic Year (optional)',
                    hintText: '2024/2025',
                  ),
                ),
                const SizedBox(height: 16),

                // File picker row
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _pickFile,
                      icon: const Icon(Icons.attach_file, size: 16),
                      label: const Text('Pick File'),
                    ),
                    const SizedBox(width: 12),
                    if (_pickedFile != null)
                      Expanded(
                        child: Chip(
                          label: Text(
                            _pickedFile!.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onDeleted: _submitting
                              ? null
                              : () => setState(() => _pickedFile = null),
                        ),
                      )
                    else
                      const Text('No file selected',
                          style: TextStyle(
                              color: AdminColors.grey600, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (_uploadProgress != null) ...[
          // Show progress bar + percentage while uploading
          SizedBox(
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AdminColors.grey300,
                  valueColor: const AlwaysStoppedAnimation(AdminColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${((_uploadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 12, color: AdminColors.grey600),
                ),
              ],
            ),
          ),
        ] else ...[
          TextButton(
            onPressed: _submitting
                ? null
                : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Upload'),
          ),
        ],
      ],
    );
  }
}

// ─── Pending card ─────────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  final PendingResource resource;
  final void Function(bool approved, String? note) onReview;

  const _PendingCard({required this.resource, required this.onReview});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.insert_drive_file_outlined,
                  color: AdminColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(resource.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 3),
                      Text(
                        '${resource.typeLabel}'
                        '${resource.academicYear != null ? ' • ${resource.academicYear}' : ''}'
                        '${resource.fileType != null ? ' • .${resource.fileType}' : ''}',
                        style: const TextStyle(
                            color: AdminColors.grey600, fontSize: 12),
                      ),
                    ]),
              ),
            ]),
            if (resource.description != null &&
                resource.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(resource.description!,
                  style: const TextStyle(
                      color: AdminColors.grey600, fontSize: 13)),
            ],
            const SizedBox(height: 14),
            Row(children: [
              // Preview button
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(resource.fileUrl);
                  if (uri != null) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('File URL'),
                        content: SelectableText(resource.fileUrl),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close')),
                        ],
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View URL'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.success,
                    foregroundColor: Colors.white),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Approve'),
                onPressed: () => onReview(true, null),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    foregroundColor: AdminColors.error,
                    side: const BorderSide(color: AdminColors.error)),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Reject'),
                onPressed: () => _showRejectDialog(context),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Resource'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Provide a reason (optional):'),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'e.g. Poor quality, duplicate content...'),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.error,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              onReview(false, ctrl.text.trim());
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    color: AdminColors.grey600, fontSize: 12)),
          ]),
        ),
      );
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _PageHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700)),
          Text(subtitle,
              style: const TextStyle(color: AdminColors.grey600)),
        ],
      );
}
