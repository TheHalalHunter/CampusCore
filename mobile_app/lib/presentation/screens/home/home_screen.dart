import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../app/router/app_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: CustomScrollView(
        slivers: [
          // Top app bar
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.white,
            title: const Row(
              children: [
                Icon(Icons.school, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'CampusCore',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push(AppRoutes.notifications),
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    'Good morning, Scholar 👋',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ready to learn something new today?',
                    style: TextStyle(color: AppColors.grey600),
                  ),
                  const SizedBox(height: 24),

                  // Quick actions
                  _SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    children: [
                      _QuickAction(icon: Icons.auto_awesome, label: 'AI Tutor', color: AppColors.accent,
                        onTap: () => context.push(AppRoutes.aiAssistant)),
                      _QuickAction(icon: Icons.calculate, label: 'GPA Calc', color: AppColors.info,
                        onTap: () => context.push(AppRoutes.gpaCalculator)),
                      _QuickAction(icon: Icons.trending_up, label: 'Progress', color: AppColors.success,
                        onTap: () => context.push(AppRoutes.progress)),
                      _QuickAction(icon: Icons.upload_file, label: 'Upload', color: AppColors.primaryLight,
                        onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Continue studying
                  _SectionHeader(title: 'Continue Studying', actionLabel: 'See all', onAction: () => context.go(AppRoutes.courses)),
                  const SizedBox(height: 12),
                  _ContinueStudyingCard(),
                  const SizedBox(height: 28),

                  // Latest resources
                  _SectionHeader(title: 'Latest Resources', actionLabel: 'See all', onAction: () {}),
                  const SizedBox(height: 12),
                  _ResourcePreviewList(),
                  const SizedBox(height: 28),

                  // Recent discussions
                  _SectionHeader(title: 'Recent Discussions', actionLabel: 'See all',
                    onAction: () => context.go(AppRoutes.community)),
                  const SizedBox(height: 12),
                  _DiscussionPreviewList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting widgets ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!, style: const TextStyle(color: AppColors.primary)),
          ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ContinueStudyingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AQU 201 — Fish Nutrition', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('Chapter 3: Protein Requirements', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: 0.42,
                  backgroundColor: Colors.white30,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                const Text('42% complete', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourcePreviewList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      {'title': 'AQU 305 Past Questions 2023', 'type': 'Past Question', 'icon': Icons.quiz_outlined},
      {'title': 'Fish Parasitology Lecture Notes', 'type': 'Lecture Note', 'icon': Icons.description_outlined},
      {'title': 'Aquatic Ecology Slides', 'type': 'Slide', 'icon': Icons.slideshow_outlined},
    ];
    return Column(
      children: items.map((item) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item['icon'] as IconData, color: AppColors.primary),
          ),
          title: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(item['type'] as String, style: TextStyle(color: AppColors.grey600, fontSize: 12)),
          trailing: const Icon(Icons.download_outlined, color: AppColors.grey600),
        ),
      )).toList(),
    );
  }
}

class _DiscussionPreviewList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      {'q': 'What is the optimal protein level for catfish juveniles?', 'answers': '4'},
      {'q': 'Can someone explain the nitrogen cycle in aquaculture?', 'answers': '7'},
    ];
    return Column(
      children: items.map((item) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppColors.accent,
            child: Icon(Icons.question_answer, color: Colors.white, size: 18),
          ),
          title: Text(item['q']!, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle: Text('${item['answers']} answers', style: TextStyle(color: AppColors.grey600, fontSize: 12)),
        ),
      )).toList(),
    );
  }
}
