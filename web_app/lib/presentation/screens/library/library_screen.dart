import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/responsive.dart';

// ── Provider ──────────────────────────────────────────────────────────────────
final libraryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api  = ref.read(apiClientProvider);
  final resp = await api.get(ApiConstants.library);
  final data = resp.data['data'];
  if (data is List) return data.cast<Map<String, dynamic>>();
  return [];
});

// ── Screen ────────────────────────────────────────────────────────────────────
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(libraryProvider);
    final isMobile     = Responsive.isMobile(context);
    final padding      = Responsive.getPaddingEdgeInsets(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Library'),
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: libraryAsync.when(
        loading: () => _buildSkeleton(padding),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bookmark_border_outlined,
                  size: 64, color: AppColors.border),
              const SizedBox(height: 16),
              const Text('Could not load your library.',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontFamily: 'Nunito')),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => ref.invalidate(libraryProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: padding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_border_outlined,
                        size: 72,
                        color: AppColors.primary.withValues(alpha: 0.3)),
                    const SizedBox(height: 20),
                    Text(
                      'Your library is empty.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Save resources while browsing to find them here.',
                      style: TextStyle(
                          color: AppColors.textHint,
                          fontFamily: 'Nunito',
                          fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved Resources',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: isMobile ? 18 : 22,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${items.length} item${items.length == 1 ? '' : 's'} saved',
                  style: const TextStyle(
                      color: AppColors.textHint,
                      fontFamily: 'Nunito',
                      fontSize: 13),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final item     = items[index];
                      final resource = item['resource'] as Map<String, dynamic>?;
                      return _LibraryItemRow(
                        item: item,
                        resource: resource,
                        isMobile: isMobile,
                        onRemoved: () => ref.invalidate(libraryProvider),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton(EdgeInsets padding) {
    return SingleChildScrollView(
      padding: padding,
      child: Card(
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppColors.border),
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                _SkeletonBox(width: 48, height: 48, radius: 10),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(width: double.infinity, height: 14),
                      SizedBox(height: 6),
                      _SkeletonBox(width: 120, height: 11),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                _SkeletonBox(width: 32, height: 32, radius: 16),
                SizedBox(width: 4),
                _SkeletonBox(width: 32, height: 32, radius: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Library Item Row ──────────────────────────────────────────────────────────
class _LibraryItemRow extends ConsumerWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic>? resource;
  final bool isMobile;
  final VoidCallback onRemoved;

  const _LibraryItemRow({
    required this.item,
    required this.resource,
    required this.isMobile,
    required this.onRemoved,
  });

  String _typeLabel(String type) {
    switch (type) {
      case 'lecture_note':     return 'Lecture Note';
      case 'past_question':    return 'Past Question';
      case 'slide':            return 'Slide';
      case 'practical_manual': return 'Practical';
      case 'assignment':       return 'Assignment';
      default:                 return type.isNotEmpty ? type : 'Resource';
    }
  }

  IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':         return Icons.picture_as_pdf_outlined;
      case 'pptx':
      case 'ppt':         return Icons.slideshow_outlined;
      case 'docx':
      case 'doc':         return Icons.description_outlined;
      default:            return Icons.insert_drive_file_outlined;
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title    = resource?['title']?.toString()    ?? item['title']?.toString()    ?? 'Resource';
    final fileType = resource?['fileType']?.toString() ?? '';
    final resType  = resource?['type']?.toString()     ?? '';
    final fileUrl  = resource?['fileUrl']?.toString();
    final course   = resource?['course']?['code']?.toString() ?? '';
    final resourceId = item['resourceId']?.toString() ?? resource?['id']?.toString() ?? '';

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Row(
        children: [
          Container(
            width: isMobile ? 40 : 48,
            height: isMobile ? 40 : 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFor(fileType),
                color: AppColors.primary, size: isMobile ? 20 : 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 13 : 14,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    if (course.isNotEmpty) _Tag(label: course, color: AppColors.primary),
                    if (resType.isNotEmpty)
                      _Tag(label: _typeLabel(resType), color: AppColors.cyan),
                  ],
                ),
              ],
            ),
          ),
          // Download
          if (fileUrl != null && fileUrl.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download_outlined),
              color: AppColors.primary,
              iconSize: 20,
              tooltip: 'Download',
              onPressed: () => _openUrl(fileUrl),
            ),
          // Remove
          IconButton(
            icon: const Icon(Icons.bookmark_remove_outlined),
            color: AppColors.error,
            iconSize: 20,
            tooltip: 'Remove from library',
            onPressed: () => _confirmRemove(context, ref, resourceId),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, String resourceId) async {
    if (resourceId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from library?'),
        content: const Text(
            'This resource will be removed from your saved library.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.delete(ApiConstants.libraryRemove(resourceId));
      onRemoved();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from library',
                style: TextStyle(fontFamily: 'Nunito')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove: $e',
                style: const TextStyle(fontFamily: 'Nunito')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'Nunito')),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _SkeletonBox(
      {required this.width, required this.height, this.radius = 4});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(radius)),
    );
  }
}
