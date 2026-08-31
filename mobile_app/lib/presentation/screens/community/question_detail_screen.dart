import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/question_model.dart';
import '../../providers/community_provider.dart';
import '../../providers/discussions_provider.dart';

class QuestionDetailScreen extends ConsumerStatefulWidget {
  final String questionId;
  const QuestionDetailScreen({super.key, required this.questionId});

  @override
  ConsumerState<QuestionDetailScreen> createState() =>
      _QuestionDetailScreenState();
}

class _QuestionDetailScreenState
    extends ConsumerState<QuestionDetailScreen> {
  final _answerCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final answersAsync = ref.watch(answersProvider(widget.questionId));
    final allQuestionsAsync = ref.watch(allQuestionsProvider);

    // Find the question from the cache
    final question = allQuestionsAsync.value?.firstWhere(
      (q) => q.id == widget.questionId,
      orElse: () => QuestionModel(
        id: widget.questionId,
        title: 'Question',
        body: '',
        authorId: '',
        upvoteCount: 0,
        answerCount: 0,
        isResolved: false,
        isFlagged: false,
        tags: [],
        createdAt: DateTime.now(),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Flag as inappropriate',
            onPressed: () => _flag(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(answersProvider(widget.questionId)),
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Question card
                  if (question != null) _QuestionCard(question: question),
                  const SizedBox(height: 20),

                  // Answers header
                  answersAsync.when(
                    data: (answers) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${answers.length} Answer${answers.length != 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (answers.any((a) => a.isVerified)) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified,
                                        size: 12, color: AppColors.success),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified answer',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (answers.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.question_answer_outlined,
                                    size: 36, color: AppColors.textHint),
                                SizedBox(height: 8),
                                Text(
                                  'No answers yet. Be the first to help!',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._buildSortedAnswers(answers, widget.questionId),
                      ],
                    ),
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (_, __) => const Text(
                      'Could not load answers.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Answer input bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                top: BorderSide(color: AppColors.border),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _answerCtrl,
                    maxLines: 3,
                    minLines: 1,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Write your answer...',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      filled: true,
                      fillColor: AppColors.surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _submitting
                    ? const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send,
                              color: Colors.white, size: 20),
                          onPressed: () => _submitAnswer(context),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAnswer(BuildContext context) async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    final success = await ref.read(postAnswerProvider.notifier).post(
      questionId: widget.questionId,
      body: text,
    );
    setState(() => _submitting = false);
    if (success) {
      _answerCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Answer posted!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not post answer. Try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _flag(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Flag this question?'),
        content: const Text(
          'This will report the question to moderators for review.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 40),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Question flagged for review.'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            child: const Text('Flag'),
          ),
        ],
      ),
    );
  }
}

List<Widget> _buildSortedAnswers(List<AnswerModel> answers, String questionId) {
  final verified = answers.where((a) => a.isVerified).toList();
  final unverified = answers.where((a) => !a.isVerified).toList()
    ..sort((a, b) => b.upvoteCount.compareTo(a.upvoteCount));
  return [...verified, ...unverified]
      .map((a) => _AnswerCard(answer: a, questionId: questionId))
      .toList();
}

// ─── Question card ────────────────────────────────────────────────────────────

class _QuestionCard extends ConsumerWidget {
  final QuestionModel question;
  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badges
          Row(
            children: [
              if (question.academicLevel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    question.academicLevel!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (question.isResolved) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 14, color: AppColors.success),
                      SizedBox(width: 4),
                      Text(
                        'Resolved',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Text(
                question.timeAgo,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            question.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),

          // Body
          Text(
            question.body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),

          // Tags
          if (question.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: question.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              )).toList(),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 8),

          // Stats with upvote button
          Row(
            children: [
              GestureDetector(
                onTap: () => ref.read(upvoteProvider.notifier)
                    .upvoteQuestion(question.id, question.upvoteCount),
                child: Row(children: [
                  Icon(Icons.thumb_up_outlined,
                      size: 16,
                      color: ref.watch(upvoteProvider)['q_${question.id}'] != null
                          ? AppColors.primary
                          : AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${ref.watch(upvoteProvider.select((s) => s['q_${question.id}'] ?? question.upvoteCount))} upvotes',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ]),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.question_answer_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('${question.answerCount} answers',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Answer card ──────────────────────────────────────────────────────────────

class _AnswerCard extends ConsumerWidget {
  final AnswerModel answer;
  final String questionId;
  const _AnswerCard({required this.answer, required this.questionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: answer.isVerified
            ? AppColors.success.withOpacity(0.04)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: answer.isVerified
              ? AppColors.success.withOpacity(0.4)
              : AppColors.border,
          width: answer.isVerified ? 1.5 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verified badge
          if (answer.isVerified)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 14, color: AppColors.success),
                  SizedBox(width: 6),
                  Text(
                    'Verified Answer',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

          // Answer body
          Text(
            answer.body,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),

          // Footer
          Row(
            children: [
              Text(
                answer.timeAgo,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              // Upvote button
              Consumer(builder: (context, ref, _) {
                final count = ref.watch(upvoteProvider.select(
                    (s) => s['a_${answer.id}'] ?? answer.upvoteCount));
                return InkWell(
                  onTap: () => ref.read(upvoteProvider.notifier)
                      .upvoteAnswer(answer.id, answer.upvoteCount),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(children: [
                      Icon(Icons.thumb_up_outlined, size: 16,
                          color: ref.watch(upvoteProvider)['a_${answer.id}'] != null
                              ? AppColors.primary
                              : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('$count helpful',
                          style: const TextStyle(color: AppColors.textSecondary,
                              fontSize: 12, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                );
              }),
              const SizedBox(width: 4),
              // Flag button
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.flag_outlined,
                      size: 16, color: AppColors.textHint),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
