import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/router/app_router.dart';
import '../../providers/discussions_provider.dart';
import '../../providers/department_provider.dart';

class DiscussionsScreen extends ConsumerStatefulWidget {
  const DiscussionsScreen({super.key});

  @override
  ConsumerState<DiscussionsScreen> createState() => _DiscussionsScreenState();
}

class _DiscussionsScreenState extends ConsumerState<DiscussionsScreen> {
  String? _selectedLevel;
  final _levels = [null, '100L', '200L', '300L', '400L', '500L'];

  @override
  Widget build(BuildContext context) {
    final threadsAsync = ref.watch(threadsProvider(_selectedLevel));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: _levels.map((level) {
                final label = level ?? 'All Levels';
                final selected = _selectedLevel == level;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedLevel = level),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: threadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load discussions.')),
        data: (threads) {
          if (threads.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.forum_outlined, size: 56, color: AppColors.grey400),
                  const SizedBox(height: 16),
                  const Text('No discussions yet',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Be the first to start a conversation.',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: threads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _ThreadCard(thread: threads[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New Thread'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreateThreadSheet(selectedLevel: _selectedLevel),
    );
  }
}

// ─── Thread card ──────────────────────────────────────────────────────────────

class _ThreadCard extends StatelessWidget {
  final dynamic thread;
  const _ThreadCard({required this.thread});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('${AppRoutes.discussions}/${thread.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (thread.isPinned)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.push_pin, size: 14, color: AppColors.accent),
                    ),
                  if (thread.academicLevel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(thread.academicLevel!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(thread.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(thread.body,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.reply, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text('${thread.replyCount} replies',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textHint)),
                  const Spacer(),
                  Text(thread.timeAgo,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textHint)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Create thread bottom sheet ───────────────────────────────────────────────

class _CreateThreadSheet extends ConsumerStatefulWidget {
  final String? selectedLevel;
  const _CreateThreadSheet({this.selectedLevel});

  @override
  ConsumerState<_CreateThreadSheet> createState() => _CreateThreadSheetState();
}

class _CreateThreadSheetState extends ConsumerState<_CreateThreadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String? _level;

  @override
  void initState() {
    super.initState();
    _level = widget.selectedLevel;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final dept = await ref.read(primaryDepartmentProvider.future);
    if (dept == null) return;

    final ok = await ref.read(threadActionsProvider.notifier).createThread(
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
          academicLevel: _level,
          departmentId: dept.id,
        );
    if (mounted) {
      Navigator.pop(context);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Thread created!'),
          backgroundColor: AppColors.success,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(threadActionsProvider) is AsyncLoading;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Discussion',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: _level,
              decoration: const InputDecoration(labelText: 'Level (optional)'),
              items: [null, '100L', '200L', '300L', '400L', '500L']
                  .map((l) => DropdownMenuItem(
                      value: l, child: Text(l ?? 'All Levels')))
                  .toList(),
              onChanged: (v) => setState(() => _level = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Post Thread'),
            ),
          ],
        ),
      ),
    );
  }
}
