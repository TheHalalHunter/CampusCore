import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final gridColumns = Responsive.getGridColumns(context).toInt();
    final spacing = Responsive.getSpacing(context);
    final padding = Responsive.getPaddingEdgeInsets(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Text(
              'Welcome back!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: isMobile ? 24 : 32,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Here\'s your learning progress at a glance.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey500,
                  ),
            ),
            SizedBox(height: spacing + 16),

            // Stats grid
            GridView.count(
              crossAxisCount: gridColumns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StatCard(
                  title: 'Courses',
                  value: '8',
                  icon: Icons.school_outlined,
                  color: AppColors.primary,
                ),
                _StatCard(
                  title: 'Resources',
                  value: '24',
                  icon: Icons.library_books_outlined,
                  color: AppColors.secondary,
                ),
                _StatCard(
                  title: 'Study Streak',
                  value: '12',
                  icon: Icons.local_fire_department_outlined,
                  color: AppColors.warning,
                ),
                _StatCard(
                  title: 'GPA',
                  value: '3.8',
                  icon: Icons.trending_up_outlined,
                  color: AppColors.success,
                ),
              ],
            ),
            SizedBox(height: spacing + 16),

            // Recent activity section
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: isMobile ? 16 : 18,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: isMobile ? 3 : 5,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: isMobile ? 18 : 24,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.file_download_outlined,
                          color: AppColors.primary,
                          size: isMobile ? 16 : 20,
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Downloaded lecture notes',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Fisheries & Aquaculture • ${index + 1} days ago',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.grey500,
                                    fontSize: isMobile ? 11 : 12,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: isMobile ? 24 : 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: color,
                        fontSize: isMobile ? 20 : 28,
                      ),
                ),
                const SizedBox(height: 4),
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
