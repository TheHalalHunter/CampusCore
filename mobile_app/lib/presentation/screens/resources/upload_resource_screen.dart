import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../providers/upload_provider.dart';
import '../../providers/courses_provider.dart';
import '../../providers/department_provider.dart';

class UploadResourceScreen extends ConsumerStatefulWidget {
  const UploadResourceScreen({super.key});

  @override
  ConsumerState<UploadResourceScreen> createState() => _UploadResourceScreenState();
}

class _UploadResourceScreenState extends ConsumerState<UploadResourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedType = 'lecture_note';
  String? _selectedCourseId;
  String? _selectedCourseName;
  String? _academicYear;
  bool _isUploading = false;

  final _resourceTypes = [
    {'value': 'lecture_note',     'label': 'Lecture Note',     'icon': Icons.description_outlined},
    {'value': 'past_question',    'label': 'Past Question',    'icon': Icons.quiz_outlined},
    {'value': 'slide',            'label': 'Slide',            'icon': Icons.slideshow_outlined},
    {'value': 'practical_manual', 'label': 'Practical Manual', 'icon': Icons.science_outlined},
    {'value': 'assignment',       'label': 'Assignment',       'icon': Icons.assignment_outlined},
  ];

  final _years = ['2024/2025', '2023/2024', '2022/2023', '2021/2022', '2020/2021', '2019/2020'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    final uploadState = ref.watch(uploadProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Resource')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your upload will be reviewed by a moderator before becoming visible to others.',
                        style: TextStyle(color: AppColors.info, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Resource type selector
              const Text('Resource Type',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _resourceTypes.map((type) {
                  final selected = _selectedType == type['value'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type['value'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type['icon'] as IconData,
                            size: 16,
                            color: selected ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            type['label'] as String,
                            style: TextStyle(
                              color: selected ? Colors.white : AppColors.textSecondary,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Title
              const Text('Title',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. AQU 201 Lecture Notes Week 3',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              const Text('Description (optional)',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Brief description of what this resource covers...',
                ),
              ),
              const SizedBox(height: 16),

              // Course selector
              const Text('Course',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              coursesAsync.when(
                data: (courses) => DropdownButtonFormField<String>(
                  value: _selectedCourseId,
                  hint: const Text('Select course'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  items: courses.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.courseCode} — ${c.title}',
                        overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCourseId = val;
                      _selectedCourseName = courses
                          .firstWhere((c) => c.id == val)
                          .title;
                    });
                  },
                  validator: (v) => v == null ? 'Please select a course' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Could not load courses'),
              ),
              const SizedBox(height: 16),

              // Academic year
              const Text('Academic Year (optional)',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _academicYear,
                hint: const Text('Select year'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                items: _years.map((y) => DropdownMenuItem(
                  value: y,
                  child: Text(y),
                )).toList(),
                onChanged: (val) => setState(() => _academicYear = val),
              ),
              const SizedBox(height: 24),

              // File picker
              const Text('File',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              _FilePicker(
                onFilePicked: (path, name) {
                  ref.read(uploadProvider.notifier).setFile(path, name);
                },
              ),
              const SizedBox(height: 32),

              // Upload status
              if (uploadState.isUploading) ...[
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: uploadState.progress,
                      backgroundColor: AppColors.grey200,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Uploading... ${(uploadState.progress * 100).toInt()}%',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (uploadState.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    uploadState.error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Submit button
              ElevatedButton.icon(
                onPressed: uploadState.isUploading ? null : _submit,
                icon: const Icon(Icons.upload_file, size: 18),
                label: Text(uploadState.isUploading ? 'Uploading...' : 'Submit for Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uploadState = ref.read(uploadProvider);
    if (uploadState.filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file to upload.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final success = await ref.read(uploadProvider.notifier).upload(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      type: _selectedType,
      courseId: _selectedCourseId!,
      academicYear: _academicYear,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resource submitted for review. Thank you!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }
}

// ─── File Picker Widget ───────────────────────────────────────────────────────

class _FilePicker extends ConsumerWidget {
  final void Function(String path, String name) onFilePicked;
  const _FilePicker({required this.onFilePicked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(uploadProvider);

    return GestureDetector(
      onTap: () => ref.read(uploadProvider.notifier).pickFile(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: uploadState.filePath != null
              ? AppColors.success.withOpacity(0.05)
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: uploadState.filePath != null
                ? AppColors.success
                : AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: uploadState.filePath != null
            ? Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      uploadState.fileName ?? 'File selected',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(uploadProvider.notifier).clearFile(),
                    child: const Text('Change'),
                  ),
                ],
              )
            : const Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.textHint),
                  SizedBox(height: 8),
                  Text(
                    'Tap to select a file',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'PDF, DOCX, PPTX — max 20MB',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}
