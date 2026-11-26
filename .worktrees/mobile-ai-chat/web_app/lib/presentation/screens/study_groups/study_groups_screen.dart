import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/auth_provider.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final discoverGroupsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, departmentId) async {
  final api = ref.read(apiClientProvider);
  final resp = await api.get(
    ApiConstants.studyGroups,
    params: departmentId.isNotEmpty ? {'departmentId': departmentId} : null,
  );
  final data = resp.data['data'] ?? resp.data;
  if (data is List) return data.cast<Map<String, dynamic>>();
  return [];
});

final myGroupsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final resp = await api.get(ApiConstants.studyGroupsMy);
  final data = resp.data['data'] ?? resp.data;
  if (data is List) return data.cast<Map<String, dynamic>>();
  return [];
});

// ── Screen ────────────────────────────────────────────────────────────────────

class StudyGroupsScreen extends ConsumerStatefulWidget {
  const StudyGroupsScreen({super.key});

  @override
  ConsumerState<StudyGroupsScreen> createState() => _StudyGroupsScreenState();
}

class _StudyGroupsScreenState extends ConsumerState<StudyGroupsScreen> {

  void _invalidateBoth() {
    final user = ref.read(currentUserProvider);
    ref.invalidate(discoverGroupsProvider(user?.departmentId ?? ''));
    ref.invalidate(myGroupsProvider);
  }

  Future<void> _joinGroup(String groupId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiConstants.joinStudyGroup(groupId));
      _invalidateBoth();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joined group successfully',
                style: TextStyle(fontFamily: 'Nunito')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = _extractError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: const TextStyle(fontFamily: 'Nunito')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _leaveGroup(String groupId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.delete(ApiConstants.leaveStudyGroup(groupId));
      _invalidateBoth();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Left group successfully',
                style: TextStyle(fontFamily: 'Nunito')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = _extractError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: const TextStyle(fontFamily: 'Nunito')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showCreateDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Create Study Group',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name *',
                  hintText: 'e.g. Aquaculture Study Circle',
                ),
                maxLength: 200,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Group name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'What will this group focus on?',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Nunito')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Create',
                style: TextStyle(fontFamily: 'Nunito')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiConstants.studyGroups, data: {
        'name': nameController.text.trim(),
        if (descController.text.trim().isNotEmpty)
          'description': descController.text.trim(),
      });
      _invalidateBoth();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Study group created',
                style: TextStyle(fontFamily: 'Nunito')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = _extractError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: const TextStyle(fontFamily: 'Nunito')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _extractError(Object e) {
    final str = e.toString();
    if (str.contains('409')) return 'You are already a member of this group';
    if (str.contains('403')) return 'This group is full or no longer active.';
    if (str.contains('404')) return 'This group no longer exists.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final departmentId = user?.departmentId ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Study Groups',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: const TabBar(
          indicatorColor: AppColors.cyanBright,
          labelColor: AppColors.cyanBright,
          unselectedLabelColor: AppColors.textOnDarkSub,
          labelStyle: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
          ),
          tabs: [
            Tab(text: 'Discover'),
            Tab(text: 'My Groups'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Create Study Group',
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        children: [
          // ── Discover tab ───────────────────────────────────────────────────
          _GroupListTab(
            asyncGroups: ref.watch(discoverGroupsProvider(departmentId)),
            myGroups: ref.watch(myGroupsProvider).asData?.value ?? [],
            onJoin: _joinGroup,
            onLeave: _leaveGroup,
            onRetry: () =>
                ref.invalidate(discoverGroupsProvider(departmentId)),
            emptyIcon: Icons.groups_outlined,
            emptyMessage: 'No study groups found for your department.',
          ),
          // ── My Groups tab ──────────────────────────────────────────────────
          _GroupListTab(
            asyncGroups: ref.watch(myGroupsProvider),
            myGroups: ref.watch(myGroupsProvider).asData?.value ?? [],
            onJoin: _joinGroup,
            onLeave: _leaveGroup,
            onRetry: () => ref.invalidate(myGroupsProvider),
            emptyIcon: Icons.groups_outlined,
            emptyMessage:
                'You have not joined any study groups yet.\nTap Discover to find one.',
            isMine: true,
          ),
        ],
      ),
      ),
    );
  }
}

// ── Group list tab ────────────────────────────────────────────────────────────

class _GroupListTab extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> asyncGroups;
  final List<Map<String, dynamic>> myGroups;
  final Future<void> Function(String) onJoin;
  final Future<void> Function(String) onLeave;
  final VoidCallback onRetry;
  final IconData emptyIcon;
  final String emptyMessage;
  final bool isMine;

  const _GroupListTab({
    required this.asyncGroups,
    required this.myGroups,
    required this.onJoin,
    required this.onLeave,
    required this.onRetry,
    required this.emptyIcon,
    required this.emptyMessage,
    this.isMine = false,
  });

  @override
  Widget build(BuildContext context) {
    return asyncGroups.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (_, __) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.border),
            const SizedBox(height: 12),
            const Text(
              'Could not load study groups. Check your connection and try again.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontFamily: 'Nunito'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry',
                  style: TextStyle(fontFamily: 'Nunito')),
            ),
          ],
        ),
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(emptyIcon,
                      size: 72,
                      color: AppColors.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontFamily: 'Nunito',
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final groupId = group['id']?.toString() ?? '';
            final isMember = isMine ||
                myGroups.any((g) => g['id']?.toString() == groupId);

            return _GroupCard(
              group: group,
              isMember: isMember,
              onJoin: () => onJoin(groupId),
              onLeave: () => onLeave(groupId),
            );
          },
        );
      },
    );
  }
}

// ── Group card ────────────────────────────────────────────────────────────────

class _GroupCard extends StatefulWidget {
  final Map<String, dynamic> group;
  final bool isMember;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  const _GroupCard({
    required this.group,
    required this.isMember,
    required this.onJoin,
    required this.onLeave,
  });

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _loading = false;

  Future<void> _handleAction() async {
    setState(() => _loading = true);
    try {
      if (widget.isMember) {
        await Future.microtask(widget.onLeave);
      } else {
        await Future.microtask(widget.onJoin);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.group['name']?.toString() ?? 'Study Group';
    final description = widget.group['description']?.toString() ?? '';
    final memberCount = widget.group['memberCount'] as int? ?? 0;
    final maxMembers = widget.group['maxMembers'] as int? ?? 50;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.groups_outlined,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                // Member count chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: AppColors.cyan),
                      const SizedBox(width: 4),
                      Text(
                        '$memberCount / $maxMembers',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cyan,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Join / Leave button
                SizedBox(
                  height: 34,
                  child: _loading
                      ? const SizedBox(
                          width: 80,
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary),
                            ),
                          ),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isMember
                                ? AppColors.error
                                : AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _handleAction,
                          child: Text(
                            widget.isMember ? 'Leave' : 'Join',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
