import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

final progressDataProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final resp = await api.get(ApiConstants.gpa);
    final data = resp.data['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
  } catch (_) {}
  return {};
});

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(progressDataProvider);
    final isMobile      = Responsive.isMobile(context);
    final padding       = Responsive.getPaddingEdgeInsets(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Progress Tracker'),
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
              'Academic Progress',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: isMobile ? 22 : 28,
                  ),
            ),
            const SizedBox(height: 20),
            progressAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    const Text('Could not load progress data.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(progressDataProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (data) => _ProgressContent(data: data, isMobile: isMobile),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMobile;

  const _ProgressContent({required this.data, required this.isMobile});

  String _gpaClass(double gpa) {
    if (gpa >= 4.5) return 'First Class';
    if (gpa >= 3.5) return 'Second Class Upper';
    if (gpa >= 2.4) return 'Second Class Lower';
    if (gpa >= 1.5) return 'Third Class';
    return 'Pass';
  }

  Color _gpaColor(double gpa) {
    if (gpa >= 4.5) return AppColors.success;
    if (gpa >= 3.5) return AppColors.primary;
    if (gpa >= 2.4) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final cgpa      = (data['cgpa'] ?? data['gpa'] ?? 0.0).toDouble();
    final gpaClass  = _gpaClass(cgpa);
    final gpaColor  = _gpaColor(cgpa);
    final courses   = data['courses'] as List? ?? [];
    final level     = data['level']?.toString()    ?? '';
    final semester  = data['semester']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // GPA card
        Card(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 28),
            child: Row(
              children: [
                Container(
                  width: isMobile ? 70 : 90,
                  height: isMobile ? 70 : 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [gpaColor.withValues(alpha: 0.15), gpaColor.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: gpaColor, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      cgpa.toStringAsFixed(2),
                      style: TextStyle(
                        color: gpaColor,
                        fontSize: isMobile ? 20 : 26,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gpaClass,
                        style: TextStyle(
                          color: gpaColor,
                          fontSize: isMobile ? 16 : 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cumulative GPA',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                      ),
                      if (level.isNotEmpty || semester.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (level.isNotEmpty)
                              _Tag(label: '${level}L', color: AppColors.primary),
                            if (semester.isNotEmpty)
                              _Tag(label: 'Semester $semester', color: AppColors.cyan),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (courses.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Course Grades',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: isMobile ? 16 : 18,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: courses.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final c       = courses[index] as Map<String, dynamic>? ?? {};
                final name    = c['courseName']?.toString()  ?? c['name']?.toString()  ?? 'Course ${index + 1}';
                final code    = c['courseCode']?.toString()  ?? c['code']?.toString()  ?? '';
                final grade   = c['grade']?.toString()       ?? '-';
                final gradeColor = _gradeColor(grade);
                return Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 12 : 14,
                                    color: AppColors.textPrimary,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (code.isNotEmpty)
                              Text(
                                code,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textHint,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        width: isMobile ? 40 : 48,
                        height: isMobile ? 40 : 48,
                        decoration: BoxDecoration(
                          color: gradeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: gradeColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            grade,
                            style: TextStyle(
                              color: gradeColor,
                              fontWeight: FontWeight.w800,
                              fontSize: isMobile ? 16 : 18,
                              fontFamily: 'Nunito',
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
        ] else ...[
          const SizedBox(height: 48),
          const Center(
            child: Column(
              children: [
                Icon(Icons.bar_chart_outlined, size: 64, color: AppColors.border),
                SizedBox(height: 16),
                Text(
                  'No grade records yet.',
                  style: TextStyle(color: AppColors.textHint, fontFamily: 'Nunito'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Color _gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':  return AppColors.success;
      case 'B':  return AppColors.primary;
      case 'C':  return AppColors.warning;
      case 'D':  return AppColors.cyan;
      case 'E':  return Colors.orange;
      case 'F':  return AppColors.error;
      default:   return AppColors.textHint;
    }
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
          color: color, fontSize: 11,
          fontWeight: FontWeight.w600, fontFamily: 'Nunito',
        ),
      ),
    );
  }
}
