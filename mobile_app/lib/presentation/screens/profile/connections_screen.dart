import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/router/app_router.dart';
import '../../providers/connections_provider.dart';

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Connections'),
          bottom: const TabBar(tabs: [
            Tab(text: 'My Connections'),
            Tab(text: 'Pending'),
          ]),
        ),
        body: const TabBarView(children: [
          _ConnectionsTab(),
          _PendingTab(),
        ]),
      ),
    );
  }
}

// ─── My Connections tab ───────────────────────────────────────────────────────

class _ConnectionsTab extends ConsumerWidget {
  const _ConnectionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(connectionsProvider);

    return connectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Could not load connections.')),
      data: (connections) {
        if (connections.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.people_outline, size: 56, color: AppColors.grey400),
              SizedBox(height: 16),
              Text('No connections yet',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              SizedBox(height: 8),
              Text('Browse profiles and connect with fellow students.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)),
            ]),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: connections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final c = connections[i];
            return _ConnectionTile(connection: c);
          },
        );
      },
    );
  }
}

// ─── Pending requests tab ─────────────────────────────────────────────────────

class _PendingTab extends ConsumerWidget {
  const _PendingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingRequestsProvider);

    return pendingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Could not load requests.')),
      data: (pending) {
        if (pending.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.mark_email_unread_outlined, size: 56, color: AppColors.grey400),
              SizedBox(height: 16),
              Text('No pending requests',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              SizedBox(height: 8),
              Text('Connection requests you receive will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)),
            ]),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pending.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final c = pending[i];
            return _PendingTile(connection: c);
          },
        );
      },
    );
  }
}

// ─── Connection tile ──────────────────────────────────────────────────────────

class _ConnectionTile extends ConsumerWidget {
  final ConnectionModel connection;
  const _ConnectionTile({required this.connection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserId = connection.requesterId == connection.receiverId
        ? connection.receiverId
        : connection.requesterId;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.15),
          child: const Icon(Icons.person_outline, color: AppColors.primary),
        ),
        title: Text('User',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Connected • ${_timeAgo(connection.createdAt)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          TextButton(
            onPressed: () => context.push('${AppRoutes.publicProfile}/$otherUserId'),
            child: const Text('View'),
          ),
          IconButton(
            icon: const Icon(Icons.person_remove_outlined,
                size: 18, color: AppColors.error),
            tooltip: 'Remove',
            onPressed: () => _remove(context, ref, connection),
          ),
        ]),
      ),
    );
  }

  Future<void> _remove(BuildContext ctx, WidgetRef ref, ConnectionModel c) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Remove Connection'),
        content: const Text('Are you sure you want to remove this connection?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(connectionActionsProvider.notifier)
        .removeConnection(c.id, c.requesterId);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'just now';
  }
}

// ─── Pending request tile ─────────────────────────────────────────────────────

class _PendingTile extends ConsumerWidget {
  final ConnectionModel connection;
  const _PendingTile({required this.connection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(connectionActionsProvider) is AsyncLoading;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.warning.withOpacity(0.15),
          child: const Icon(Icons.person_add_outlined, color: AppColors.warning),
        ),
        title: Text('Connection Request',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(_timeAgo(connection.createdAt),
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          ElevatedButton(
            onPressed: isLoading ? null : () async {
              final ok = await ref.read(connectionActionsProvider.notifier)
                  .acceptRequest(connection.id, connection.requesterId);
              if (context.mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Connection accepted!'),
                  backgroundColor: AppColors.success,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Accept', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 6),
          OutlinedButton(
            onPressed: isLoading ? null : () async {
              await ref.read(connectionActionsProvider.notifier)
                  .removeConnection(connection.id, connection.requesterId);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            child: const Text('Decline', style: TextStyle(fontSize: 12)),
          ),
        ]),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'just now';
  }
}
