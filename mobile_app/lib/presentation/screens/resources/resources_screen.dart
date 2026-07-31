import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';

class ResourcesScreen extends ConsumerWidget {
  final String courseId;
  const ResourcesScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resources')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _ResourceTile(index: i),
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final int index;
  const _ResourceTile({required this.index});

  static const _types = ['Lecture Note', 'Past Question', 'Slide', 'Practical Manual'];
  static const _icons = [
    Icons.description_outlined,
    Icons.quiz_outlined,
    Icons.slideshow_outlined,
    Icons.science_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final type = _types[index % _types.length];
    final icon = _icons[index % _icons.length];
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text('$type ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('PDF • ${(index + 1) * 300}KB • ${2020 + index}/${2021 + index}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, color: AppColors.success, size: 18),
            const SizedBox(width: 4),
            const Icon(Icons.download_outlined),
          ],
        ),
      ),
    );
  }
}
