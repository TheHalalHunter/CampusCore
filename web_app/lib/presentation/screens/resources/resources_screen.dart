import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/auth_provider.dart';

import 'package:file_picker/file_picker.dart';

// ── Providers ─────────────────────────────────────────────────────────────────
final resourcesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api  = ref.read(apiClientProvider);
  final resp = await api.get(ApiConstants.resources, params: {'limit': 50});
  final data = resp.data['data'];
  if (data is List) return data.cast<Map<String, dynamic>>();
  if (data is Map) {
    final items = data['items'] ?? data['data'];
    if (items is List) return items.cast<Map<String, dynamic>>();
  }
  return [];
});

final coursesForUploadProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api  = ref.read(apiClientProvider);
  final user = ref.read(currentUserProvider);
  final resp = await api.get(
    ApiConstants.courses,
    params: user?.departmentId != null ? {'departmentId': user!.departmentId} : null,
  );
  final data = resp.data['data'];
  if (data is List) return data.cast<Map<String, dynamic>>();
  return [];
});

// ── Screen ────────────────────────────────────────────────────────────────────
class ResourcesScreen extends ConsumerWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(resourcesProvider);
    final isMobile       = Responsive.isMobile(context);
    final padding        = Responsive.getPaddingEdgeInsets(context);
    final spacing        = Responsive.getSpacing(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Resources'),
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => _UploadDialog(onUploaded: () => ref.invalidate(resourcesProvider)),
        ),
        icon: const Icon(Icons.upload_file_outlined),
        label: const Text('Upload', style: TextStyle(fontFamily: 'Nunito')),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Learning Resources',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: isMobile ? 22 : 28,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Lecture notes, past questions, slides and more.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
            ),
            SizedBox(height: spacing + 4),
            resourcesAsync.when(
              loading: () => Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 6,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, __) => const _SkeletonRow(),
                ),
              ),
              error: (_, __) => Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    const Text('Could not load resources.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(resourcesProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (resources) {
                if (resources.isEmpty) {
                  return Column(
                    children: [
                      const SizedBox(height: 48),
                      const Icon(Icons.library_books_outlined, size: 64, color: AppColors.border),
                      const SizedBox(height: 16),
                      Text('No resources uploaded yet.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textHint)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => _UploadDialog(onUploaded: () => ref.invalidate(resourcesProvider)),
                        ),
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Upload First Resource'),
                      ),
                    ],
                  );
                }
                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: resources.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) => _ResourceRow(
                      resource: resources[index],
                      isMobile: isMobile,
                      spacing: spacing,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ── Upload Dialog ─────────────────────────────────────────────────────────────
class _UploadDialog extends ConsumerStatefulWidget {
  final VoidCallback onUploaded;
  const _UploadDialog({required this.onUploaded});

  @override
  ConsumerState<_UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends ConsumerState<_UploadDialog> {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _yearCtrl   = TextEditingController();

  String? _selectedCourseId;
  String  _selectedType = 'lecture_note';
  String? _fileName;
  Uint8List? _fileBytes;
  String? _fileMime;

  double  _uploadProgress = 0;
  bool    _uploading = false;
  String? _error;

  final _resourceTypes = const {
    'lecture_note':     'Lecture Note',
    'past_question':    'Past Question',
    'slide':            'Slide',
    'practical_manual': 'Practical Manual',
    'assignment':       'Assignment',
    'other':            'Other',
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
      allowedExtensions: ['pdf', 'pptx', 'ppt', 'docx', 'doc', 'xlsx', 'xls', 'txt', 'png', 'jpg', 'jpeg'],
      withData: true, // loads bytes directly — required for web
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _fileName  = file.name;
      _fileBytes = file.bytes!;
      _fileMime  = _mimeFromExtension(file.extension ?? '');
    });
  }

  /// Derives a MIME type from a file extension for Firebase Storage metadata.
  String _mimeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':  return 'application/pdf';
      case 'pptx': return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'ppt':  return 'application/vnd.ms-powerpoint';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'doc':  return 'application/msword';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'xls':  return 'application/vnd.ms-excel';
      case 'png':  return 'image/png';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      default:     return 'application/octet-stream';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fileBytes == null) {
      setState(() => _error = 'Please select a file to upload.');
      return;
    }
    if (_selectedCourseId == null) {
      setState(() => _error = 'Please select a course.');
      return;
    }

    setState(() { _uploading = true; _error = null; _uploadProgress = 0; });

    try {
      // 1. Upload file to Firebase Storage
      final user   = ref.read(currentUserProvider);
      final ext    = _fileName!.split('.').last;
      final path   = 'resources/${user?.id ?? "anon"}/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref_   = FirebaseStorage.instance.ref(path);
      final task   = ref_.putData(
        _fileBytes!,
        SettableMetadata(contentType: _fileMime),
      );

      task.snapshotEvents.listen((snap) {
        final progress = snap.bytesTransferred / snap.totalBytes;
        if (mounted) setState(() => _uploadProgress = progress);
      });

      await task;
      final fileUrl = await ref_.getDownloadURL();

      // 2. POST resource metadata to backend
      final api  = ref.read(apiClientProvider);
      final resp = await api.post(ApiConstants.uploadResource, data: {
        'title':        _titleCtrl.text.trim(),
        'description':  _descCtrl.text.trim(),
        'fileUrl':      fileUrl,
        'fileType':     ext,
        'fileSize':     _fileBytes!.lengthInBytes,
        'type':         _selectedType,
        'courseId':     _selectedCourseId,
        if (_yearCtrl.text.trim().isNotEmpty) 'academicYear': _yearCtrl.text.trim(),
      });

      final body = resp.data as Map<String, dynamic>;
      if (body['success'] != true) {
        setState(() { _uploading = false; _error = body['message']?.toString() ?? 'Upload failed.'; });
        return;
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onUploaded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resource submitted for review! 🎉', style: TextStyle(fontFamily: 'Nunito')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // Surface the full error so we can diagnose Firebase Storage vs backend issues
      String msg = e.toString();
      if (msg.contains('firebase_storage') || msg.contains('storage/')) {
        msg = 'Firebase Storage error: $msg\n\nMake sure Firebase Storage rules allow writes.';
      }
      setState(() { _uploading = false; _error = msg; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesForUploadProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.upload_file_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Upload Resource',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Nunito', color: AppColors.textPrimary)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _uploading ? null : () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Uploads go to moderator review before going live.',
                  style: TextStyle(color: AppColors.warning, fontSize: 11, fontFamily: 'Nunito'),
                ),
              ),
              const SizedBox(height: 16),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // File picker
                        GestureDetector(
                          onTap: _uploading ? null : _pickFile,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: _fileBytes != null
                                  ? AppColors.success.withValues(alpha: 0.06)
                                  : AppColors.surfaceAlt,
                              border: Border.all(
                                color: _fileBytes != null ? AppColors.success : AppColors.border,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _fileBytes != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                                  color: _fileBytes != null ? AppColors.success : AppColors.primary,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _fileBytes != null ? _fileName! : 'Click to select file',
                                  style: TextStyle(
                                    color: _fileBytes != null ? AppColors.success : AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_fileBytes == null)
                                  const Text('PDF, PPTX, DOCX, images',
                                      style: TextStyle(color: AppColors.textHint, fontSize: 11, fontFamily: 'Nunito')),
                                if (_fileBytes != null)
                                  Text(
                                    '${(_fileBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB — tap to change',
                                    style: const TextStyle(color: AppColors.textHint, fontSize: 11, fontFamily: 'Nunito'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Title
                        TextFormField(
                          controller: _titleCtrl,
                          enabled: !_uploading,
                          decoration: const InputDecoration(labelText: 'Title *', prefixIcon: Icon(Icons.title_outlined)),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),

                        // Course
                        coursesAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const Text('Could not load courses', style: TextStyle(color: AppColors.error)),
                          data: (courses) => DropdownButtonFormField<String>(
                            value: _selectedCourseId,
                            decoration: const InputDecoration(labelText: 'Course *', prefixIcon: Icon(Icons.school_outlined)),
                            items: courses.map((c) {
                              return DropdownMenuItem(
                                value: c['id']?.toString(),
                                child: Text(
                                  '${c['code'] ?? ''} — ${c['name'] ?? ''}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontFamily: 'Nunito'),
                                ),
                              );
                            }).toList(),
                            onChanged: _uploading ? null : (v) => setState(() => _selectedCourseId = v),
                            validator: (v) => v == null ? 'Select a course' : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Type
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: const InputDecoration(labelText: 'Resource Type *', prefixIcon: Icon(Icons.category_outlined)),
                          items: _resourceTypes.entries.map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value, style: const TextStyle(fontFamily: 'Nunito')),
                          )).toList(),
                          onChanged: _uploading ? null : (v) => setState(() => _selectedType = v!),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 2,
                          enabled: !_uploading,
                          decoration: const InputDecoration(
                            labelText: 'Description (optional)',
                            prefixIcon: Icon(Icons.description_outlined),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Academic year
                        TextFormField(
                          controller: _yearCtrl,
                          enabled: !_uploading,
                          decoration: const InputDecoration(
                            labelText: 'Academic Year (optional)',
                            hintText: 'e.g. 2023/2024',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Upload progress
              if (_uploading) ...[
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  _uploadProgress < 1.0
                      ? 'Uploading file... ${(_uploadProgress * 100).toStringAsFixed(0)}%'
                      : 'Saving to server...',
                  style: const TextStyle(color: AppColors.textHint, fontSize: 12, fontFamily: 'Nunito'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12, fontFamily: 'Nunito'))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _uploading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _uploading ? null : _submit,
                      child: _uploading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Upload'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Resource Row ──────────────────────────────────────────────────────────────
class _ResourceRow extends StatelessWidget {
  final Map<String, dynamic> resource;
  final bool isMobile;
  final double spacing;

  const _ResourceRow({required this.resource, required this.isMobile, required this.spacing});

  IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':            return Icons.picture_as_pdf_outlined;
      case 'pptx': case 'ppt': return Icons.slideshow_outlined;
      case 'docx': case 'doc': return Icons.description_outlined;
      case 'mp4': case 'video': return Icons.play_circle_outline;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  Color _colorFor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':   return AppColors.error;
      case 'pptx': case 'ppt': return AppColors.warning;
      case 'video': return AppColors.primaryLight;
      default:      return AppColors.primary;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'lecture_note':     return 'Lecture Note';
      case 'past_question':    return 'Past Question';
      case 'slide':            return 'Slide';
      case 'practical_manual': return 'Practical';
      case 'assignment':       return 'Assignment';
      default:                 return type.toUpperCase();
    }
  }

  Future<void> _open(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final title    = resource['title']?.toString()    ?? 'Resource';
    final fileType = resource['fileType']?.toString() ?? resource['type']?.toString() ?? 'file';
    final resType  = resource['type']?.toString()     ?? '';
    final fileUrl  = resource['fileUrl']?.toString();
    final status   = resource['status']?.toString()   ?? 'approved';
    final course   = resource['course']?['code']?.toString() ?? '';

    final iconData  = _iconFor(fileType);
    final iconColor = _colorFor(fileType);

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Row(
        children: [
          Container(
            width: isMobile ? 40 : 48,
            height: isMobile ? 40 : 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, color: iconColor, size: isMobile ? 20 : 24),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 12 : 14,
                          color: AppColors.textPrimary,
                        ),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    if (course.isNotEmpty)
                      _Tag(label: course, color: AppColors.primary),
                    if (resType.isNotEmpty)
                      _Tag(label: _typeLabel(resType), color: AppColors.cyan),
                    if (status == 'pending')
                      _Tag(label: 'Under Review', color: AppColors.warning),
                  ],
                ),
              ],
            ),
          ),
          if (fileUrl != null && fileUrl.isNotEmpty && status == 'approved')
            IconButton(
              icon: const Icon(Icons.download_outlined),
              color: AppColors.primary,
              iconSize: isMobile ? 18 : 22,
              tooltip: 'Download',
              onPressed: () => _open(fileUrl),
            )
          else if (status == 'pending')
            const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.hourglass_empty_outlined, color: AppColors.warning, size: 18),
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'Nunito')),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: double.infinity, height: 14, color: AppColors.surfaceAlt),
                const SizedBox(height: 6),
                Container(width: 120, height: 11, color: AppColors.surfaceAlt),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
