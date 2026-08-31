import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/router/app_router.dart';
import '../../../data/models/question_model.dart';
import '../../providers/community_provider.dart';
import 'discussions_screen.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedLevel = 'All';
  final _levels = ['All', '100L', '200L', '300L', '400L', '500L'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Q&A'),
            Tab(text: 'Discussions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _QATab(
            selectedLevel: _selectedLevel,
            levels: _levels,
            onLevelChanged: (l) => setState(() => _selectedLevel = l),
          ),
          const DiscussionsScreen(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabCtrl,
        builder: (_, __) => FloatingActionButton.extended(
          onPressed: () => _tabCtrl.index == 0
              ? context.push(AppRoutes.postQuestion)
              : null,
          icon: const Icon(Icons.add),
          label: Text(_tabCtrl.index == 0 ? 'Ask Question' : 'New Thread'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

// ─── Q&A Tab ──────────────────────────────────────────────────────────────────

class _QATab extends ConsumerWidget {
  final String selectedLevel;
  final List<String> levels;
  final void Function(String) onLevelChanged;

  const _QATab({
    required this.selectedLevel,
    required this.levels,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(
      questionsProvider((
        courseId: null,
        level: selectedLevel == 'All' ? null : selectedLevel,
      )),
    );

    return Column(
      children: [
        // Level filter
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: levels.map((level) {
                final selected = selectedLevel == level;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onLevelChanged(level),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(level,
                          style: TextStyle(
                            color: selected ? Colors.white : AppColors.textSecondary,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Questions list
        Expanded(
          child: questionsAsync.when(
            data: (questions) {
              if (questions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
                        child: const Icon(Icons.forum_outlined, size: 40, color: AppColors.primary),
                      ),
                      const SizedBox(height: 20),
                      const Text('No questions yet',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      const Text('Be the first to ask a question.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Ask a Question'),
                        onPressed: () => context.push(AppRoutes.postQuestion),
                      ),
                    ]),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(allQuestionsProvider),
                color: AppColors.primary,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: questions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _QuestionCard(question: questions[i]),
                ),
              );
            },
            loading: () => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, __) => Container(
                height: 100,
                decoration: BoxDecoration(color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            error: (_, __) => Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.wifi_off, size: 48, color: AppColors.textHint),
                const SizedBox(height: 12),
                const Text('Could not load questions.',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(allQuestionsProvider),
                  child: const Text('Retry'),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final QuestionModel question;
  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push(
          '${AppRoutes.community}/questions/${question.id}',
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      question.authorId.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (question.academicLevel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        question.academicLevel!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    question.timeAgo,
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                  if (question.isResolved) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 16),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                question.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),

              // Body preview
              if (question.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  question.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],

              // Tags
              if (question.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: question.tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )).toList(),
                ),
              ],

              const SizedBox(height: 12),

              // Footer stats
              Row(
                children: [
                  _StatChip(
                    icon: Icons.question_answer_outlined,
                    label: '${question.answerCount} answers',
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.thumb_up_outlined,
                    label: '${question.upvoteCount}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
