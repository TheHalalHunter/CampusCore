import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

// ── Provider ──────────────────────────────────────────────────────────────────
final questionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api  = ref.read(apiClientProvider);
  final resp = await api.get(ApiConstants.questions, params: {'limit': 30});
  final data = resp.data['data'] ?? resp.data;
  // Handle shaped response: { questions: [...], total: N }
  if (data is Map && data['questions'] is List) {
    return (data['questions'] as List).cast<Map<String, dynamic>>();
  }
  // Handle tuple fallback: [[...questions], count]
  if (data is List && data.isNotEmpty && data[0] is List) {
    return (data[0] as List).cast<Map<String, dynamic>>();
  }
  if (data is List) return data.cast<Map<String, dynamic>>();
  return [];
});

// ── Screen ────────────────────────────────────────────────────────────────────
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  void _openAskDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _AskQuestionDialog(onPosted: () => ref.invalidate(questionsProvider)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsProvider);
    final isMobile       = Responsive.isMobile(context);
    final padding        = Responsive.getPaddingEdgeInsets(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAskDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ask Question', style: TextStyle(fontFamily: 'Nunito')),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Q&A Forum',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: isMobile ? 22 : 28,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask questions, share knowledge, help your peers.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
            ),
            const SizedBox(height: 20),
            questionsAsync.when(
              loading: () => Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, __) => const _SkeletonQuestion(),
                ),
              ),
              error: (_, __) => Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    const Text('Could not load questions.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(questionsProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (questions) {
                if (questions.isEmpty) {
                  return Column(
                    children: [
                      const SizedBox(height: 48),
                      const Icon(Icons.forum_outlined, size: 64, color: AppColors.border),
                      const SizedBox(height: 16),
                      Text(
                        'No questions yet. Be the first to ask!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _openAskDialog(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Ask a Question'),
                      ),
                    ],
                  );
                }
                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: questions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _QuestionTile(question: questions[index], isMobile: isMobile),
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ── Ask Question Dialog ───────────────────────────────────────────────────────
class _AskQuestionDialog extends ConsumerStatefulWidget {
  final VoidCallback onPosted;
  const _AskQuestionDialog({required this.onPosted});

  @override
  ConsumerState<_AskQuestionDialog> createState() => _AskQuestionDialogState();
}

class _AskQuestionDialogState extends ConsumerState<_AskQuestionDialog> {
  final _formKey     = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _tagsCtrl    = TextEditingController();
  bool _posting  = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _posting = true; _error = null; });

    try {
      final api  = ref.read(apiClientProvider);
      final tags = _tagsCtrl.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final resp = await api.post(ApiConstants.postQuestion, data: {
        'title':   _titleCtrl.text.trim(),
        'body':    _contentCtrl.text.trim(),
        if (tags.isNotEmpty) 'tags': tags,
      });

      final body = resp.data as Map<String, dynamic>;
      if (body['success'] != true) {
        setState(() { _posting = false; _error = body['message']?.toString() ?? 'Failed to post.'; });
        return;
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onPosted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question posted!', style: TextStyle(fontFamily: 'Nunito')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() { _posting = false; _error = 'Could not post. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.help_outline, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Ask a Question',
                        style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          fontFamily: 'Nunito', color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Title
                TextFormField(
                  controller: _titleCtrl,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Question title *',
                    hintText: 'e.g. What is the difference between osmosis and diffusion?',
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter a title';
                    if (v.trim().length < 10) return 'Title too short (min 10 chars)';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Content
                TextFormField(
                  controller: _contentCtrl,
                  maxLines: 5,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Details (optional)',
                    hintText: 'Add more context to help others answer better...',
                    alignLabelWithHint: true,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),

                // Tags
                TextFormField(
                  controller: _tagsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tags (optional)',
                    hintText: 'e.g. fisheries, 200L, semester-2',
                    prefixIcon: Icon(Icons.tag_outlined),
                    helperText: 'Separate tags with commas',
                  ),
                ),

                // Error
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontFamily: 'Nunito'))),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _posting ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _posting ? null : _submit,
                        child: _posting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Post Question'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Question tile ─────────────────────────────────────────────────────────────
class _QuestionTile extends StatelessWidget {
  final Map<String, dynamic> question;
  final bool isMobile;
  const _QuestionTile({required this.question, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final title       = question['title']?.toString()    ?? 'Question';
    final content     = question['body']?.toString()    ?? '';
    final answerCount = question['answerCount']          ?? question['_count']?['answers'] ?? 0;
    final viewCount   = question['viewCount']            ?? 0;
    final author      = question['author']               ?? question['askedBy'];
    final firstName   = author?['firstName']?.toString() ?? 'Student';
    final lastName    = author?['lastName']?.toString()  ?? '';
    final initials    = '${firstName.isNotEmpty ? firstName[0] : "S"}${lastName.isNotEmpty ? lastName[0] : ""}';
    final tags        = question['tags'] as List?        ?? [];

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 15 : 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(initials.toUpperCase(),
                    style: TextStyle(color: AppColors.primary, fontSize: isMobile ? 11 : 12, fontWeight: FontWeight.w700, fontFamily: 'Nunito')),
              ),
              SizedBox(width: isMobile ? 8 : 10),
              Expanded(
                child: Text('$firstName $lastName'.trim(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: isMobile ? 11 : 13),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 10),
          Text(title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700, fontSize: isMobile ? 13 : 15, color: AppColors.textPrimary),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(content,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary, fontSize: isMobile ? 11 : 13),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          SizedBox(height: isMobile ? 8 : 10),
          Wrap(
            spacing: 6, runSpacing: 4,
            children: [
              _Badge(icon: Icons.comment_outlined, label: '$answerCount ${answerCount == 1 ? "answer" : "answers"}', color: AppColors.primary),
              _Badge(icon: Icons.visibility_outlined, label: '$viewCount views', color: AppColors.success),
              ...tags.take(2).map((t) => _Badge(label: t.toString(), color: AppColors.cyan)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Badge({required this.label, required this.color, this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 11, color: color), const SizedBox(width: 3)],
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Nunito')),
        ],
      ),
    );
  }
}

class _SkeletonQuestion extends StatelessWidget {
  const _SkeletonQuestion();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 36, height: 36, decoration: const BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Container(width: 100, height: 12, color: AppColors.surfaceAlt),
          ]),
          const SizedBox(height: 10),
          Container(width: double.infinity, height: 14, color: AppColors.surfaceAlt),
          const SizedBox(height: 6),
          Container(width: 200, height: 12, color: AppColors.surfaceAlt),
        ],
      ),
    );
  }
}
