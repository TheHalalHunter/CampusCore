import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/auth_provider.dart';

// ── Data Models ───────────────────────────────────────────────────────────────

class _ConnectionItem {
  final String id;
  final String requesterId;
  final String receiverId;
  final String status;
  final String createdAt;

  const _ConnectionItem({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
  });

  factory _ConnectionItem.fromMap(Map<String, dynamic> map) {
    return _ConnectionItem(
      id:          map['id']?.toString()        ?? '',
      requesterId: map['requesterId']?.toString() ?? '',
      receiverId:  map['receiverId']?.toString()  ?? '',
      status:      map['status']?.toString()      ?? '',
      createdAt:   map['createdAt']?.toString()   ?? '',
    );
  }
}

class _UserProfile {
  final String id;
  final String fullName;
  final String? academicLevel;
  final String? role;
  final int reputationPoints;

  const _UserProfile({
    required this.id,
    required this.fullName,
    this.academicLevel,
    this.role,
    this.reputationPoints = 0,
  });

  factory _UserProfile.fromMap(Map<String, dynamic> map) {
    return _UserProfile(
      id:               map['id']?.toString()            ?? '',
      fullName:         map['fullName']?.toString()       ?? 'Unknown Student',
      academicLevel:    map['academicLevel']?.toString(),
      role:             map['role']?.toString(),
      reputationPoints: (map['reputationPoints'] as int?) ?? 0,
    );
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final a = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    final b = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0].toUpperCase() : '';
    return '$a$b';
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final connectionsProvider =
    FutureProvider.autoDispose<List<_ConnectionItem>>((ref) async {
  final api  = ref.read(apiClientProvider);
  final resp = await api.get(ApiConstants.connections);
  final data = resp.data['data'];
  if (data is List) {
    return data
        .cast<Map<String, dynamic>>()
        .map(_ConnectionItem.fromMap)
        .toList();
  }
  return [];
});

final pendingReceivedProvider =
    FutureProvider.autoDispose<List<_ConnectionItem>>((ref) async {
  final api  = ref.read(apiClientProvider);
  final resp = await api.get(ApiConstants.connectionsPendingReceived);
  final data = resp.data['data'];
  if (data is List) {
    return data
        .cast<Map<String, dynamic>>()
        .map(_ConnectionItem.fromMap)
        .toList();
  }
  return [];
});

final pendingSentProvider =
    FutureProvider.autoDispose<List<_ConnectionItem>>((ref) async {
  final api  = ref.read(apiClientProvider);
  final resp = await api.get(ApiConstants.connectionsPendingSent);
  final data = resp.data['data'];
  if (data is List) {
    return data
        .cast<Map<String, dynamic>>()
        .map(_ConnectionItem.fromMap)
        .toList();
  }
  return [];
});

final userProfileCacheProvider = FutureProvider.autoDispose
    .family<_UserProfile?, String>((ref, userId) async {
  if (userId.isEmpty) return null;
  try {
    final api  = ref.read(apiClientProvider);
    final resp = await api.get(ApiConstants.userProfile(userId));
    final data = resp.data['data'];
    if (data is Map<String, dynamic>) {
      return _UserProfile.fromMap(data);
    }
    return _UserProfile(id: userId, fullName: 'Unknown Student');
  } catch (_) {
    return _UserProfile(id: userId, fullName: 'Unknown Student');
  }
});

final _findStudentsProvider = FutureProvider.autoDispose
    .family<List<_UserProfile>, String>((ref, query) async {
  if (query.length < 2) return [];

  final results = <_UserProfile>[];
  final seen    = <String>{};

  // Strategy 1: filter accepted-connection peers by name
  try {
    final connections = await ref.read(connectionsProvider.future);
    final currentUser = ref.read(currentUserProvider);
    final lowerQuery  = query.toLowerCase();

    for (final conn in connections) {
      if (conn.status != 'accepted') continue;
      final peerId = conn.requesterId == currentUser?.id
          ? conn.receiverId
          : conn.requesterId;
      if (peerId.isEmpty || seen.contains(peerId)) continue;

      try {
        final profile =
            await ref.read(userProfileCacheProvider(peerId).future);
        if (profile != null &&
            profile.fullName.toLowerCase().contains(lowerQuery)) {
          results.add(profile);
          seen.add(peerId);
        }
      } catch (_) {}
    }
  } catch (_) {}

  // Strategy 2: optimistic — try user search endpoint if backend adds it
  try {
    final api  = ref.read(apiClientProvider);
    final resp = await api.get('/users/search', params: {'q': query});
    final data = resp.data['data'];
    if (data is List) {
      for (final item in data.cast<Map<String, dynamic>>()) {
        final p = _UserProfile.fromMap(item);
        if (p.id.isNotEmpty && !seen.contains(p.id)) {
          results.add(p);
          seen.add(p.id);
        }
      }
    }
  } catch (_) {
    // 404 or any error — silently ignore
  }

  return results;
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  final Map<String, bool> _actionLoading = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Action helpers ───────────────────────────────────────────────────────

  Future<void> _sendRequest(String receiverId) async {
    if (_actionLoading[receiverId] == true) return;
    setState(() => _actionLoading[receiverId] = true);
    try {
      final api  = ref.read(apiClientProvider);
      final resp = await api.post(ApiConstants.connectionRequest,
          data: {'receiverId': receiverId});
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        ref.invalidate(pendingSentProvider);
        ref.invalidate(connectionsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Connection request sent!',
                style: TextStyle(fontFamily: 'Nunito')),
            backgroundColor: AppColors.success,
          ));
        }
      } else {
        _showErrorSnackBar(body['message']?.toString() ?? 'Could not send request.');
      }
    } catch (e) {
      _showErrorSnackBar('Could not send request. Please try again.');
    } finally {
      if (mounted) setState(() => _actionLoading.remove(receiverId));
    }
  }

  Future<void> _acceptRequest(String connectionId) async {
    if (_actionLoading[connectionId] == true) return;
    setState(() => _actionLoading[connectionId] = true);
    try {
      final api  = ref.read(apiClientProvider);
      final resp = await api.patch(ApiConstants.connectionAccept(connectionId));
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        ref.invalidate(pendingReceivedProvider);
        ref.invalidate(connectionsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Connection accepted!',
                style: TextStyle(fontFamily: 'Nunito')),
            backgroundColor: AppColors.success,
          ));
        }
      } else {
        _showErrorSnackBar(body['message']?.toString() ?? 'Could not accept request.');
      }
    } catch (e) {
      _showErrorSnackBar('Could not accept request. Please try again.');
    } finally {
      if (mounted) setState(() => _actionLoading.remove(connectionId));
    }
  }

  Future<void> _removeConnection(String connectionId) async {
    if (_actionLoading[connectionId] == true) return;
    setState(() => _actionLoading[connectionId] = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.delete(ApiConstants.connectionRemove(connectionId));
      ref.invalidate(connectionsProvider);
      ref.invalidate(pendingReceivedProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Connection removed.',
              style: TextStyle(fontFamily: 'Nunito')),
          backgroundColor: AppColors.warning,
        ));
      }
    } catch (e) {
      _showErrorSnackBar('Could not remove connection. Please try again.');
    } finally {
      if (mounted) setState(() => _actionLoading.remove(connectionId));
    }
  }

  Future<void> _cancelRequest(String connectionId) async {
    if (_actionLoading[connectionId] == true) return;
    setState(() => _actionLoading[connectionId] = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.delete(ApiConstants.connectionRemove(connectionId));
      ref.invalidate(pendingSentProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Request cancelled.',
              style: TextStyle(fontFamily: 'Nunito')),
          backgroundColor: AppColors.warning,
        ));
      }
    } catch (e) {
      _showErrorSnackBar('Could not cancel request. Please try again.');
    } finally {
      if (mounted) setState(() => _actionLoading.remove(connectionId));
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontFamily: 'Nunito')),
      backgroundColor: AppColors.error,
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Connections'),
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.cyanBright,
          unselectedLabelColor: AppColors.textOnDarkSub,
          indicatorColor: AppColors.cyanBright,
          labelStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'My Connections'),
            Tab(
              child: _RequestsBadge(
                child: Text(
                  'Requests',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 13),
                ),
              ),
            ),
            Tab(text: 'Find Students'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyConnectionsTab(
            actionLoading: _actionLoading,
            onRemove: _removeConnection,
          ),
          _RequestsTab(
            actionLoading: _actionLoading,
            onAccept: _acceptRequest,
            onReject: _removeConnection,
            onCancel: _cancelRequest,
          ),
          _FindStudentsTab(
            searchCtrl: _searchCtrl,
            searchQuery: _searchQuery,
            onQueryChanged: (q) => setState(() => _searchQuery = q),
            onSendRequest: _sendRequest,
            actionLoading: _actionLoading,
          ),
        ],
      ),
    );
  }
}

