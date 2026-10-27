import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/storage/activity_storage.dart';
import '../../../core/utils/responsive.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final questionDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, questionId) async {
    final api  = ref.read(apiClientProvider);
    final resp = await api.get(ApiConstants.questionDetail(questionId));
    final data = resp.data['data'] ?? resp.data;
    // Backend may return { question: {...}, answers: [...] }
    // OR the question map directly with an 'answers' key.
    if (data is Map<String, dynamic> && data.containsKey('question')) {
      final q = Map<String, dynamic>.from(data['question'] as Map);
      q['answers'] = data['answers'] ?? q['answers'] ?? [];
      return q;
    }
    return data as Map<String, dynamic>;
  },
);

// ── Screen ────────────────────────────────────────────────────────────────────

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
  final _formKey    = GlobalKey<FormState>();
  bool _submitting  = false;
  bool _voting      = false;
  bool _resolving   = false;

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  // ── Vote handler ─────────────────────────────────────────────────────────

  Future<void> _vote({required String endpoint}) async {
    if (_voting) return;
    setState(() => _voting = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(endpoint);
      ref.invalidate(questionDetailProvider(widget.questionId));
    } catch (_) {
      // Silently ignore — provider refresh restores correct state
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  // ── Resolve handler ───────────────────────────────────────────────────────

  Future<void> _resolve() async {
    setState(() => _resolving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.patch(ApiConstants.resolveQuestion(widget.questionId));
      ref.invalidate(questionDetailProvider(widget.questionId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Question marked as resolved.',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not resolve: $e',
              style: const TextStyle(fontFamily: 'Nunito'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  // ── Submit answer handler ─────────────────────────────────────────────────

  Future<void> _submitAnswer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final api  = ref.read(apiClientProvider);
      await api.post(
        ApiConstants.postAnswer(widget.questionId),
        data: {'body': _answerCtrl.text.trim()},
      );
      _answerCtrl.clear();
      ref.invalidate(questionDetailProvider(widget.questionId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Answer posted!',
                style: TextStyle(fontFamily: 'Nunito')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to post answer: $e',
              style: const TextStyle(fontFamily: 'Nunito'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final questionAsync = ref.watch(questionDetailProvider(widget.questionId));
    final isMobile      = Responsive.isMobile(context);
    final padding       = Responsive.getPaddingEdgeInsets(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/community'),
        ),
        title: questionAsync.when(
          data: (q) {
            final title      = q['title']?.toString() ?? 'Question';
            final isResolved = q['isResolved'] == true;
            return Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Nunito',
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isResolved) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Resolved',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const Text('Loading...'),
          error:   (_, __) => const Text('Question'),
        ),
      ),
      body: questionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Could not load question.',
                style: TextStyle(fontFamily: 'Nunito'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.invalidate(questionDetailProvider(widget.questionId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (question) {
          // Record the view (fire-and-forget) for the home Recent Activity list.
          ActivityStorage.addQuestionView(
            id: widget.questionId,
            title: question['title']?.toString() ?? '',
          );
          final currentUser = ref.read(currentUserProvider);
          return _QuestionDetailBody(
            question:       question,
            questionId:     widget.questionId,
            currentUser:    currentUser,
            isMobile:       isMobile,
            padding:        padding,
            answerCtrl:     _answerCtrl,
            formKey:        _formKey,
            submitting:     _submitting,
            resolving:      _resolving,
            onSubmitAnswer: _submitAnswer,
            onVote:         (endpoint) => _vote(endpoint: endpoint),
            onResolve:      _resolve,
          );
        },
      ),
    );
  }
}

// ── Body widget ───────────────────────────────────────────────────────────────

class _QuestionDetailBody extends StatelessWidget {
  final Map<String, dynamic> question;
  final String questionId;
  final AppUser? currentUser;
  final bool isMobile;
  final EdgeInsets padding;
  final TextEditingController answerCtrl;
  final GlobalKey<FormState> formKey;
  final bool submitting;
  final bool resolving;
  final VoidCallback onSubmitAnswer;
  final void Function(String endpoint) onVote;
  final VoidCallback onResolve;

  const _QuestionDetailBody({
    required this.question,
    required this.questionId,
    required this.currentUser,
    required this.isMobile,
    required this.padding,
    required this.answerCtrl,
    required this.formKey,
    required this.submitting,
    required this.resolving,
    required this.onSubmitAnswer,
    required this.onVote,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    // ── Parse question fields ────────────────────────────────────────────────
    final title      = question['title']?.toString()    ?? '';
    final body       = question['body']?.toString()     ?? '';
    final upvotes    = question['upvoteCount'] as int?  ??
                       question['upvotes']     as int?  ?? 0;
    final isResolved = question['isResolved'] == true;
    final author     = question['author'] ?? question['askedBy'];
    final authorId   = author?['id']?.toString() ?? '';
    final firstName  = author?['firstName']?.toString() ?? 'Student';
    final lastName   = author?['lastName']?.toString()  ?? '';
    final initials   =
        '${firstName.isNotEmpty ? firstName[0] : "S"}${lastName.isNotEmpty ? lastName[0] : ""}';
    final createdAt  = question['createdAt']?.toString() ?? '';
    final tags       = question['tags'] as List?         ?? [];

    // ── Parse answers ────────────────────────────────────────────────────────
    final rawAnswers = question['answers'] as List? ?? [];
    final answers    = rawAnswers
        .cast<Map<String, dynamic>>()
        .toList()
      ..sort((a, b) {
        final aVerified = a['isVerified'] == true ? 1 : 0;
        final bVerified = b['isVerified'] == true ? 1 : 0;
        if (bVerified != aVerified) return bVerified - aVerified;
        final aUp = a['upvoteCount'] as int? ?? a['upvotes'] as int? ?? 0;
        final bUp = b['upvoteCount'] as int? ?? b['upvotes'] as int? ?? 0;
        return bUp - aUp;
      });

    final isOwner    = currentUser != null && currentUser!.id == authorId;
    final canResolve = isOwner && !isResolved;

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Question card ─────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 14 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: isMobile ? 16 : 20,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          initials.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: isMobile ? 11 : 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 8 : 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$firstName $lastName'.trim(),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: isMobile ? 12 : 14,
                                fontFamily: 'Nunito',
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (createdAt.isNotEmpty)
                              Text(
                                _formatDate(createdAt),
                                style: const TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 11,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 12 : 16),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: isMobile ? 16 : 20,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),

                  // Body
                  if (body.isNotEmpty) ...[
                    SizedBox(height: isMobile ? 8 : 12),
                    Text(
                      body,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.6,
                        fontFamily: 'Nunito',
                        fontSize: 14,
                      ),
                    ),
                  ],

                  // Tags
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: tags
                          .map((t) => Chip(
                                label: Text(
                                  t.toString(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Vote row
                  Row(
                    children: [
                      _VoteButton(
                        icon: Icons.thumb_up_outlined,
                        label: '$upvotes',
                        onTap: () =>
                            onVote(ApiConstants.upvoteQuestion(questionId)),
                      ),
                      const SizedBox(width: 8),
                      _VoteButton(
                        icon: Icons.thumb_down_outlined,
                        label: '',
                        onTap: () =>
                            onVote(ApiConstants.downvoteQuestion(questionId)),
                      ),
                      const Spacer(),

                      // Mark as resolved — only shown to question owner when unresolved
                      if (canResolve)
                        ElevatedButton.icon(
                          onPressed: resolving ? null : onResolve,
                          icon: resolving
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_outline,
                                  size: 16),
                          label: const Text('Mark Resolved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: isMobile ? 20 : 28),

          // ── Answers section header ─────────────────────────────────────────
          Text(
            '${answers.length} ${answers.length == 1 ? "Answer" : "Answers"}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),

          // ── Answers list ───────────────────────────────────────────────────
          if (answers.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 40, horizontal: 24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.forum_outlined,
                          size: 48, color: AppColors.border),
                      const SizedBox(height: 12),
                      Text(
                        'No answers yet. Be the first to help!',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textHint),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: answers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _AnswerCard(
                answer:     answers[i],
                questionId: questionId,
                isMobile:   isMobile,
                onVote:     onVote,
              ),
            ),

          SizedBox(height: isMobile ? 24 : 32),

          // ── Post your answer ───────────────────────────────────────────────
          Text(
            'Post Your Answer',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 14 : 20),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: answerCtrl,
                      maxLines: 5,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        labelText: 'Your answer',
                        hintText:
                            'Share what you know — be clear and concise.',
                        alignLabelWithHint: true,
                        counterText: '',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please write your answer';
                        }
                        if (v.trim().length < 10) {
                          return 'Answer too short (min 10 characters)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: submitting ? null : onSubmitAnswer,
                      child: submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit Answer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Answer card ───────────────────────────────────────────────────────────────

class _AnswerCard extends StatelessWidget {
  final Map<String, dynamic> answer;
  final String questionId;
  final bool isMobile;
  final void Function(String endpoint) onVote;

  const _AnswerCard({
    required this.answer,
    required this.questionId,
    required this.isMobile,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final body       = answer['body']?.toString()        ?? '';
    final isVerified = answer['isVerified'] == true;
    final upvotes    = answer['upvoteCount'] as int?     ??
                       answer['upvotes']     as int?     ?? 0;
    final answerId   = answer['id']?.toString()          ?? '';
    final author     = answer['author']                  ?? answer['answeredBy'];
    final firstName  = author?['firstName']?.toString()  ?? 'Student';
    final lastName   = author?['lastName']?.toString()   ?? '';
    final initials   =
        '${firstName.isNotEmpty ? firstName[0] : "S"}${lastName.isNotEmpty ? lastName[0] : ""}';
    final createdAt  = answer['createdAt']?.toString()   ?? '';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isVerified
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.border,
          width: isVerified ? 1.5 : 0.8,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: author + verified badge
            Row(
              children: [
                CircleAvatar(
                  radius: isMobile ? 14 : 17,
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    initials.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: isMobile ? 10 : 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName'.trim(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 11 : 13,
                          fontFamily: 'Nunito',
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (createdAt.isNotEmpty)
                        Text(
                          _formatDate(createdAt),
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                            fontFamily: 'Nunito',
                          ),
                        ),
                    ],
                  ),
                ),
                if (isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_outlined,
                            size: 12, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            SizedBox(height: isMobile ? 10 : 14),

            // Answer body
            Text(
              body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.6,
                fontFamily: 'Nunito',
                fontSize: 14,
              ),
            ),

            SizedBox(height: isMobile ? 10 : 14),
            const Divider(),
            const SizedBox(height: 6),

            // Vote row
            Row(
              children: [
                _VoteButton(
                  icon: Icons.thumb_up_outlined,
                  label: '$upvotes',
                  onTap: () => onVote(ApiConstants.upvoteAnswer(answerId)),
                ),
                const SizedBox(width: 8),
                _VoteButton(
                  icon: Icons.thumb_down_outlined,
                  label: '',
                  onTap: () =>
                      onVote(ApiConstants.downvoteAnswer(answerId)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Vote button ───────────────────────────────────────────────────────────────

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
