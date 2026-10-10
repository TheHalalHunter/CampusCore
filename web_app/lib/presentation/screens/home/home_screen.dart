import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

// -- Provider -----------------------------------------------------------------
final homeDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api  = ref.read(apiClientProvider);
  final user = ref.read(currentUserProvider);
  try {
    final results = await Future.wait([
      api.get(ApiConstants.courses, params: user?.departmentId != null ? {'departmentId': user!.departmentId} : null),
      api.get(ApiConstants.resources),
      api.get(ApiConstants.questions, params: {'limit': '3'}),
      api.get(ApiConstants.gpaCgpa),
    ]);
    final courses   = (results[0].data['data'] as List?) ?? [];
    final resources = (results[1].data['data'] as List?) ?? [];
    final questions = (results[2].data['data'] as List?) ?? [];
    final cgpaData  = results[3].data['data'];
    final cgpa      = ((cgpaData is Map ? cgpaData['cgpa'] : null) ?? 0.0);
    return {
      'courses':    courses,
      'resources':  resources,
      'questions':  questions,
      'cgpa':       (cgpa is num ? cgpa.toDouble() : 0.0).toStringAsFixed(2),
    };
  } catch (_) {
    return {'courses': <dynamic>[], 'resources': <dynamic>[], 'questions': <dynamic>[], 'cgpa': '0.00'};
  }
});

// -- Screen -------------------------------------------------------------------
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting(int hour) {
    if (hour >= 5 && hour < 12)  return 'Good morning';
    if (hour >= 12 && hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(currentUserProvider);
    final dashAsync = ref.watch(homeDashboardProvider);
    final isMobile  = Responsive.isMobile(context);
    final spacing   = Responsive.getSpacing(context);
    final padding   = Responsive.getPaddingEdgeInsets(context);
    final hour      = DateTime.now().hour;
    final greeting  = '${_greeting(hour)}, ${user?.firstName ?? 'Student'}!';
    final dateStr   = DateFormat('EEEE, MMMM d').format(DateTime.now());

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
                    '$greeting ??',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 20 : 26,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: AppColors.textOnDarkSub,
                      fontSize: isMobile ? 12 : 14,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing + 4),

            // Stats row
            dashAsync.when(
              loading: () => _buildStatsSkeleton(isMobile, spacing),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) {
                final courses   = (data['courses']   as List).length;
                final resources = (data['resources'] as List).length;
                final cgpa      = data['cgpa']?.toString() ?? '0.00';
                final rep       = user?.reputationPoints ?? 0;
                return _buildStatsRow(context, isMobile, spacing, courses, resources, cgpa, rep, () => context.go('/courses'), () => context.go('/resources'));
              },
            ),
            SizedBox(height: spacing + 4),

            // Quick Actions
            Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: isMobile ? 16 : 18)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickAction(icon: Icons.forum_outlined,        label: 'Ask Question',    color: AppColors.cyan,         onTap: () => context.go('/community')),
                _QuickAction(icon: Icons.upload_file_outlined,  label: 'Upload Resource', color: AppColors.primary,      onTap: () => context.go('/resources')),
                _QuickAction(icon: Icons.auto_awesome_outlined, label: 'AI Assistant',    color: AppColors.primaryLight, onTap: () => context.go('/ai')),
                _QuickAction(icon: Icons.school_outlined,       label: 'Browse Courses',  color: AppColors.success,      onTap: () => context.go('/courses')),
              ],
            ),
            SizedBox(height: spacing + 4),

            // Recent Questions
            _SectionHeader(
              title: 'Recent Questions',
              onViewAll: () => context.go('/community'),
            ),
            const SizedBox(height: 12),
            dashAsync.when(
              loading: () => _buildQuestionsSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) {
                final questions = data['questions'] as List;
                if (questions.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.forum_outlined,
                    text: 'No questions yet. Be the first to ask!',
                  );
                }
                return Column(
                  children: questions
                      .take(3)
                      .map((q) => _QuestionCard(
                            question: q as Map<String, dynamic>,
                            onTap: () => context.go('/community'),
                          ))
                      .toList(),
                );
              },
            ),
            SizedBox(height: spacing + 4),

            // Department Courses
            _SectionHeader(
              title: 'Your Courses',
              onViewAll: () => context.go('/courses'),
            ),
            const SizedBox(height: 12),
            dashAsync.when(
              loading: () => _buildCoursesSkeleton(isMobile, spacing),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) {
                final courses = data['courses'] as List;
                if (courses.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.school_outlined,
                    text: 'No courses found for your department.',
                  );
                }
                return GridView.count(
                  crossAxisCount: isMobile ? 1 : 2,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: isMobile ? 4 : 3.2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: courses
                      .take(4)
                      .map((c) => _CourseCard(
                            course: c as Map<String, dynamic>,
                            onTap: () => context.go('/courses/${c['id']}'),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    bool isMobile,
    double spacing,
    int courses,
    int resources,
    String cgpa,
    int rep,
    VoidCallback onCoursesTap,
    VoidCallback onResourcesTap,
  ) {
    return Row(
      children: [
        Expanded(child: GestureDetector(onTap: onCoursesTap,   child: _StatCard(title: 'Courses',    value: courses.toString(),   icon: Icons.school_outlined,         color: AppColors.primary))),
        SizedBox(width: spacing),
        Expanded(child: GestureDetector(onTap: onResourcesTap, child: _StatCard(title: 'Resources',  value: resources.toString(), icon: Icons.library_books_outlined,  color: AppColors.cyan))),
        SizedBox(width: spacing),
        Expanded(child: _StatCard(title: 'Reputation', value: rep.toString(), icon: Icons.star_outline, color: AppColors.warning)),
        SizedBox(width: spacing),
        Expanded(child: _StatCard(title: 'CGPA',       value: cgpa,           icon: Icons.trending_up_outlined, color: AppColors.success)),
      ],
    );
  }

  Widget _buildStatsSkeleton(bool isMobile, double spacing) {
    return Row(
      children: List.generate(4, (i) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : spacing),
          child: const _SkeletonCard(),
        ),
      )),
    );
  }

  Widget _buildQuestionsSkeleton() {
    return Column(
      children: List.generate(3, (_) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: double.infinity, height: 14, color: AppColors.surfaceAlt),
            const SizedBox(height: 8),
            Container(width: 100, height: 11, color: AppColors.surfaceAlt),
          ],
        ),
      )),
    );
  }

  Widget _buildCoursesSkeleton(bool isMobile, double spacing) {
    return GridView.count(
      crossAxisCount: isMobile ? 1 : 2,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: isMobile ? 4 : 3.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(4, (_) => const _SkeletonCard()),
    );
  }
}

