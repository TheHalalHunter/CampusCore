import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../app/theme/app_theme.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Placeholder data — will be driven by ProgressProvider once backend is wired
    final courses = [
      {'title': 'AQU 201 — Fish Nutrition', 'progress': 0.42, 'completed': 5, 'total': 12},
      {'title': 'AQU 203 — Aquatic Ecology', 'progress': 0.75, 'completed': 9, 'total': 12},
      {'title': 'AQU 205 — Fish Parasitology', 'progress': 0.20, 'completed': 2, 'total': 10},
      {'title': 'AQU 207 — Pond Management', 'progress': 0.60, 'completed': 6, 'total': 10},
    ];

    final overallProgress = courses.fold<double>(0, (sum, c) => sum + (c['progress'] as double)) / courses.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Tracker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Semester overview card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircularPercentIndicator(
                      radius: 48,
                      lineWidth: 8,
                      percent: overallProgress,
                      center: Text(
                        '${(overallProgress * 100).toInt()}%',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      progressColor: AppColors.primary,
                      backgroundColor: AppColors.grey200,
                    ),
                    const SizedBox(width: 20),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Semester Progress',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('200 Level — First Semester',
                            style: TextStyle(color: AppColors.grey600, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Course Progress',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),

            ...courses.map((course) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(course['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(
                          '${course['completed']}/${course['total']} topics completed',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: course['progress'] as double,
                          backgroundColor: AppColors.grey200,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${((course['progress'] as double) * 100).toInt()}% complete',
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
