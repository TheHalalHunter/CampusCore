import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getPaddingEdgeInsets(context);
    final gridColumns = Responsive.getGridColumns(context).toInt();
    final spacing = Responsive.getSpacing(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
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
                    fontSize: isMobile ? 24 : 32,
                  ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: gridColumns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(
                9,
                (index) => _CourseCard(
                  title: 'Course ${index + 1}',
                  code: 'FAS${100 + index}',
                  progress: (index + 1) * 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final String title;
  final String code;
  final int progress;

  const _CourseCard({
    required this.title,
    required this.code,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: isMobile ? 80 : 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.school_outlined,
                color: AppColors.primary,
                size: isMobile ? 32 : 48,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 12 : 14,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isMobile ? 2 : 4),
            Text(
              code,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey500,
                    fontSize: isMobile ? 11 : 12,
                  ),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey600,
                            fontSize: isMobile ? 10 : 12,
                          ),
                    ),
                    Text(
                      '$progress%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            fontSize: isMobile ? 10 : 12,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 6 : 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: isMobile ? 3 : 4,
                    backgroundColor: AppColors.grey200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
