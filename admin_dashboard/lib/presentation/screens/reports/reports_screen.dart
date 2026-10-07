import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/admin_theme.dart';
import '../../../core/utils/api_client.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _FlaggedItem {
  final String type; // 'question' or 'answer'
  final String id;
  final String title;
  final String body;
  final String createdAt;

  const _FlaggedItem({
    required this.type,
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });
}

// ── Provider ──────────────────────────────────────────────────────────────────

final flaggedContentProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final resp = await adminApi.get('/community/flagged');
  final data = resp.data['data'];
  if (data is Map) return Map<String, dynamic>.from(data);
  return {'questions': [], 'answers': []};
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final Map<String, bool> _actionLoading = {};

  Future<void> _resolve(_FlaggedItem item) async {
    if (_actionLoading[item.id] == true) return;
    setState(() => _actionLoading[item.id] = true);
    try {
      await adminApi.patch(
          '/community/flagged/${item.type}/${item.id}/resolve');
      ref.invalidate(flaggedContentProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Could not resolve. Please try again.',
            style: TextStyle(fontFamily: 'Nunito'),
          ),
          backgroundColor: AdminColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _actionLoading.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final flaggedAsync = ref.watch(flaggedContentProvider);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reports',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
          ),
          const Text(
            'Review flagged content and misconduct reports',
            style: TextStyle(
              color: AdminColors.grey600,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: flaggedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AdminColors.error, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load flagged content.',
                      style: TextStyle(fontFamily: 'Nunito'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.invalidate(flaggedContentProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.primary,
                          foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
              data: (data) {
                // Build combined list
                final items = <_FlaggedItem>[];

                final questions = data['questions'];
                if (questions is List) {
                  for (final q in questions) {
                    if (q is Map) {
                      items.add(_FlaggedItem(
                        type: 'question',
                        id: q['id']?.toString() ?? '',
                        title: q['title']?.toString() ?? 'Question',
                        body: q['body']?.toString() ?? '',
                        createdAt: q['createdAt']?.toString() ?? '',
                      ));
                    }
                  }
                }

                final answers = data['answers'];
                if (answers is List) {
                  for (final a in answers) {
                    if (a is Map) {
                      items.add(_FlaggedItem(
                        type: 'answer',
                        id: a['id']?.toString() ?? '',
                        title: 'Answer',
                        body: a['body']?.toString() ?? '',
                        createdAt: a['createdAt']?.toString() ?? '',
                      ));
                    }
                  }
                }

                // Sort by createdAt descending
                items.sort((a, b) =>
                    b.createdAt.compareTo(a.createdAt));

                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: AdminColors.success, size: 56),
                        SizedBox(height: 16),
                        Text(
                          'No flagged content.',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Everything looks clean.',
                          style: TextStyle(
                            color: AdminColors.grey600,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => _FlagCard(
                    item: items[i],
                    isLoading: _actionLoading[items[i].id] == true,
                    onResolve: () => _resolve(items[i]),
                    onDismiss: () => _resolve(items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Flag card ─────────────────────────────────────────────────────────────────

class _FlagCard extends StatelessWidget {
  final _FlaggedItem item;
  final bool isLoading;
  final VoidCallback onResolve;
  final VoidCallback onDismiss;

  const _FlagCard({
    required this.item,
    required this.isLoading,
    required this.onResolve,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isQuestion = item.type == 'question';
    // Format date — just show the ISO prefix (date portion)
    final dateStr = item.createdAt.length >= 10
        ? item.createdAt.substring(0, 10)
        : item.createdAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flag icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AdminColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.flag,
                color: AdminColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge + date row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AdminColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          isQuestion ? 'Question' : 'Answer',
                          style: const TextStyle(
                            color: AdminColors.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: AdminColors.grey600,
                          fontSize: 12,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      fontFamily: 'Nunito',
                    ),
                  ),

                  // Body preview
                  if (item.body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.grey600,
                        fontSize: 13,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Actions
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(fontFamily: 'Nunito'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.primary,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                          fontFamily: 'Nunito', fontWeight: FontWeight.w600),
                    ),
                    onPressed: onResolve,
                    child: const Text('Resolve'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
