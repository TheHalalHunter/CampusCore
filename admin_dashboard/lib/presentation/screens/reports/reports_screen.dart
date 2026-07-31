import 'package:flutter/material.dart';
import '../../../app/theme/admin_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static final _reports = [
    {'type': 'Content',      'description': 'Inappropriate answer in Q&A section',       'reporter': 'student22',   'status': 'Open',     'date': '31 Jul 2026'},
    {'type': 'Misconduct',   'description': 'User suspected of sharing exam answers live','reporter': 'student08',   'status': 'Open',     'date': '30 Jul 2026'},
    {'type': 'Content',      'description': 'Offensive comment in 300L discussion',       'reporter': 'student15',   'status': 'Resolved', 'date': '29 Jul 2026'},
    {'type': 'Impersonation','description': 'Account using another student\'s matric no.','reporter': 'student31',   'status': 'Open',     'date': '28 Jul 2026'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reports', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const Text('Review flagged content and misconduct reports',
              style: TextStyle(color: AdminColors.grey600)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _reports.length,
              itemBuilder: (_, i) => _ReportCard(report: _reports[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, String> report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final isOpen = report['status'] == 'Open';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isOpen ? AdminColors.error : AdminColors.success).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isOpen ? Icons.flag : Icons.check_circle,
                color: isOpen ? AdminColors.error : AdminColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AdminColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(report['type']!,
                          style: const TextStyle(
                              color: AdminColors.warning, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Text(report['date']!,
                        style: const TextStyle(color: AdminColors.grey600, fontSize: 12)),
                  ]),
                  const SizedBox(height: 6),
                  Text(report['description']!,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('Reported by: ${report['reporter']}',
                      style: const TextStyle(color: AdminColors.grey600, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isOpen) ...[
              TextButton(onPressed: () {}, child: const Text('Dismiss')),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary, foregroundColor: Colors.white),
                onPressed: () {},
                child: const Text('Resolve'),
              ),
            ] else
              const Text('Resolved',
                  style: TextStyle(color: AdminColors.success, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
