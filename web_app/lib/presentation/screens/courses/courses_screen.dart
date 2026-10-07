import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/auth_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────
final coursesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final user = ref.read(currentUserProvider);
  final resp = await api.get(
    ApiConstants.courses,
    params: user?.departmentId != null
        ? {'departmentId': user!.departmentId}
        : null,
  );
  final data = resp.data['data'];
  if (data is List) return data.cast<Map<String, dynamic>>();
  return [];
});

// ── Screen ────────────────────────────────────────────────────────────────────
class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    final isMobile     = Responsive.isMobile(context);
    final padding      = Responsive.getPaddingEdgeInsets(context);
    final gridCols     = Responsive.getGridColumns(context).toInt();
    final spacing      = Responsive.getSpacing(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Courses'),
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enrolled Courses',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: isMobile ? 22 : 28,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 20),
            coursesAsync.when(
              loading: () => GridView.count(
                crossAxisCount: gridCols,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(6, (_) => const _SkeletonCourseCard()),
              ),
              error: (e, _) => _ErrorWidget(
                message: 'Could not load courses.',
                onRetry: () => ref.invalidate(coursesProvider),
              ),
              data: (courses) {
                if (courses.isEmpty) {
                  return _EmptyWidget(
                    icon: Icons.school_outlined,
                    message: 'No courses found for your department yet.',
                  );
                }
                return GridView.count(
                  crossAxisCount: gridCols,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: courses
                      .map((c) => _CourseCard(course: c))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final name     = course['title']?.toString()          ?? course['name']?.toString()  ?? 'Course';
    final code     = course['courseCode']?.toString()      ?? course['code']?.toString()  ?? '';
    final level    = course['academicLevel']?.toString()   ?? course['level']?.toString() ?? '';
    final semester = course['semester']?.toString()        ?? '';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final id = course['id']?.toString() ?? '';
          if (id.isNotEmpty) context.go('/courses/$id');
        },
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: isMobile ? 70 : 100,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.school_outlined, color: Colors.white, size: 36),
              ),
            ),
            SizedBox(height: isMobile ? 10 : 14),
            Text(
              name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: isMobile ? 12 : 14,
                    color: AppColors.textPrimary,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            Text(
              code,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 11 : 12,
                  ),
            ),
            const Spacer(),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (level.isNotEmpty)
                  _Tag(label: level, color: AppColors.primary),
                if (semester.isNotEmpty)
                  _Tag(label: 'Sem $semester', color: AppColors.cyan),
              ],
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'Nunito',
        ),
      ),
    );
  }
}

class _SkeletonCourseCard extends StatelessWidget {
  const _SkeletonCourseCard();
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity, height: 100,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 14, color: AppColors.surfaceAlt),
            const SizedBox(height: 6),
            Container(width: 60, height: 12, color: AppColors.surfaceAlt),
          ],
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyWidget({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 48),
          Icon(icon, size: 64, color: AppColors.border),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: AppColors.textHint, fontFamily: 'Nunito'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