// -- Widgets ------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;
  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
        ),
        TextButton(
          onPressed: onViewAll,
          child: const Text('View all ?', style: TextStyle(fontSize: 12, fontFamily: 'Nunito')),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final VoidCallback onTap;
  const _QuestionCard({required this.question, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title       = question['title']?.toString() ?? 'Question';
    final answerCount = question['answerCount'] ?? question['answer_count'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$answerCount ans',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback onTap;
  const _CourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final code  = course['code']?.toString()          ?? course['courseCode']?.toString() ?? '';
    final title = course['title']?.toString()         ?? course['name']?.toString()       ?? 'Course';
    final level = course['academicLevel']?.toString() ?? course['academic_level']?.toString() ?? '';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.book_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.primary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'Nunito',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (level.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    level,
                    style: const TextStyle(
                      color: AppColors.cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.border),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: AppColors.textHint, fontFamily: 'Nunito', fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: isMobile ? 20 : 26,
                fontWeight: FontWeight.w800,
                fontFamily: 'Nunito',
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.grey500,
                fontSize: 11,
                fontFamily: 'Nunito',
              ),
              overflow: TextOverflow.ellipsis,
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 8),
            Container(width: 50, height: 24, color: AppColors.surfaceAlt),
            const SizedBox(height: 4),
            Container(width: 70, height: 11, color: AppColors.surfaceAlt),
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

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

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
