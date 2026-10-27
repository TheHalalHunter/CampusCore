import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/api_client.dart';
import '../../../app/theme/admin_theme.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

/// Fetches the list of community questions for moderation.
///
/// The backend wraps responses in `{ success, data, message }`. For the
/// questions list, `data` is the shaped object `{ questions: [...], total }`,
/// so we extract the `questions` array and fall back to a flat list if the
/// backend ever returns one directly.
final adminQuestionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final resp =
      await adminApi.get('/community/questions', params: {'limit': '50'});
  final data = resp.data['data'] ?? resp.data;
  if (data is Map) {
    final questions = data['questions'];
    if (questions is List) return questions.cast<Map<String, dynamic>>();
    return [];
  }
  if (data is List) return data.cast<Map<String, dynamic>>();
  return [];
});

/// Fetches the answers for a single question (lazily — only when its
/// ExpansionTile is expanded). Handles both the shaped
/// `{ data: { question, answers } }` response and a flat list of answers.
final adminQuestionAnswersProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, questionId) async {
  final resp = await adminApi.get('/community/questions/$questionId');
  final raw = resp.data['data'] ?? resp.data;
  if (raw is Map) {
    final answers = raw['answers'];
    if (answers is List) return answers.cast<Map<String, dynamic>>();
    return [];
  }
  if (raw is List) return raw.cast<Map<String, dynamic>>();
  return [];
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class CommunityModerationScreen extends ConsumerWidget {
  const CommunityModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(adminQuestionsProvider);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PageHeader(
            title: 'Community Moderation',
            subtitle: 'Verify student answers',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: questionsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AdminColors.error),
                    const SizedBox(height: 12),
                    const Text('Could not load questions.',
                        style: TextStyle(fontFamily: 'Nunito')),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry',
                          style: TextStyle(fontFamily: 'Nunito')),
                      onPressed: () =>
                          ref.invalidate(adminQuestionsProvider),
                    ),
                  ],
                ),
              ),
              data: (questions) {
                if (questions.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 56, color: AdminColors.success),
                        SizedBox(height: 16),
                        Text('No questions to moderate.',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        SizedBox(height: 8),
                        Text('Community questions will appear here.',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                color: AdminColors.grey600)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (_, i) =>
                      _QuestionTile(question: questions[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Question tile (lazy fetch on expand) ──────────────────────────────────────

class _QuestionTile extends ConsumerStatefulWidget {
  final Map<String, dynamic> question;
  const _QuestionTile({required this.question});

  @override
  ConsumerState<_QuestionTile> createState() => _QuestionTileState();
}

class _QuestionTileState extends ConsumerState<_QuestionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final id = q['id']?.toString() ?? '';
    final answerCount = q['answerCount'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Remove the default divider/extra padding inside the ExpansionTile.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            q['title']?.toString() ?? 'Untitled question',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AdminColors.grey900,
            ),
          ),
          subtitle: Text(
            '$answerCount answers',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: AdminColors.grey600,
            ),
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          children: [
            if (!_expanded)
              const SizedBox.shrink()
            else
              ref.watch(adminQuestionAnswersProvider(id)).when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: LinearProgressIndicator(),
                    ),
                    error: (_, __) => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Could not load answers.',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: AdminColors.error,
                        ),
                      ),
                    ),
                    data: (answers) {
                      if (answers.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No answers yet.',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: AdminColors.grey600,
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: answers
                              .map((a) => _AnswerModerationCard(
                                    answer: a,
                                    questionId: id,
                                  ))
                              .toList(),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

// ─── Answer moderation card ───────────────────────────────────────────────────

class _AnswerModerationCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> answer;
  final String questionId;
  const _AnswerModerationCard({required this.answer, required this.questionId});

  @override
  ConsumerState<_AnswerModerationCard> createState() =>
      _AnswerModerationCardState();
}

class _AnswerModerationCardState extends ConsumerState<_AnswerModerationCard> {
  bool _verifying = false;

  String get _authorName {
    final author = widget.answer['author'];
    if (author is Map) {
      final first = author['firstName']?.toString() ?? '';
      final last = author['lastName']?.toString() ?? '';
      final name = '$first $last'.trim();
      if (name.isNotEmpty) return name;
    }
    return 'Student';
  }

  Future<void> _verify() async {
    setState(() => _verifying = true);
    try {
      await adminApi.patch('/community/answers/${widget.answer['id']}/verify');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Answer verified!'),
            backgroundColor: AdminColors.success,
          ),
        );
      }
      // Refresh the answers for this question so the badge appears.
      ref.invalidate(adminQuestionAnswersProvider(widget.questionId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying answer: $e'),
            backgroundColor: AdminColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = widget.answer['isVerified'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18, color: AdminColors.grey600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _authorName,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AdminColors.grey900,
                  ),
                ),
              ),
              if (isVerified)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.answer['body']?.toString() ?? '',
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: AdminColors.grey800,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (!isVerified)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.success,
                foregroundColor: Colors.white,
              ),
              icon: _verifying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 16),
              label: Text(
                _verifying ? 'Verifying…' : 'Verify',
                style: const TextStyle(fontFamily: 'Nunito'),
              ),
              onPressed: _verifying ? null : _verify,
            ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Page header copied from moderation_screen.dart to keep a consistent
/// look across admin screens (kept private to this file).
class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _PageHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 24,
                  fontWeight: FontWeight.w700)),
          Text(subtitle,
              style: const TextStyle(
                  fontFamily: 'Nunito', color: AdminColors.grey600)),
        ],
      );
}
