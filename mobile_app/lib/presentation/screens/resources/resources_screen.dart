import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/router/app_router.dart';
import '../../../data/models/resource_model.dart';
import '../../providers/resources_provider.dart';
import '../../providers/library_provider.dart';
import '../widgets/common/error_view.dart';
import '../widgets/common/offline_banner.dart';

class ResourcesScreen extends ConsumerStatefulWidget {
  final String courseId;
  const ResourcesScreen({super.key, required this.courseId});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> {
  String _typeFilter = 'all';

  static const _filters = [
    ('all', 'All'),
    ('lecture_note', 'Notes'),
    ('past_question', 'Past Qs'),
    ('slide', 'Slides'),
    ('practical_manual', 'Practicals'),
    ('assignment', 'Assignments'),
  ];

  @override
  Widget build(BuildContext context) {
    final resourcesAsync =
        ref.watch(resourcesByCourseProvider(widget.courseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resources'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Upload',
            onPressed: () => context.push(AppRoutes.uploadResource),
          ),
        ],
      ),
      body: Column(
        children: [
          // Type filter chips
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final selected = _typeFilter == f.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _typeFilter = f.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border),
                        ),
                        child: Text(f.$2,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            )),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // Resources list
          Expanded(
            child: OfflineBanner(
              cacheKey: 'resources_course_${widget.courseId}',
              child: resourcesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorView(
                  message: 'Could not load resources. Check your connection.',
                  onRetry: () => ref
                      .invalidate(resourcesByCourseProvider(widget.courseId)),
                ),
                data: (resources) {
                  final filtered = _typeFilter == 'all'
                      ? resources
                      : resources.where((r) => r.type == _typeFilter).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.folder_open_outlined,
                            size: 56, color: AppColors.grey400),
                        const SizedBox(height: 16),
                        const Text('No resources yet',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('Be the first to upload for this course.',
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.push(AppRoutes.uploadResource),
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Upload Resource'),
                        ),
                      ]),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref
                        .invalidate(resourcesByCourseProvider(widget.courseId)),
                    color: AppColors.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) =>
                          _ResourceCard(resource: filtered[i]),
                    ),
                  );
                },
              ), // closes OfflineBanner child: resourcesAsync.when(
            ), // closes OfflineBanner(
          ), // closes Expanded(
        ],
      ),
    );
  }
}

// ─── Resource card ────────────────────────────────────────────────────────────

class _ResourceCard extends ConsumerWidget {
  final ResourceModel resource;
  const _ResourceCard({required this.resource});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked =
        ref.watch(bookmarkProvider.select((s) => s.contains(resource.id)));

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('${AppRoutes.resources}/${resource.id}/view'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _typeColor(resource.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon(resource.type),
                  color: _typeColor(resource.type), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(resource.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Text(resource.typeLabel,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    if (resource.academicYear != null) ...[
                      const Text(' • ',
                          style: TextStyle(
                              color: AppColors.textHint, fontSize: 12)),
                      Text(resource.academicYear!,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                    if (resource.fileSizeLabel.isNotEmpty) ...[
                      const Text(' • ',
                          style: TextStyle(
                              color: AppColors.textHint, fontSize: 12)),
                      Text(resource.fileSizeLabel,
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 12)),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.download_outlined,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Text('${resource.downloadCount}',
                        style: const TextStyle(
                            color: AppColors.textHint, fontSize: 12)),
                    if (resource.isOfficial) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified,
                          size: 13, color: AppColors.success),
                      const SizedBox(width: 3),
                      const Text('Official',
                          style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ]),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                color: isBookmarked ? AppColors.primary : AppColors.textHint,
                size: 20,
              ),
              onPressed: () =>
                  ref.read(bookmarkProvider.notifier).toggle(resource.id),
            ),
          ]),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'lecture_note':
        return Icons.description_outlined;
      case 'past_question':
        return Icons.quiz_outlined;
      case 'slide':
        return Icons.slideshow_outlined;
      case 'practical_manual':
        return Icons.science_outlined;
      case 'assignment':
        return Icons.assignment_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'lecture_note':
        return AppColors.info;
      case 'past_question':
        return AppColors.accent;
      case 'slide':
        return AppColors.success;
      case 'practical_manual':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }
}
