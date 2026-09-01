import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/notification_model.dart';
import '../../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(markAllReadProvider.notifier).markAll();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load notifications.')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.notifications_none, size: 56, color: AppColors.grey400),
                SizedBox(height: 16),
                Text('No notifications yet',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                SizedBox(height: 8),
                Text('You\'ll be notified about uploads, answers and more.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary)),
              ]),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
            color: AppColors.primary,
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _NotificationTile(
                notification: notifications[i],
                onTap: () async {
                  if (!notifications[i].isRead) {
                    await ref
                        .read(markReadProvider.notifier)
                        .markRead(notifications[i].id);
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(unreadCountProvider);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Notification tile ────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final info = _typeInfo(notification.type);
    return ListTile(
      tileColor: notification.isRead ? null : AppColors.primary.withOpacity(0.04),
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: info.color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(info.icon, color: info.color, size: 20),
      ),
      title: Text(notification.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(_timeAgo(notification.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        ],
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle)),
      isThreeLine: true,
    );
  }

  _TypeInfo _typeInfo(String type) {
    switch (type) {
      case 'upload_approved':
        return _TypeInfo(Icons.check_circle_outline, AppColors.success);
      case 'upload_rejected':
        return _TypeInfo(Icons.cancel_outlined, AppColors.error);
      case 'question_answered':
        return _TypeInfo(Icons.question_answer_outlined, AppColors.info);
      case 'answer_verified':
        return _TypeInfo(Icons.verified_outlined, AppColors.success);
      case 'new_resource':
        return _TypeInfo(Icons.upload_file_outlined, AppColors.accent);
      case 'badge_earned':
        return _TypeInfo(Icons.military_tech_outlined, AppColors.accent);
      case 'announcement':
        return _TypeInfo(Icons.campaign_outlined, AppColors.warning);
      default:
        return _TypeInfo(Icons.notifications_outlined, AppColors.primary);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class _TypeInfo {
  final IconData icon;
  final Color color;
  const _TypeInfo(this.icon, this.color);
}

// ─── Mark read providers ──────────────────────────────────────────────────────

final markReadProvider =
    NotifierProvider<MarkReadNotifier, void>(MarkReadNotifier.new);

class MarkReadNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> markRead(String id) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.patch('/notifications/$id/read');
    } catch (_) {}
  }
}

final markAllReadProvider =
    NotifierProvider<MarkAllReadNotifier, void>(MarkAllReadNotifier.new);

class MarkAllReadNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> markAll() async {
    try {
      final api = ref.read(apiClientProvider);
      await api.patch('/notifications/read-all');
    } catch (_) {}
  }
}