// ── My Connections Tab ────────────────────────────────────────────────────────

class _MyConnectionsTab extends ConsumerWidget {
  final Map<String, bool> actionLoading;
  final Future<void> Function(String connectionId) onRemove;

  const _MyConnectionsTab({
    required this.actionLoading,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(connectionsProvider);
    final padding          = Responsive.getPaddingEdgeInsets(context);
    final currentUser      = ref.watch(currentUserProvider);

    return connectionsAsync.when(
      loading: () => const _ConnectionSkeleton(),
      error: (e, _) => _ConnErrorWidget(
        message: 'Could not load connections.',
        onRetry: () => ref.invalidate(connectionsProvider),
      ),
      data: (connections) {
        final accepted =
            connections.where((c) => c.status == 'accepted').toList();
        if (accepted.isEmpty) {
          return const _EmptyState(
            icon: Icons.people_outline,
            message: 'No connections yet. Find students to connect!',
          );
        }
        return ListView.separated(
          padding: padding,
          itemCount: accepted.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final conn   = accepted[i];
            final peerId = conn.requesterId == currentUser?.id
                ? conn.receiverId
                : conn.requesterId;
            return _ConnectionCard(
              connectionId: conn.id,
              peerId: peerId,
              actionLoading: actionLoading,
              actions: [
                _CardAction(
                  label: 'Remove',
                  style: _ActionStyle.destructive,
                  onPressed: () => onRemove(conn.id),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Requests Tab ──────────────────────────────────────────────────────────────

class _RequestsTab extends ConsumerWidget {
  final Map<String, bool> actionLoading;
  final Future<void> Function(String) onAccept;
  final Future<void> Function(String) onReject;
  final Future<void> Function(String) onCancel;

  const _RequestsTab({
    required this.actionLoading,
    required this.onAccept,
    required this.onReject,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receivedAsync = ref.watch(pendingReceivedProvider);
    final sentAsync     = ref.watch(pendingSentProvider);
    final padding       = Responsive.getPaddingEdgeInsets(context);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Received section
          const Text(
            'Received Requests',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          receivedAsync.when(
            loading: () => const _ConnectionSkeleton(count: 3),
            error: (e, _) => _ConnErrorWidget(
              message: 'Could not load received requests.',
              onRetry: () => ref.invalidate(pendingReceivedProvider),
            ),
            data: (received) {
              if (received.isEmpty) {
                return const _EmptyState(
                  icon: Icons.inbox_outlined,
                  message: 'No pending requests.',
                );
              }
              return Column(
                children: received
                    .map((conn) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ConnectionCard(
                            connectionId: conn.id,
                            peerId: conn.requesterId,
                            actionLoading: actionLoading,
                            actions: [
                              _CardAction(
                                label: 'Accept',
                                style: _ActionStyle.accept,
                                onPressed: () => onAccept(conn.id),
                              ),
                              _CardAction(
                                label: 'Reject',
                                style: _ActionStyle.destructive,
                                onPressed: () => onReject(conn.id),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // Sent section
          const Text(
            'Sent Requests',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          sentAsync.when(
            loading: () => const _ConnectionSkeleton(count: 3),
            error: (e, _) => _ConnErrorWidget(
              message: 'Could not load sent requests.',
              onRetry: () => ref.invalidate(pendingSentProvider),
            ),
            data: (sent) {
              if (sent.isEmpty) {
                return const _EmptyState(
                  icon: Icons.send_outlined,
                  message: 'No sent requests.',
                );
              }
              return Column(
                children: sent
                    .map((conn) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ConnectionCard(
                            connectionId: conn.id,
                            peerId: conn.receiverId,
                            actionLoading: actionLoading,
                            actions: [
                              _CardAction(
                                label: 'Cancel',
                                style: _ActionStyle.neutral,
                                onPressed: () => onCancel(conn.id),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Find Students Tab ─────────────────────────────────────────────────────────

class _FindStudentsTab extends ConsumerWidget {
  final TextEditingController searchCtrl;
  final String searchQuery;
  final ValueChanged<String> onQueryChanged;
  final Future<void> Function(String userId) onSendRequest;
  final Map<String, bool> actionLoading;

  const _FindStudentsTab({
    required this.searchCtrl,
    required this.searchQuery,
    required this.onQueryChanged,
    required this.onSendRequest,
    required this.actionLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padding        = Responsive.getPaddingEdgeInsets(context);
    final studentsAsync  = ref.watch(_findStudentsProvider(searchQuery));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Limitation notice
        Container(
          width: double.infinity,
          margin: EdgeInsets.fromLTRB(
              padding.left, padding.top, padding.right, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.info.withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline,
                  color: AppColors.info, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Student search is limited. You can find students you are already connected with, or try entering an exact name. A dedicated student search feature is coming soon.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search field
        Padding(
          padding: EdgeInsets.fromLTRB(
              padding.left, 12, padding.right, 12),
          child: TextField(
            controller: searchCtrl,
            onChanged: onQueryChanged,
            style: const TextStyle(fontFamily: 'Nunito'),
            decoration: const InputDecoration(
              hintText: 'Search by name…',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: AppColors.surfaceAlt,
            ),
          ),
        ),

        // Results
        Expanded(
          child: searchQuery.length < 2
              ? const Center(
                  child: Text(
                    'Enter a name to search for students.',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: AppColors.textHint,
                    ),
                  ),
                )
              : studentsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (e, _) => const Center(
                    child: Text(
                      'Could not search. Please try again.',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                  data: (students) {
                    if (students.isEmpty) {
                      return const _EmptyState(
                        icon: Icons.search_off_outlined,
                        message: 'No students found for that name.',
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.symmetric(
                          horizontal: padding.left),
                      itemCount: students.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final student = students[i];
                        return _ProfileCard(
                          profile: student,
                          actionLoading: actionLoading,
                          actions: [
                            _CardAction(
                              label: 'Connect',
                              style: _ActionStyle.primary,
                              onPressed: () =>
                                  onSendRequest(student.id),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Requests Badge ────────────────────────────────────────────────────────────

class _RequestsBadge extends ConsumerWidget {
  final Widget child;
  const _RequestsBadge({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receivedAsync = ref.watch(pendingReceivedProvider);
    final count = receivedAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    if (count == 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          right: -10,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Action model ──────────────────────────────────────────────────────────────

enum _ActionStyle { accept, destructive, neutral, primary }

class _CardAction {
  final String label;
  final _ActionStyle style;
  final VoidCallback onPressed;

  const _CardAction({
    required this.label,
    required this.style,
    required this.onPressed,
  });
}

// ── Connection Card (with profile fetch) ──────────────────────────────────────

class _ConnectionCard extends ConsumerWidget {
  final String connectionId;
  final String peerId;
  final Map<String, bool> actionLoading;
  final List<_CardAction> actions;

  const _ConnectionCard({
    required this.connectionId,
    required this.peerId,
    required this.actionLoading,
    required this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileCacheProvider(peerId));

    return profileAsync.when(
      loading: () => const Card(child: _SkeletonListTile()),
      error: (_, __) => const Card(
        child: ListTile(
          leading: CircleAvatar(child: Icon(Icons.person)),
          title: Text(
            'Unknown Student',
            style: TextStyle(fontFamily: 'Nunito'),
          ),
        ),
      ),
      data: (profile) => _ProfileCard(
        profile: profile ??
            _UserProfile(id: peerId, fullName: 'Unknown Student'),
        actionLoading: actionLoading,
        actionKey: connectionId,
        actions: actions,
      ),
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final _UserProfile profile;
  final Map<String, bool> actionLoading;
  final String? actionKey; // key in actionLoading map; defaults to profile.id
  final List<_CardAction> actions;

  const _ProfileCard({
    required this.profile,
    required this.actionLoading,
    required this.actions,
    this.actionKey,
  });

  @override
  Widget build(BuildContext context) {
    final key       = actionKey ?? profile.id;
    final isLoading = actionLoading[key] == true;
    final subtitle  = [
      if (profile.role != null && profile.role != 'student') profile.role,
      if (profile.academicLevel != null) profile.academicLevel,
    ].join(' · ');

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Text(
            profile.initials.isEmpty ? '?' : profile.initials,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        title: Text(
          profile.fullName,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : _ActionButtons(actions: actions),
      ),
    );
  }
}

// ── Action Buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final List<_CardAction> actions;
  const _ActionButtons({required this.actions});

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions.asMap().entries.map((entry) {
        final i      = entry.key;
        final action = entry.value;
        return Padding(
          padding: EdgeInsets.only(left: i > 0 ? 6 : 0),
          child: _buildButton(action),
        );
      }).toList(),
    );
  }

  Widget _buildButton(_CardAction action) {
    switch (action.style) {
      case _ActionStyle.accept:
        return SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: action.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(action.label),
          ),
        );
      case _ActionStyle.destructive:
        return SizedBox(
          height: 34,
          child: OutlinedButton(
            onPressed: action.onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(action.label),
          ),
        );
      case _ActionStyle.neutral:
        return SizedBox(
          height: 34,
          child: OutlinedButton(
            onPressed: action.onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(action.label),
          ),
        );
      case _ActionStyle.primary:
        return SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: action.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(action.label),
          ),
        );
    }
  }
}

// ── Skeleton Widgets ──────────────────────────────────────────────────────────

class _SkeletonListTile extends StatelessWidget {
  const _SkeletonListTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.surfaceAlt,
          shape: BoxShape.circle,
        ),
      ),
      title: Container(
          width: 120, height: 13, color: AppColors.surfaceAlt),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child:
            Container(width: 80, height: 11, color: AppColors.surfaceAlt),
      ),
    );
  }
}

class _ConnectionSkeleton extends StatelessWidget {
  final int count;
  const _ConnectionSkeleton({this.count = 5});

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.getPaddingEdgeInsets(context);
    return ListView.separated(
      padding: padding,
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => const Card(child: _SkeletonListTile()),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          Icon(icon, size: 64, color: AppColors.border),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: AppColors.textHint,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Error Widget ──────────────────────────────────────────────────────────────

class _ConnErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ConnErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.error_outline,
              color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry',
                style: TextStyle(fontFamily: 'Nunito')),
          ),
        ],
      ),
    );
  }
}
