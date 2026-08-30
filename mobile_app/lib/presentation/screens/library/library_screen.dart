import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/router/app_router.dart';
import '../../../data/models/resource_model.dart';
import '../../providers/library_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Library'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Saved'),
              Tab(text: 'Bookmarks'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.upload_file_outlined),
              tooltip: 'Upload Resource',
              onPressed: () => context.push(AppRoutes.uploadResource),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            _SavedTab(),
            _BookmarksTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.uploadResource),
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

// ─── Saved Tab ────────────────────────────────────────────────────────────────

class _SavedTab extends ConsumerWidget {
  const _SavedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resources = ref.watch(personalLibraryProvider);

    if (resources.isEmpty) {
      return _EmptyLibrary(
        icon: Icons.bookmark_outline,
        title: 'No saved resources yet',
        subtitle:
            'Browse courses and save resources to access them quickly here.',
        actionLabel: 'Browse Courses',
        onAction: () => context.go(AppRoutes.courses),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: resources.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _LibraryResourceCard(resource: resources[i]),
    );
  }
}

// ─── Bookmarks Tab ────────────────────────────────────────────────────────────

class _BookmarksTab extends ConsumerWidget {
  const _BookmarksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarkProvider);

    if (bookmarks.isEmpty) {
      return _EmptyLibrary(
        icon: Icons.turned_in_not,
        title: 'No bookmarks yet',
        subtitle: 'Tap the bookmark icon on any resource to save it here.',
        actionLabel: 'Browse Courses',
        onAction: () => context.go(AppRoutes.courses),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookmarks.length,
      itemBuilder: (_, i) {
        final resourceId = bookmarks.elementAt(i);
        return _BookmarkCard(resourceId: resourceId);
      },
    );
  }
}

// ─── Resource Card ────────────────────────────────────────────────────────────

class _LibraryResourceCard extends ConsumerWidget {
  final ResourceModel resource;
  const _LibraryResourceCard({required this.resource});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(
      bookmarkProvider.select((s) => s.contains(resource.id)),
    );

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _typeColor(resource.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_typeIcon(resource.type),
              color: _typeColor(resource.type), size: 22),
        ),
        title: Text(
          resource.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              resource.typeLabel,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            if (resource.academicYear != null) ...[
              const Text(' • ',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12)),
              Text(
                resource.academicYear!,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                color:
                    isBookmarked ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () =>
                  ref.read(bookmarkProvider.notifier).toggle(resource.id),
            ),
            IconButton(
              icon: const Icon(Icons.download_outlined,
                  color: AppColors.primary, size: 20),
              onPressed: () => _download(context, resource),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _download(BuildContext context, ResourceModel resource) async {
    final uri = Uri.tryParse(resource.fileUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open file.')),
      );
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
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}

class _BookmarkCard extends ConsumerWidget {
  final String resourceId;
  const _BookmarkCard({required this.resourceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.bookmark, color: AppColors.primary),
        title: Text(
          'Resource $resourceId',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.bookmark, color: AppColors.primary, size: 20),
          onPressed: () =>
              ref.read(bookmarkProvider.notifier).toggle(resourceId),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyLibrary extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyLibrary({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
