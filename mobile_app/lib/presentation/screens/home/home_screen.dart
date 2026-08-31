import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/router/app_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/courses_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/department_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final unreadAsync = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.surface,
            title: const Row(
              children: [
                Icon(Icons.school, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'CampusCore',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            actions: [
              // Search
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.textPrimary),
                tooltip: 'Search',
                onPressed: () => context.push(AppRoutes.search),
              ),
              // Notification bell with unread badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                    onPressed: () => context.push(AppRoutes.notifications),
                  ),
                  unreadAsync.when(
                    data: (count) => count > 0
                        ? Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting with real user name
                  userAsync.when(
                    data: (user) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good day, ${user?.firstName ?? 'Scholar'} 👋',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user != null
                              ? '${user.displayLevel} • Fisheries & Aquaculture'
                              : 'Ready to learn something new today?',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    loading: () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerBox(width: 200, height: 24),
                        const SizedBox(height: 6),
                        _ShimmerBox(width: 160, height: 16),
                      ],
                    ),
                    error: (_, __) => const Text(
                      'Good day, Scholar 👋',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick actions
                  const _SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _QuickAction(
                        icon: Icons.auto_awesome,
                        label: 'AI Tutor',
                        color: AppColors.accent,
                        onTap: () => context.push(AppRoutes.aiAssistant),
                      ),
                      const SizedBox(width: 16),
                      _QuickAction(
                        icon: Icons.calculate,
                        label: 'GPA Calc',
                        color: AppColors.info,
                        onTap: () => context.push(AppRoutes.gpaCalculator),
                      ),
                      const SizedBox(width: 16),
                      _QuickAction(
                        icon: Icons.trending_up,
                        label: 'Progress',
                        color: AppColors.success,
                        onTap: () => context.push(AppRoutes.progress),
                      ),
                      const SizedBox(width: 16),
                      _QuickAction(
                        icon: Icons.upload_file,
                        label: 'Upload',
                        color: AppColors.primaryLight,
                        onTap: () => context.push(AppRoutes.uploadResource),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Continue studying
                  _SectionHeader(
                    title: 'Courses',
                    actionLabel: 'See all',
                    onAction: () => context.go(AppRoutes.courses),
                  ),
                  const SizedBox(height: 12),
                  _RealCoursesList(ref: ref),
                  const SizedBox(height: 28),

                  // Department info
                  _DepartmentCard(ref: ref),
                  const SizedBox(height: 28),

                  // Recent discussions
                  _SectionHeader(
                    title: 'Community',
                    actionLabel: 'See all',
                    onAction: () => context.go(AppRoutes.community),
                  ),
                  const SizedBox(height: 12),
                  _DiscussionPreviewList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Real Courses List ────────────────────────────────────────────────────────

class _RealCoursesList extends StatelessWidget {
  final WidgetRef ref;
  const _RealCoursesList({required this.ref});

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    return coursesAsync.when(
      data: (courses) {
        if (courses.isEmpty) {
          return const _EmptyState(
            icon: Icons.menu_book_outlined,
            message: 'No courses available yet.',
          );
        }
        // Show first 3 courses
        final preview = courses.take(3).toList();
        return Column(
          children: preview.map((course) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book, color: AppColors.primary, size: 22),
              ),
              title: Text(
                course.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                '${course.courseCode} • ${course.academicLevel} • ${course.creditUnits} units',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
              onTap: () => context.push('${AppRoutes.courses}/${course.id}'),
            ),
          )).toList(),
        );
      },
      loading: () => Column(
        children: List.generate(3, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ShimmerBox(width: double.infinity, height: 72, radius: 16),
        )),
      ),
      error: (_, __) => const _EmptyState(
        icon: Icons.wifi_off,
        message: 'Could not load courses. Make sure the backend is running.',
      ),
    );
  }
}

// ─── Department Card ─────────────────────────────────────────────────────────

class _DepartmentCard extends StatelessWidget {
  final WidgetRef ref;
  const _DepartmentCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    final deptAsync = ref.watch(primaryDepartmentProvider);
    final coursesAsync = ref.watch(coursesProvider);

    return deptAsync.when(
      data: (dept) {
        if (dept == null) return const SizedBox();
        final courseCount = coursesAsync.value?.length ?? 0;
        return Container(
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
          child: Row(
            children: [
              const Icon(Icons.school, color: Colors.white, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dept.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dept.universityName,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$courseCount courses available',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _ShimmerBox(width: double.infinity, height: 100, radius: 16),
      error: (_, __) => const SizedBox(),
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }
}

class _DiscussionPreviewList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      {'q': 'What is the optimal protein level for catfish juveniles?', 'answers': '4'},
      {'q': 'Can someone explain the nitrogen cycle in aquaculture?', 'answers': '7'},
    ];
    return Column(
      children: items.map((item) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppColors.accent,
            child: Icon(Icons.question_answer, color: Colors.white, size: 18),
          ),
          title: Text(
            item['q']!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            '${item['answers']} answers',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          onTap: () => context.go(AppRoutes.community),
        ),
      )).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _ShimmerBox({required this.width, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
