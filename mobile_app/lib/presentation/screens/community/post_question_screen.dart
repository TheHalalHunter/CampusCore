import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../providers/community_provider.dart';
import '../../providers/courses_provider.dart';

class PostQuestionScreen extends ConsumerStatefulWidget {
  const PostQuestionScreen({super.key});

  @override
  ConsumerState<PostQuestionScreen> createState() =>
      _PostQuestionScreenState();
}

class _PostQuestionScreenState extends ConsumerState<PostQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  String? _selectedCourseId;
  String? _selectedLevel;
  bool _submitting = false;

  final _levels = ['100L', '200L', '300L', '400L', '500L'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ask a Question')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tips banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.accent.withOpacity(0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: AppColors.accent, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Write a clear title and detailed question to get the best answers from your peers.',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Question Title',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. What is the optimal feeding frequency for catfish?',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a question title';
                  }
                  if (v.trim().length < 10) {
                    return 'Title must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Body
              const Text(
                'Question Details',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText:
                      'Describe your question in detail. Include what you already know and what you\'ve tried...',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please provide details for your question';
                  }
                  if (v.trim().length < 20) {
                    return 'Please provide more detail (at least 20 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Academic level
              const Text(
                'Academic Level',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _levels.map((level) {
                  final selected = _selectedLevel == level;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedLevel = level),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        level,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Related course (optional)
              const Text(
                'Related Course (optional)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              coursesAsync.when(
                data: (courses) => DropdownButtonFormField<String>(
                  value: _selectedCourseId,
                  hint: const Text('Select a course (optional)'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('No specific course'),
                    ),
                    ...courses.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            '${c.courseCode} — ${c.title}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  onChanged: (val) =>
                      setState(() => _selectedCourseId = val),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 16),

              // Tags
              const Text(
                'Tags (optional)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Separate with commas e.g. fish nutrition, FCR, feeding',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tagsCtrl,
                decoration: const InputDecoration(
                  hintText: 'fish nutrition, FCR, catfish',
                ),
              ),
              const SizedBox(height: 32),

              // Submit
              ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 18),
                label:
                    Text(_submitting ? 'Posting...' : 'Post Question'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    setState(() => _submitting = true);

    final success = await ref.read(postQuestionProvider.notifier).post(
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      courseId: _selectedCourseId,
      academicLevel: _selectedLevel,
      tags: tags,
    );

    setState(() => _submitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question posted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not post question. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
