import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class _Notification {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const _Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory _Notification.fromMap(Map<String, dynamic> map) {
    return _Notification(
      id:        map['id']?.toString()    ?? '',
      title:     map['title']?.toString() ?? '',
      body:      map['body']?.toString()  ?? '',
      type:      map['type']?.toString()  ?? '',
      isRead:    map['isRead'] as bool?   ?? false,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60)  return 'Just now';
  if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
  if (diff.inHours   < 24)  return '${diff.inHours}h ago';
  if (diff.inDays    < 7)   return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

({IconData icon, Color color}) _typeIcon(String type) {
  switch (type) {
    case 'upload_approved':
      return (icon: Icons.check_circle_outline,    color: AppColors.success);
    case 'upload_rejected':
      return (icon: Icons.cancel_outlined,         color: AppColors.error);
    case 'question_answered':
      return (icon: Icons.question_answer_outlined, color: AppColors.info);
    case 'answer_verified':
      return (icon: Icons.verified_outlined,        color: AppColors.success);
    case 'new_resource':
      return (icon: Icons.library_books_outlined,   color: AppColors.primary);
    case 'badge_earned':
      return (icon: Icons.emoji_events_outlined,    color: AppColors.warning);
    case 'announcement':
      return (icon: Icons.campaign_outlined,        color: AppColors.warning);
    case 'study_reminder':
      return (icon: Icons.alarm_outlined,           color: AppColors.primaryLight);
    case 'new_discussion':
      return (icon: Icons.forum_outlined,           color: AppColors.coreBlue);
    default:
      return (icon: Icons.notifications_outlined,   color: AppColors.textHint);
  }
}

// ── Providers (exported so app_shell.dart can import them) ────────────────────

final notificationsProvider =
    FutureProvider.autoDispose<List<_Notification>>((ref) async {
  final api  = ref.read(apiClientProvider);
  final resp = await api.get(ApiConstants.notifications);
  final data = resp.data['data'];
  if (data is List) {
    final list = data
        .cast<Map<String, dynamic>>()
        .map(_Notification.fromMap)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
  return [];
});

final notifUnreadCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final api  = ref.read(apiClientProvider);
  final resp = await api.get(ApiConstants.unreadCount);
  final data = resp.data['data'];
  if (data is num) return data.toInt();
  if (data is Map) return (data['count'] as num?)?.toInt() ?? 0;
  return 0;
});

// ── Screen ────────────────────────────────────────────────────────────────────

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _markingAll = false;

  Future<void> _markAllRead() async {
    if (_markingAll) return;
    setState(() => _markingAll = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.patch(ApiConstants.notificationsReadAll);
      ref.invalidate(notificationsProvider);
      ref.invalidate(notifUnreadCountProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read.',
                style: TextStyle(fontFamily: 'Nunito')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not mark all as read. Please try again.',
                style: TextStyle(fontFamily: 'Nunito')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadAsync = ref.watch(notifUnreadCountProvider);
    final unreadCount = unreadAsync.maybeWhen(data: (n) => n, orElse: () => 0);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: AppColors.navyDark,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (_markingAll)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: _markAllRead,
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(width: 4),
          ],
          bottom: TabBar(
            labelColor: AppColors.cyanBright,
            unselectedLabelColor: AppColors.textOnDarkSub,
            indicatorColor: AppColors.cyanBright,
            labelStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            tabs: [
              const Tab(text: 'All'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Unread',
                        style: TextStyle(fontFamily: 'Nunito', fontSize: 13)),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _NotificationsList(showUnreadOnly: false),
            _NotificationsList(showUnreadOnly: true),
          ],
        ),
      ),
    );
  }
}

// ── Notifications List ────────────────────────────────────────────────────────

class _NotificationsList extends ConsumerWidget {
  final bool showUnreadOnly;
  const _NotificationsList({required this.showUnreadOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(notificationsProvider);
        ref.invalidate(notifUnreadCountProvider);
        await ref.read(notificationsProvider.future);
      },
      child: notifAsync.when(
        loading: () => const _NotificationSkeleton(),
        error: (e, _) => _ErrorState(
          message: 'Could not load notifications.',
          onRetry: () {
            ref.invalidate(notificationsProvider);
            ref.invalidate(notifUnreadCountProvider);
          },
        ),
        data: (all) {
          final items = showUnreadOnly
              ? all.where((n) => !n.isRead).toList()
              : all;
          if (items.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppColors.border, height: 1),
            itemBuilder: (ctx, i) => _NotificationTile(
              notification: items[i],
            ),
          );
        },
      ),
    );
  }
}

// ── Notification Tile ─────────────────────────────────────────────────────────

class _NotificationTile extends ConsumerWidget {
  final _Notification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeInfo = _typeIcon(notification.type);

    return InkWell(
      onTap: () async {
        if (!notification.isRead) {
          try {
            final api = ref.read(apiClientProvider);
            await api.patch(
                ApiConstants.markNotificationRead(notification.id));
            ref.invalidate(notificationsProvider);
            ref.invalidate(notifUnreadCountProvider);
          } catch (_) {
            // silently ignore tap-to-read errors
          }
        }
      },
      child: Container(
        color: notification.isRead
            ? null
            : AppColors.primary.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading icon
            CircleAvatar(
              radius: 20,
              backgroundColor: typeInfo.color.withValues(alpha: 0.15),
              child: Icon(typeInfo.icon, color: typeInfo.color, size: 18),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),

            // Unread dot
            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: SizedBox(
                  width: 8,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _NotificationSkeleton extends StatefulWidget {
  const _NotificationSkeleton();

  @override
  State<_NotificationSkeleton> createState() => _NotificationSkeletonState();
}

class _NotificationSkeletonState extends State<_NotificationSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 6,
        separatorBuilder: (_, __) =>
            const Divider(color: AppColors.border, height: 1),
        itemBuilder: (_, i) => Opacity(
          opacity: _opacity.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.grey200,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 13,
                        width: (i % 2 == 0) ? 200 : 160,
                        decoration: BoxDecoration(
                          color: AppColors.grey200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 11,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 11,
                        width: (i % 3 == 0) ? 240 : 180,
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "You'll be notified about uploads, answers and more.",
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry',
                  style: TextStyle(fontFamily: 'Nunito')),
            ),
          ],
        ),
      ),
    );
  }
}
