import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';

class QuestionDetailScreen extends ConsumerWidget {
  final String questionId;
  const QuestionDetailScreen({super.key, required this.questionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Question')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'What is the optimal feeding frequency for Clarias gariepinus?',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'I have been feeding my catfish twice daily but some papers suggest 3 times. What does the research say?',
                          style: TextStyle(height: 1.6),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.thumb_up_outlined, size: 16, color: AppColors.grey600),
                            const SizedBox(width: 4),
                Text('5 upvotes', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('2 Answers', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                _AnswerCard(
                  answer: 'Research by Adewolu et al. (2008) found that 3× daily feeding gave optimal growth for C. gariepinus juveniles at optimal temperatures.',
                  isVerified: true,
                ),
                _AnswerCard(
                  answer: 'Feeding frequency also depends on your feeding rate and stocking density. At high densities, more frequent smaller meals reduce competition.',
                  isVerified: false,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -1))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Write your answer...'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final String answer;
  final bool isVerified;
  const _AnswerCard({required this.answer, required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isVerified)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 14, color: AppColors.success),
                    SizedBox(width: 4),
                    Text('Verified Answer',
                        style: TextStyle(
                            color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            Text(answer, style: const TextStyle(height: 1.6)),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_up_outlined, size: 18),
                  onPressed: () {},
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                const Text(' Helpful'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
