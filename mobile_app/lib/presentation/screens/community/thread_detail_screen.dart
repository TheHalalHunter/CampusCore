import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../providers/discussions_provider.dart';

class ThreadDetailScreen extends ConsumerStatefulWidget {
  final String threadId;
  const ThreadDetailScreen({super.key, required this.threadId});

  @override
  ConsumerState<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends ConsumerState<ThreadDetailScreen> {
  final _replyCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _postReply() async {
    final body = _replyCtrl.text.trim();
    if (body.isEmpty) return;
    setState(() => _submitting = true);
    final ok = await ref
        .read(threadActionsProvider.notifier)
        .addReply(widget.threadId, body);
    if (mounted) {
      setState(() => _submitting = false);
      if (ok) {
        _replyCtrl.clear();
        FocusScope.of(context).unfocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not post reply. Please try again.'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(threadDetailProvider(widget.threadId));

    return Scaffold(
      appBar: AppBar(title: const Text('Discussion')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load thread.')),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Thread not found.'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Thread body
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (detail.thread.academicLevel != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(detail.thread.academicLevel!,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700)),
                              ),
                            Text(detail.thread.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 10),
                            Text(detail.thread.body,
                                style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondary,
                                    height: 1.6)),
                            const SizedBox(height: 10),
                            Text(detail.thread.timeAgo,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textHint)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Replies header
                    Text(
                      '${detail.replies.length} ${detail.replies.length == 1 ? 'Reply' : 'Replies'}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),

                    // Replies
                    ...detail.replies.map((reply) => _ReplyCard(reply: reply)),
                  ],
                ),
              ),

              // Reply input
              Container(
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 12),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: const Border(
                      top: const BorderSide(
                          color: AppColors.border, width: 0.8)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyCtrl,
                        decoration: InputDecoration(
                          hintText: 'Write a reply…',
                          filled: true,
                          fillColor: AppColors.surfaceAlt,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _submitting
                        ? const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                            icon: const Icon(Icons.send_rounded,
                                color: AppColors.primary),
                            onPressed: _postReply,
                          ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReplyCard extends StatelessWidget {
  final dynamic reply;
  const _ReplyCard({required this.reply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: const Icon(Icons.person_outline,
                size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reply.body,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.5)),
                  const SizedBox(height: 4),
                  Text(reply.timeAgo,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
