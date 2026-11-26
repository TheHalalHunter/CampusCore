import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/router/app_router.dart';
import '../../providers/courses_provider.dart';
import '../../providers/progress_provider.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Tracker')),
      body: coursesAsync.when(
        data: (courses) {
          if (courses.isEmpty) {
            return const Center(
              child: Text('No courses found.',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(coursesProvider),
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Study streak card (private)
                _StreakCard(),
                const SizedBox(height: 16),
                // Semester overview
                _SemesterOverview(courses: courses),
                const SizedBox(height: 28),
                const Text('Course Progress',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                ...courses.map((course) => _CourseProgressCard(
                      courseId: course.id,
                      title: course.title,
                      code: course.courseCode,
                      level: course.academicLevel,
                    )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load courses.')),
      ),
    );
  }
}

// ─── Semester Overview ────────────────────────────────────────────────────────

class _SemesterOverview extends ConsumerWidget {
  final List courses;
  const _SemesterOverview({required this.courses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semesterAsync = ref.watch(semesterProgressProvider);

    return semesterAsync.when(
      data: (data) {
        int totalCompleted = 0;
        int totalTopics = 0;
        data.forEach((_, v) {
          final m = v as Map<String, dynamic>;
          totalCompleted += (m['completed'] as num?)?.toInt() ?? 0;
          totalTopics += (m['total'] as num?)?.toInt() ?? 0;
        });
        final pct = totalTopics > 0 ? totalCompleted / totalTopics : 0.0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CircularPercentIndicator(
                radius: 50,
                lineWidth: 8,
                percent: pct.clamp(0.0, 1.0),
                center: Text(
                  '${(pct * 100).toInt()}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
                progressColor: Colors.white,
                backgroundColor: Colors.white24,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Semester Progress',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      '$totalCompleted of $totalTopics topics completed',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${courses.length} courses',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.grey200,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      error: (_, __) => const SizedBox(),
    );
  }
}

// ─── Streak Card ─────────────────────────────────────────────────────────────

class _StreakCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    return streakAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (streak) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: streak.studiedToday
                ? [const Color(0xFF16A34A), const Color(0xFF22C55E)]
                : [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Text(
            streak.studiedToday ? '🔥' : '📚',
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${streak.currentStreak} day streak',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  streak.studiedToday
                      ? 'You studied today! Keep it up.'
                      : 'Study today to keep your streak!',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13),
                ),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Best: ${streak.longestStreak}d',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            Text('Total: ${streak.totalStudyDays}d',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}

// ─── Course Progress Card ─────────────────────────────────────────────────────

class _CourseProgressCard extends ConsumerWidget {
  final String courseId;
  final String title;
  final String code;
  final String level;

  const _CourseProgressCard({
    required this.courseId,
    required this.title,
    required this.code,
    required this.level,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(courseProgressProvider(courseId));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('${AppRoutes.courses}/$courseId'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(code,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(level,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              progressAsync.when(
                data: (progress) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: progress.percentage / 100,
                      backgroundColor: AppColors.grey200,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${progress.completedCount}/${progress.totalCount} topics',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                        Text(
                          '${progress.percentage}%',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                loading: () => const LinearProgressIndicator(
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation(AppColors.grey200),
                  minHeight: 8,
                ),
                error: (_, __) => const Text('Could not load progress',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
