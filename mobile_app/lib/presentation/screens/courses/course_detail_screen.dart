import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/router/app_router.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fish Nutrition'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Notes'),
            Tab(text: 'Past Q.'),
            Tab(text: 'Discuss'),
            Tab(text: 'AI Tutor'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // Overview
          const _CourseOverview(),
          // Notes
          const _ResourcesTab(type: 'Lecture Notes'),
          // Past Questions
          const _ResourcesTab(type: 'Past Questions'),
          // Discussion
          const _DiscussionTab(),
          // AI Tutor
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Open AI Tutor'),
              onPressed: () => context.push(AppRoutes.aiAssistant),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseOverview extends StatelessWidget {
  const _CourseOverview();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AQU 201 — Fish Nutrition',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 8),
          Text('200 Level • Semester 1 • 2 Credit Units',
              style: TextStyle(color: AppColors.grey600)),
          const SizedBox(height: 16),
          const Text(
            'This course covers the nutritional requirements of fish, feed formulation, and feeding strategies in aquaculture systems.',
            style: TextStyle(height: 1.6),
          ),
          const SizedBox(height: 24),
          const Text('Topics', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ...[
            'Introduction to Fish Nutrition',
            'Protein and Amino Acids in Fish Feed',
            'Lipid Requirements',
            'Carbohydrates and Energy',
            'Vitamins and Minerals',
            'Feed Formulation Principles',
            'Feed Processing Technologies',
          ].map((t) => ListTile(
                leading: const Icon(Icons.check_circle_outline, color: AppColors.primary),
                title: Text(t),
                dense: true,
              )),
        ],
      ),
    );
  }
}

class _ResourcesTab extends StatelessWidget {
  final String type;
  const _ResourcesTab({required this.type});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, i) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.picture_as_pdf, color: AppColors.error),
          title: Text('$type ${i + 1}'),
          subtitle: Text(type == 'Past Questions' ? '${2019 + i}/2020' : 'PDF • 2.${i + 1}MB'),
          trailing: const Icon(Icons.download_outlined),
        ),
      ),
    );
  }
}

class _DiscussionTab extends StatelessWidget {
  const _DiscussionTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Course discussions will appear here.'),
    );
  }
}
