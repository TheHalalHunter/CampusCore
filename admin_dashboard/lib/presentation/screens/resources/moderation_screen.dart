import 'package:flutter/material.dart';
import '../../../app/theme/admin_theme.dart';

class ModerationScreen extends StatelessWidget {
  const ModerationScreen({super.key});

  static final _pending = [
    {'title': 'AQU 301 Lecture Notes — Aquaculture Systems', 'uploader': 'student12@lautech.edu.ng',  'type': 'Lecture Note',  'size': '2.3MB', 'submitted': '30 Jul 2026'},
    {'title': 'Fish Genetics Past Questions 2023',           'uploader': 'student45@lautech.edu.ng',  'type': 'Past Question', 'size': '1.1MB', 'submitted': '29 Jul 2026'},
    {'title': 'Aquatic Toxicology Practical Manual',         'uploader': 'student07@lautech.edu.ng',  'type': 'Practical',     'size': '4.7MB', 'submitted': '28 Jul 2026'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PageHeader(title: 'Resource Moderation', subtitle: 'Review and approve student submissions'),
          const SizedBox(height: 24),
          // Stats
          Row(children: [
            _MiniStat(label: 'Pending',  value: '${_pending.length}', color: AdminColors.warning),
            const SizedBox(width: 16),
            const _MiniStat(label: 'Approved this week', value: '18', color: AdminColors.success),
            const SizedBox(width: 16),
            const _MiniStat(label: 'Rejected this week', value: '3',  color: AdminColors.error),
          ]),
          const SizedBox(height: 24),
          const Text('Pending Submissions',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _pending.length,
              itemBuilder: (_, i) => _PendingCard(resource: _pending[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final Map<String, String> resource;
  const _PendingCard({required this.resource});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: AdminColors.error, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(resource['title']!,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('${resource['type']} • ${resource['size']} • Submitted ${resource['submitted']}',
                      style: const TextStyle(color: AdminColors.grey600, fontSize: 12)),
                  Text('By: ${resource['uploader']}',
                      style: const TextStyle(color: AdminColors.grey600, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Preview'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.success, foregroundColor: Colors.white),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Approve'),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AdminColors.error,
                  side: const BorderSide(color: AdminColors.error)),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Reject'),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(color: AdminColors.grey600, fontSize: 12)),
        ],
      ),
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
      Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
      Text(subtitle, style: const TextStyle(color: AdminColors.grey600)),
    ],
  );
}
