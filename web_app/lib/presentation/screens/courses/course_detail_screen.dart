import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/auth_provider.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final courseDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, courseId) async {
  final api  = ref.read(apiClientProvider);
  final resp = await api.get('${ApiConstants.courses}/$courseId');
  final data = resp.data['data'] ?? resp.data;
  return data as Map<String, dynamic>;
});

final courseResourcesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, courseId) async {
  final api  = ref.read(apiClientProvider);
  final resp = await api.get(ApiConstants.resources, params: {
    'courseId': courseId,
    'status':   'approved',
    'limit':    50,
  });
  final data = resp.data['data'];
  if (data is List) return data.cast<Map<String, dynamic>>();
  if (data is Map) {
    final items = data['items'] ?? data['data'];
    if (items is List) return items.cast<Map<String, dynamic>>();
  }
  return [];
});

// ── Screen ────────────────────────────────────────────────────────────────────

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync    = ref.watch(courseDetailProvider(widget.courseId));
    final resourcesAsync = ref.watch(courseResourcesProvider(widget.courseId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/courses'),
        ),
        title: courseAsync.when(
          data:    (c) => Text(c['courseCode']?.toString() ?? 'Course'),
          loading: () => const Text('Loading...'),
          error:   (_, __) => const Text('Course'),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Resources'),
          ],
        ),
      ),
      body: courseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              const Text('Could not load course details.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(courseDetailProvider(widget.courseId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (course) => TabBarView(
          controller: _tabs,
          children: [
            _OverviewTab(course: course),
            _ResourcesTab(
              courseId: widget.courseId,
              resourcesAsync: resourcesAsync,
              onRefresh: () => ref.invalidate(courseResourcesProvider(widget.courseId)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> course;
  const _OverviewTab({required this.course});

  @override
  Widget build(BuildContext context) {
    final title    = course['title']?.toString()        ?? '';
    final code     = course['courseCode']?.toString()   ?? '';
    final level    = course['academicLevel']?.toString() ?? '';
    final semester = course['semester']?.toString()     ?? '';
    final units    = course['creditUnits']?.toString()  ?? '';
    final desc     = course['description']?.toString()  ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Info chips
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (level.isNotEmpty)
                _InfoChip(icon: Icons.school_outlined,   label: level),
              if (semester.isNotEmpty)
                _InfoChip(icon: Icons.calendar_today,    label: 'Semester $semester'),
              if (units.isNotEmpty)
                _InfoChip(icon: Icons.star_outline,      label: '$units Credit Units'),
            ],
          ),

          if (desc.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'About this Course',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.6,
                fontFamily: 'Nunito',
              ),
            ),
          ],

          const SizedBox(height: 32),
          // Quick action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text('Ask AI Tutor'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Resources Tab ─────────────────────────────────────────────────────────────

class _ResourcesTab extends StatelessWidget {
  final String courseId;
  final AsyncValue<List<Map<String, dynamic>>> resourcesAsync;
  final VoidCallback onRefresh;

  const _ResourcesTab({
    required this.courseId,
    required this.resourcesAsync,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return resourcesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            const Text('Could not load resources.'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRefresh, child: const Text('Retry')),
          ],
        ),
      ),
      data: (resources) {
        if (resources.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_outlined, size: 64, color: AppColors.border),
                SizedBox(height: 16),
                Text(
                  'No resources uploaded for this course yet.',
                  style: TextStyle(color: AppColors.textHint, fontFamily: 'Nunito'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: resources.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final r = resources[i];
            return _ResourceTile(resource: r);
          },
        );
      },
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final Map<String, dynamic> resource;
  const _ResourceTile({required this.resource});

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'past_question': return Icons.quiz_outlined;
      case 'lecture_note':  return Icons.description_outlined;
      case 'slide':         return Icons.slideshow_outlined;
      default:              return Icons.insert_drive_file_outlined;
    }
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'past_question': return 'Past Question';
      case 'lecture_note':  return 'Lecture Note';
      case 'slide':         return 'Slide';
      default:              return 'Resource';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title   = resource['title']?.toString()   ?? 'Resource';
    final type    = resource['type']?.toString();
    final fileUrl = resource['fileUrl']?.toString() ?? resource['file_url']?.toString() ?? '';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(_typeIcon(type), color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Nunito',
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          _typeLabel(type),
          style: const TextStyle(
            color: AppColors.textHint,
            fontSize: 12,
            fontFamily: 'Nunito',
          ),
        ),
        trailing: fileUrl.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.download_outlined, color: AppColors.primary),
                tooltip: 'Download',
                onPressed: () async {
                  final uri = Uri.parse(fileUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              )
            : null,
      ),
    );
  }
}
