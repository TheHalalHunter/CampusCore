import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

// ── Provider ──────────────────────────────────────────────────────────────────
final homeDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final user = ref.read(currentUserProvider);
  try {
    final results = await Future.wait([
      api.get(
        ApiConstants.courses,
        params: user?.departmentId != null
            ? {'departmentId': user!.departmentId}
            : null,
      ),
      api.get(ApiConstants.resources),
      api.get(ApiConstants.gpa),
    ]);

    final courses   = (results[0].data['data'] as List?)?.length ?? 0;
    final resources = (results[1].data['data'] as List?)?.length ?? 0;
    final gpaData   = results[2].data['data'];
    final gpa       = (gpaData?['cgpa'] ?? gpaData?['gpa'] ?? 0.0).toStringAsFixed(2);

    return {'courses': courses, 'resources': resources, 'gpa': gpa};
  } catch (_) {
    return {'courses': 0, 'resources': 0, 'gpa': '0.00'};
  }
});

// ── Screen ────────────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user       = ref.watch(currentUserProvider);
    final dashAsync  = ref.watch(homeDashboardProvider);
    final isMobile   = Responsive.isMobile(context);
    final gridCols   = Responsive.getGridColumns(context).toInt();
    final spacing    = Responsive.getSpacing(context);
    final padding    = Responsive.getPaddingEdgeInsets(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 20 : 28),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${user?.firstName ?? 'Student'}! 👋',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 20 : 26,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Here\'s your learning overview.',
                    style: TextStyle(
                      color: AppColors.textOnDarkSub,
                      fontSize: isMobile ? 13 : 15,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing + 8),

            // Stats grid
            dashAsync.when(
              loading: () => GridView.count(
                crossAxisCount: gridCols,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(4, (_) => const _SkeletonCard()),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) => GridView.count(
                crossAxisCount: gridCols,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StatCard(
                    title: 'Courses',
                    value: data['courses'].toString(),
                    icon: Icons.school_outlined,
                    color: AppColors.primary,
                  ),
                  _StatCard(
                    title: 'Resources',
                    value: data['resources'].toString(),
                    icon: Icons.library_books_outlined,
                    color: AppColors.cyan,
                  ),
                  _StatCard(
                    title: 'GPA',
                    value: data['gpa'].toString(),
                    icon: Icons.trending_up_outlined,
                    color: AppColors.success,
                  ),
                  _StatCard(
                    title: 'Role',
                    value: _roleLabel(user?.role ?? 'student'),
                    icon: Icons.verified_user_outlined,
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),

            SizedBox(height: spacing + 8),

            // Quick actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: isMobile ? 16 : 18,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickAction(
                  icon: Icons.upload_file_outlined,
                  label: 'Upload Resource',
                  color: AppColors.primary,
                  onTap: () => context.go('/resources'),
                ),
                _QuickAction(
                  icon: Icons.forum_outlined,
                  label: 'Ask Question',
                  color: AppColors.cyan,
                  onTap: () => context.go('/community'),
                ),
                _QuickAction(
                  icon: Icons.auto_awesome_outlined,
                  label: 'AI Assistant',
                  color: AppColors.primaryLight,
                  onTap: () => context.go('/ai'),
                ),
                _QuickAction(
                  icon: Icons.insert_chart_outlined,
                  label: 'View Progress',
                  color: AppColors.success,
                  onTap: () => context.go('/progress'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':      return 'Admin';
      case 'moderator':  return 'Mod';
      case 'lecturer':   return 'Lecturer';
      default:           return 'Student';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: isMobile ? 20 : 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: isMobile ? 22 : 30,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey500,
                        fontSize: isMobile ? 11 : 12,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 60, height: 28, color: AppColors.surfaceAlt),
                const SizedBox(height: 6),
                Container(width: 80, height: 12, color: AppColors.surfaceAlt),
              ],
            ),
          ],
        ),
      ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
