import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/admin_theme.dart';
import '../../../core/utils/api_client.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class PendingResource {
  final String id;
  final String title;
  final String? description;
  final String fileUrl;
  final String? fileType;
  final String type;
  final String uploaderId;
  final String? academicYear;

  const PendingResource({
    required this.id,
    required this.title,
    this.description,
    required this.fileUrl,
    this.fileType,
    required this.type,
    required this.uploaderId,
    this.academicYear,
  });

  factory PendingResource.fromJson(Map<String, dynamic> json) =>
      PendingResource(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        fileUrl: json['fileUrl'] as String? ?? json['file_url'] as String? ?? '',
        fileType: json['fileType'] as String? ?? json['file_type'] as String?,
        type: json['type'] as String? ?? 'other',
        uploaderId: json['uploaderId'] as String? ?? json['uploader_id'] as String? ?? '',
        academicYear: json['academicYear'] as String? ?? json['academic_year'] as String?,
      );

  String get typeLabel {
    switch (type) {
      case 'lecture_note': return 'Lecture Note';
      case 'past_question': return 'Past Question';
      case 'slide': return 'Slide';
      case 'practical_manual': return 'Practical Manual';
      case 'assignment': return 'Assignment';
      default: return 'Resource';
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final pendingResourcesProvider =
    FutureProvider<List<PendingResource>>((ref) async {
  try {
    final response = await adminApi.get('/resources/moderation/pending');
    final data = (response.data['data'] ?? response.data) as List;
    return data
        .map((r) => PendingResource.fromJson(r as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingResourcesProvider);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PageHeader(
              title: 'Resource Moderation',
              subtitle: 'Review and approve student submissions'),
          const SizedBox(height: 24),

          // Stats row
          pendingAsync.when(
            data: (resources) => Row(children: [
              _MiniStat(
                  label: 'Pending',
                  value: '${resources.length}',
                  color: AdminColors.warning),
            ]),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          const Text('Pending Submissions',
              style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),

          Expanded(
            child: pendingAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                  child: Text('Could not load pending resources.')),
              data: (resources) {
                if (resources.isEmpty) {
                  return Center(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_outline,
                              size: 56, color: AdminColors.success),
                          SizedBox(height: 16),
                          Text('All caught up!',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                          SizedBox(height: 8),
                          Text('No resources pending review.',
                              style: TextStyle(
                                  color: AdminColors.grey600)),
                        ]),
                  );
                }
                return ListView.builder(
                  itemCount: resources.length,
                  itemBuilder: (_, i) => _PendingCard(
                    resource: resources[i],
                    onReview: (approved, note) async {
                      try {
                        await adminApi.patch(
                          '/resources/${resources[i].id}/review',
                          data: {
                            'status': approved ? 'approved' : 'rejected',
                            if (note != null && note.isNotEmpty)
                              'reviewNote': note,
                          },
                        );
                        ref.invalidate(pendingResourcesProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(approved
                                ? '✅ Resource approved!'
                                : '❌ Resource rejected.'),
                            backgroundColor: approved
                                ? AdminColors.success
                                : AdminColors.error,
                          ));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: AdminColors.error,
                          ));
                        }
                      }
                    },
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

// ─── Pending card ─────────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  final PendingResource resource;
  final void Function(bool approved, String? note) onReview;

  const _PendingCard({required this.resource, required this.onReview});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.insert_drive_file_outlined,
                  color: AdminColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(resource.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const SizedBox(height: 3),
                      Text(
                        '${resource.typeLabel}'
                        '${resource.academicYear != null ? ' • ${resource.academicYear}' : ''}'
                        '${resource.fileType != null ? ' • .${resource.fileType}' : ''}',
                        style: const TextStyle(
                            color: AdminColors.grey600,
                            fontSize: 12),
                      ),
                    ]),
              ),
            ]),
            if (resource.description != null &&
                resource.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(resource.description!,
                  style: const TextStyle(
                      color: AdminColors.grey600, fontSize: 13)),
            ],
            const SizedBox(height: 14),
            Row(children: [
              // Preview button
              OutlinedButton.icon(
                onPressed: () async {
                  // Open in browser
                  final uri = Uri.tryParse(resource.fileUrl);
                  if (uri != null) {
                    // ignore: deprecated_member_use
                    // launchUrl can't be used in admin (no url_launcher dep)
                    // Show URL instead
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('File URL'),
                        content: SelectableText(resource.fileUrl),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close')),
                        ],
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View URL'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.success,
                    foregroundColor: Colors.white),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Approve'),
                onPressed: () => onReview(true, null),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    foregroundColor: AdminColors.error,
                    side: const BorderSide(color: AdminColors.error)),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Reject'),
                onPressed: () => _showRejectDialog(context),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Resource'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Provide a reason (optional):'),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'e.g. Poor quality, duplicate content...'),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.error,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              onReview(false, ctrl.text.trim());
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    color: AdminColors.grey600, fontSize: 12)),
          ]),
        ),
      );
}

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
                  fontSize: 24, fontWeight: FontWeight.w700)),
          Text(subtitle,
              style: const TextStyle(color: AdminColors.grey600)),
        ],
      );
}
