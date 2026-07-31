import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/router/app_router.dart';

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Courses')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          return _CourseCard(
            code: 'AQU ${201 + i * 2}',
            title: _courseTitles[i],
            level: '200L',
            progress: (i + 1) * 0.15,
            onTap: () => context.push('${AppRoutes.courses}/course_$i'),
          );
        },
      ),
    );
  }

  static const _courseTitles = [
    'Fish Nutrition',
    'Aquatic Ecology',
    'Fish Parasitology',
    'Pond Management',
    'Fisheries Law',
    'Aquaculture Technology',
  ];
}

class _CourseCard extends StatelessWidget {
  final String code;
  final String title;
  final String level;
  final double progress;
  final VoidCallback onTap;

  const _CourseCard({
    required this.code,
    required this.title,
    required this.level,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(code, style: const TextStyle(color: AppColors.grey600, fontSize: 12)),
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.grey200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text('${(progress * 100).toInt()}% complete',
                        style: const TextStyle(fontSize: 11, color: AppColors.grey600)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.grey600),
            ],
          ),
        ),
      ),
    );
  }
}
