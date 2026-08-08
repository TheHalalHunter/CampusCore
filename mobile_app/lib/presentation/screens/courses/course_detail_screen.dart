import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/router/app_router.dart';
import '../../../data/models/resource_model.dart';
import '../../providers/courses_provider.dart';
import '../../providers/resources_provider.dart';

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
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(
      coursesProvider.select((value) => value.whenData(
        (courses) => courses.where((c) => c.id == widget.courseId).firstOrNull,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: courseAsync.when(
          data: (course) => Text(course?.courseCode ?? 'Course'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Course'),
        ),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Notes'),
            Tab(text: 'Past Q.'),
            Tab(text: 'Slides'),
            Tab(text: 'AI Tutor'),
          ],
        ),
      ),
      body: courseAsync.when(
        data: (course) {
          if (course == null) {
            return const Center(child: Text('Course not found.'));
          }
          return TabBarView(
            controller: _tabs,
            children: [
              // Overview
              _OverviewTab(
                title: course.title,
                code: course.courseCode,
                level: course.academicLevel,
                semester: course.semester,
                units: course.creditUnits,
                description: course.description,
              ),
              // Notes
              _ResourcesTab(courseId: widget.courseId, type: 'lecture_note'),
              // Past Questions
              _ResourcesTab(courseId: widget.courseId, type: 'past_question'),
              // Slides
              _ResourcesTab(courseId: widget.courseId, type: 'slide'),
              // AI Tutor
              _AiTutorTab(courseTitle: course.title),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load course.')),
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final String title;
  final String code;
  final String level;
  final int semester;
  final int units;
  final String? description;

  const _OverviewTab({
    required this.title,
    required this.code,
    required this.level,
    required this.semester,
    required this.units,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(label: level),
                    const SizedBox(width: 8),
                    _InfoChip(label: 'Semester $semester'),
                    const SizedBox(width: 8),
                    _InfoChip(label: '$units units'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Description
          if (description != null && description!.isNotEmpty) ...[
            const Text(
              'About this Course',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Quick links
          const Text(
            'Study Materials',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _StudyMaterialLink(
            icon: Icons.description_outlined,
            color: AppColors.info,
            label: 'Lecture Notes',
            subtitle: 'Download course notes',
          ),
          _StudyMaterialLink(
            icon: Icons.quiz_outlined,
            color: AppColors.accent,
            label: 'Past Questions',
            subtitle: 'Practice with past exam questions',
          ),
          _StudyMaterialLink(
            icon: Icons.slideshow_outlined,
            color: AppColors.success,
            label: 'Slides',
            subtitle: 'Presentation slides',
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StudyMaterialLink extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;

  const _StudyMaterialLink({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─── Resources Tab ────────────────────────────────────────────────────────────

class _ResourcesTab extends ConsumerWidget {
  final String courseId;
  final String type;

  const _ResourcesTab({required this.courseId, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(
      resourcesByTypeProvider((courseId: courseId, type: type)),
    );

    return resourcesAsync.when(
      data: (resources) {
        if (resources.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 56,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No materials uploaded yet.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Be the first to contribute! Upload a resource for this course.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textHint, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Upload Resource'),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: resources.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _ResourceCard(resource: resources[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Text(
          'Could not load resources.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final ResourceModel resource;
  const _ResourceCard({required this.resource});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.picture_as_pdf, color: AppColors.error, size: 22),
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
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            if (resource.academicYear != null) ...[
              const Text(' • ', style: TextStyle(color: AppColors.textHint)),
              Text(
                resource.academicYear!,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
            if (resource.fileSizeLabel.isNotEmpty) ...[
              const Text(' • ', style: TextStyle(color: AppColors.textHint)),
              Text(
                resource.fileSizeLabel,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (resource.isOfficial)
              const Tooltip(
                message: 'Official resource',
                child: Icon(Icons.verified, color: AppColors.success, size: 18),
              ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.download_outlined, color: AppColors.primary),
              onPressed: () => _download(context, resource),
              tooltip: 'Download',
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
}

// ─── AI Tutor Tab ─────────────────────────────────────────────────────────────

class _AiTutorTab extends StatelessWidget {
  final String courseTitle;
  const _AiTutorTab({required this.courseTitle});

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
                color: AppColors.accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, size: 40, color: AppColors.accent),
            ),
            const SizedBox(height: 20),
            Text(
              'AI Tutor for $courseTitle',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get explanations, generate practice quizzes, and create flashcards specific to this course.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Open AI Assistant'),
              onPressed: () => context.push(AppRoutes.aiAssistant),
            ),
          ],
        ),
      ),
    );
  }
}
