import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/router/app_router.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Ask Question'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _QuestionCard(index: i),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  const _QuestionCard({required this.index});

  static const _questions = [
    'What is the optimal feeding frequency for Clarias gariepinus?',
    'Can someone recommend good references for aquatic toxicology?',
    'Difference between extensive and intensive aquaculture systems?',
    'How is dissolved oxygen measured in pond management?',
    'Best approach for calculating FCR in my practicals?',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('${AppRoutes.community}/questions/q_$index'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 16, backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.person, color: Colors.white, size: 16)),
                  const SizedBox(width: 8),
                  Text('Student ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                  const Spacer(),
                  Text('${index + 1}h ago',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              Text(_questions[index],
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.question_answer_outlined, size: 16, color: AppColors.grey600),
                  const SizedBox(width: 4),
                  Text('${(index + 1) * 2} answers',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 16),
                  const Icon(Icons.thumb_up_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('${index + 3}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
