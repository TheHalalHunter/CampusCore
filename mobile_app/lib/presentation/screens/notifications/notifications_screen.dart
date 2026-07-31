import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Mark all read')),
        ],
      ),
      body: ListView.separated(
        itemCount: 4,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final items = [
            {'icon': Icons.upload_file, 'color': AppColors.success,
              'title': 'Upload approved', 'body': 'Your Fish Nutrition notes have been approved.', 'read': false},
            {'icon': Icons.question_answer, 'color': AppColors.info,
              'title': 'New answer', 'body': 'Someone answered your question about FCR.', 'read': false},
            {'icon': Icons.new_releases, 'color': AppColors.accent,
              'title': 'New resource', 'body': 'AQU 203 Past Questions 2023 uploaded.', 'read': true},
            {'icon': Icons.star, 'color': AppColors.accent,
              'title': 'Badge earned!', 'body': 'You earned the Bookworm badge.', 'read': true},
          ];
          final item = items[i];
          return ListTile(
            tileColor: (item['read'] as bool) ? null : AppColors.primary.withOpacity(0.04),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (item['color'] as Color).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
            ),
            title: Text(item['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(item['body'] as String),
            trailing: (item['read'] as bool)
                ? null
                : Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
          );
        },
      ),
    );
  }
}
