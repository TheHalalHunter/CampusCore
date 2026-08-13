import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Tracker'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Academic Progress',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: isMobile ? 24 : 32,
              ),
            ),
            const SizedBox(height: 24),
            // GPA Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current GPA',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.grey600,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '3.8',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppColors.success,
                            fontSize: isMobile ? 32 : 48,
                          ),
                        ),
                        SizedBox(width: isMobile ? 8 : 12),
                        Text(
                          'First Class',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Courses Breakdown
            Text(
              'Courses Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: isMobile ? 16 : 18,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: isMobile ? 4 : 8,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final grades = ['A', 'A', 'B', 'B', 'C', 'B', 'A', 'B'];
                  final gradeColors = {
                    'A': AppColors.success,
                    'B': AppColors.info,
                    'C': AppColors.warning,
                  };
                  return Padding(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Course ${index + 1}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isMobile ? 12 : 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'FAS${100 + index}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.grey500,
                                  fontSize: isMobile ? 11 : 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? 40 : 50,
                          height: isMobile ? 40 : 50,
                          child: Container(
                            decoration: BoxDecoration(
                              color: gradeColors[grades[index]]?.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                grades[index],
                                style: TextStyle(
                                  color: gradeColors[grades[index]],
                                  fontWeight: FontWeight.w700,
                                  fontSize: isMobile ? 16 : 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
