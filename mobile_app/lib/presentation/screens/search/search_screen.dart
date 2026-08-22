import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/router/app_router.dart';
import '../../providers/search_provider.dart';
import '../../providers/department_provider.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/resource_model.dart';
import '../../../data/models/question_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (value.trim().length < 2) {
      ref.read(searchProvider.notifier).clear();
      return;
    }
    // Debounce-style: search on every keystroke (provider handles fast calls)
    _doSearch(value);
  }

  Future<void> _doSearch(String q) async {
    final dept = await ref.read(primaryDepartmentProvider.future);
    ref.read(searchProvider.notifier).search(q, departmentId: dept?.id);
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          focusNode: _focusNode,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: 'Search courses, resources, questions…',
            filled: true,
            fillColor: AppColors.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _ctrl.clear();
                      ref.read(searchProvider.notifier).clear();
                    },
                  )
                : null,
          ),
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: _buildBody(search),
    );
  }

  Widget _buildBody(SearchState search) {
    if (!search.hasQuery) {
      return _EmptyState(
        icon: Icons.search,
        title: 'Search CampusCore',
        subtitle: 'Find courses, resources and community questions.',
      );
    }

    if (search.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (search.error != null) {
      return _EmptyState(
        icon: Icons.error_outline,
        title: 'Search failed',
        subtitle: search.error!,
      );
    }

    if (!search.hasResults) {
      return _EmptyState(
        icon: Icons.search_off,
        title: 'No results for "${search.query}"',
        subtitle: 'Try different keywords.',
      );
    }

    final results = search.results!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Courses section
        if (results.courses.isNotEmpty) ...[
          _SectionHeader(
              label: 'Courses', count: results.courses.length),
          ...results.courses.map((c) => _CourseResultTile(course: c)),
          const SizedBox(height: 8),
        ],

        // Resources section
        if (results.resources.isNotEmpty) ...[
          _SectionHeader(
              label: 'Resources', count: results.resources.length),
          ...results.resources.map((r) => _ResourceResultTile(resource: r)),
          const SizedBox(height: 8),
        ],

        // Questions section
        if (results.questions.isNotEmpty) ...[
          _SectionHeader(
              label: 'Questions', count: results.questions.length),
          ...results.questions.map((q) => _QuestionResultTile(question: q)),
        ],
      ],
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textSecondary)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ─── Course result tile ───────────────────────────────────────────────────────

class _CourseResultTile extends StatelessWidget {
  final CourseModel course;
  const _CourseResultTile({required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.menu_book_outlined,
              color: AppColors.primary, size: 20),
        ),
        title: Text(course.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
            '${course.courseCode} • ${course.academicLevel} • Sem ${course.semester}',
            style: const TextStyle(fontSize: 12)),
        onTap: () => context.push('${AppRoutes.courses}/${course.id}'),
      ),
    );
  }
}

// ─── Resource result tile ─────────────────────────────────────────────────────

class _ResourceResultTile extends StatelessWidget {
  final ResourceModel resource;
  const _ResourceResultTile({required this.resource});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.description_outlined,
              color: AppColors.accent, size: 20),
        ),
        title: Text(resource.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
            '${resource.typeLabel} • ${resource.fileSizeLabel}',
            style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 14, color: AppColors.textHint),
        onTap: () =>
            context.push('${AppRoutes.resources}/${resource.id}/view'),
      ),
    );
  }
}

// ─── Question result tile ─────────────────────────────────────────────────────

class _QuestionResultTile extends StatelessWidget {
  final QuestionModel question;
  const _QuestionResultTile({required this.question});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.help_outline,
              color: AppColors.info, size: 20),
        ),
        title: Text(question.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
            '${question.answerCount} answers • ${question.timeAgo}',
            style: const TextStyle(fontSize: 12)),
        trailing: question.isResolved
            ? const Icon(Icons.check_circle,
                size: 16, color: AppColors.success)
            : null,
        onTap: () => context.push(
            '${AppRoutes.community}/questions/${question.id}'),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
