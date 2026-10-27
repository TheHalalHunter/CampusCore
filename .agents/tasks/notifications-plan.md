# Implementation Plan — Notifications Screen (Web App)

## Context from Exploration

**Packages confirmed in `web_app/pubspec.yaml`:**
- `intl: ^0.19.0` — available, use `DateFormat` for timestamps
- No `shimmer` package — use a manually-animated skeleton (animated `Container` with `AnimationController` + opacity pulse, same pattern used by `_ConnectionSkeleton` in connections_screen.dart)
- No `timeago` package — implement a `_timeAgo(DateTime)` helper function (same approach as mobile app's notifications screen)

**API response shape (confirmed from backend service + mobile model):**
- `GET /notifications` → `{ success, data: [ { id, userId, title, body, type, relatedId, isRead, createdAt } ] }`
- `GET /notifications/unread-count` → `{ success, data: <number> }` (service returns `Promise<number>`, wrapped by `ResponseInterceptor`)
- `PATCH /notifications/:id/read` → no body needed, returns wrapped void
- `PATCH /notifications/read-all` → no body needed, returns wrapped void

**Key decisions:**
1. `unreadCountProvider` defined as `FutureProvider.autoDispose<int>` **inside** `notifications_screen.dart` and imported into `app_shell.dart`. This keeps providers co-located with their screen, matching the pattern used by `connectionsProvider` in connections_screen.dart.
2. No shimmer package — skeleton uses `AnimatedOpacity` pulsing between 0.3–1.0 via `AnimationController`. Matches existing project style (no external animation packages used in web_app).
3. Relative timestamp implemented as a standalone `_timeAgo(DateTime)` top-level function, no package needed.
4. Notifications added to `_navItems` in `app_shell.dart` (between Profile and existing items, specifically after Community) with a `Stack`-wrapped icon showing a badge. This is consistent with how `_RequestsBadge` works in connections_screen.dart.
5. `/notifications` removed from `_comingSoonRoutes` set in app_shell.dart.
6. The unread badge in the sidebar uses `ref.watch(unreadCountProvider)` with `.maybeWhen(data: …, orElse: () => 0)` — identical to `_RequestsBadge` pattern.

---

## Steps

- [ ] 1. Add missing notification constants to `api_constants.dart`.
      Add three new entries to the Notifications section: `notifications`, `notificationsReadAll`, and `markNotificationRead(String id)`.
      Files: `web_app/lib/core/constants/api_constants.dart`
      Verify: `flutter analyze web_app` — no errors on this file.

- [ ] 2. Create the `NotificationsScreen` in a new file.
      Create `web_app/lib/presentation/screens/notifications/notifications_screen.dart`.
      The file contains, in order:
      
      **Top-level model:**
      ```dart
      class _Notification {
        final String id, title, body, type;
        final bool isRead;
        final DateTime createdAt;
        // constructor + fromMap factory
      }
      ```
      Parse `isRead` as `json['isRead'] as bool? ?? false` and `createdAt` via `DateTime.tryParse(...)  ?? DateTime.now()`.

      **Top-level providers (both `FutureProvider.autoDispose`):**
      ```dart
      final notificationsProvider = FutureProvider.autoDispose<List<_Notification>>((ref) async { ... });
      final unreadCountProvider   = FutureProvider.autoDispose<int>((ref) async { ... });
      ```
      `notificationsProvider` calls `GET ApiConstants.notifications`, reads `resp.data['data']`, casts to `List`, maps to `_Notification.fromMap`, sorts descending by `createdAt`.
      `unreadCountProvider` calls `GET ApiConstants.unreadCount`, reads `resp.data['data']` as `num`, returns `.toInt()`.

      **`NotificationsScreen` widget (`ConsumerStatefulWidget`):**
      - Uses `DefaultTabController(length: 2)` wrapping a `Scaffold`.
      - `AppBar` title `'Notifications'`, `backgroundColor: AppColors.navyDark`, `foregroundColor: Colors.white`.
      - `AppBar.actions`: a `TextButton` labelled `'Mark all as read'` that calls `PATCH ApiConstants.notificationsReadAll` then `ref.invalidate` on both providers.
      - `AppBar.bottom`: a `TabBar` with two tabs:
        - Tab 0: `Text('All')`
        - Tab 1: a `Stack` showing `Text('Unread')` with a small red count badge positioned top-right (only visible when count > 0, using `unreadCountProvider.maybeWhen`).
      - `body`: `TabBarView` with two children:
        - All tab: watches `notificationsProvider`, shows loading skeleton / error+retry / empty state / list of all notifications.
        - Unread tab: same provider, but `.where((n) => !n.isRead)` filtered in the widget, same states.
      - Pull-to-refresh: wrap the list in `RefreshIndicator` that `ref.invalidate`s both providers.

      **`_NotificationTile` (`StatelessWidget`):**
      - Background: `notification.isRead ? null : AppColors.primary.withValues(alpha: 0.06)` (tinted row for unread).
      - Leading: circular container with icon + color from `_typeIcon(type)` helper.
      - Title: `Text(notification.title)` bold (`fontWeight: FontWeight.w700`).
      - Subtitle: `notification.body` + `_timeAgo(notification.createdAt)`.
      - Trailing: unread blue dot `Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))` — hidden when `isRead`.
      - `onTap`: async; if `!isRead`, calls `PATCH ApiConstants.markNotificationRead(id)` then `ref.invalidate` both providers.

      **`_typeIcon(String type)` helper** — returns `({IconData icon, Color color})`:
      | type | icon | color |
      |---|---|---|
      | `upload_approved` | `Icons.check_circle_outline` | `AppColors.success` |
      | `upload_rejected` | `Icons.cancel_outlined` | `AppColors.error` |
      | `question_answered` | `Icons.question_answer_outlined` | `AppColors.info` |
      | `answer_verified` | `Icons.verified_outlined` | `AppColors.success` |
      | `new_resource` | `Icons.upload_file_outlined` | `AppColors.accent` |
      | `badge_earned` | `Icons.military_tech_outlined` | `AppColors.accent` |
      | `announcement` | `Icons.campaign_outlined` | `AppColors.warning` |
      | `study_reminder` | `Icons.alarm_outlined` | `AppColors.primary` |
      | `new_discussion` | `Icons.forum_outlined` | `AppColors.coreBlue` |
      | default | `Icons.notifications_outlined` | `AppColors.primary` |

      **`_timeAgo(DateTime dt)` top-level function:**
      ```dart
      String _timeAgo(DateTime dt) {
        final diff = DateTime.now().difference(dt);
        if (diff.inSeconds < 60) return 'Just now';
        if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
        if (diff.inHours < 24) return '${diff.inHours}h ago';
        if (diff.inDays < 7) return '${diff.inDays}d ago';
        return '${(diff.inDays / 7).floor()}w ago';
      }
      ```

      **`_NotificationSkeleton` (`StatefulWidget`):**
      Uses a single `AnimationController(duration: 800ms)` with `repeat(reverse: true)`, drives an `AnimatedBuilder` that pulses `opacity` between 0.3 and 1.0 on grey `Container` rows (icon circle + two text bars per row, 6 rows total).

      **Empty state:** centered `Icons.notifications_none` (size 64, `AppColors.grey400`) + `'No notifications yet'` text + subtitle `'You\'ll be notified about uploads, answers and more.'`

      **Error state:** centered `Icons.error_outline` + error message text + `TextButton('Retry', onPressed: () => ref.invalidate(notificationsProvider))`.

      Files: `web_app/lib/presentation/screens/notifications/notifications_screen.dart` (new file)
      Verify: `flutter analyze web_app` — zero errors in this file.

- [ ] 3. Update `app_router.dart` — wire `/notifications` to `NotificationsScreen`.
      - Add import: `import '../../presentation/screens/notifications/notifications_screen.dart';`
      - In the `/notifications` `GoRoute`, replace `ComingSoonScreen(...)` with `const NotificationsScreen()`.
      - Keep the `/leaderboard` route unchanged (still uses `ComingSoonScreen`).
      - Keep the `coming_soon_screen.dart` import (still needed for leaderboard).
      
      Files: `web_app/lib/app/router/app_router.dart`
      Verify: `flutter analyze web_app` — no errors; hot-reload confirms `/notifications` navigates to `NotificationsScreen`.

- [ ] 4. Update `app_shell.dart` — add Notifications to sidebar nav + real unread badge.
      
      **Import:** add at top:
      ```dart
      import '../../presentation/screens/notifications/notifications_screen.dart';
      ```

      **`_navItems` list:** insert `(label: 'Notifications', route: '/notifications', icon: Icons.notifications_outlined)` — insert it **after** `'Community'` and **before** `'Progress'`, so the order becomes: Home, Courses, Resources, Community, **Notifications**, Progress, AI Assist, Profile. This keeps notification logically adjacent to community (social features cluster).

      **`_comingSoonRoutes`:** remove `'/notifications'` from the set. It now reads:
      ```dart
      static const _comingSoonRoutes = {'/leaderboard'};
      ```
      (connections was already live, notifications is now live, only leaderboard remains)

      **Sidebar nav item rendering** — in the `ListView.builder` for `_navItems`, check if `item.route == '/notifications'`. When true, wrap the `ListTile`'s `leading` icon in a `Stack` with a small badge overlay:
      ```dart
      leading: item.route == '/notifications'
          ? _NotifBadge(child: Icon(item.icon, color: ..., size: 20))
          : Icon(item.icon, color: ..., size: 20),
      ```
      Add a private `_NotifBadge extends ConsumerWidget` at the bottom of the file:
      ```dart
      class _NotifBadge extends ConsumerWidget {
        final Widget child;
        const _NotifBadge({required this.child, super.key});
        @override
        Widget build(BuildContext context, WidgetRef ref) {
          final count = ref.watch(unreadCountProvider).maybeWhen(
            data: (n) => n, orElse: () => 0);
          if (count == 0) return child;
          return Stack(clipBehavior: Clip.none, children: [
            child,
            Positioned(
              top: -4, right: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 9,
                    fontWeight: FontWeight.w800, fontFamily: 'Nunito'),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ]);
        }
      }
      ```

      **Mobile AppBar notifications bell** — replace the current hardcoded 'Soon' badge block with:
      ```dart
      Consumer(builder: (context, ref, _) {
        final count = ref.watch(unreadCountProvider).maybeWhen(
          data: (n) => n, orElse: () => 0);
        return Stack(children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'Notifications',
            onPressed: () => context.go('/notifications'),
          ),
          if (count > 0)
            Positioned(
              right: 8, top: 8,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 9,
                    fontWeight: FontWeight.w800, fontFamily: 'Nunito'),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ]);
      }),
      ```

      Note: `Consumer` is needed inside `actions` list because `_AppShellState` is already a `ConsumerStatefulWidget`, so `ref.watch` can alternatively be used directly in the build method — the implementer may use either approach. Using `ref.watch(unreadCountProvider)` directly in `_AppShellState.build` and passing the count down is cleaner; the inline `Consumer` is also valid.

      Files: `web_app/lib/app/shell/app_shell.dart`
      Verify: `flutter analyze web_app` — zero errors; sidebar shows Notifications item; mobile AppBar shows numeric badge when unread count > 0.

- [ ] 5. Final build verification.
      Run `flutter analyze web_app` — confirm zero errors across all changed files. Run `flutter build web --web-renderer canvaskit` (or `html`) from the `web_app` directory to confirm the app compiles cleanly. No test suite exists for the Flutter web app, so a clean build + analyze is the verification gate.
      Files: none (verification only)
      Verify: `flutter analyze web_app` exits with no errors; `flutter build web` completes without compilation errors.

---

## File Summary

| Action | File |
|--------|------|
| Modify | `web_app/lib/core/constants/api_constants.dart` |
| Create | `web_app/lib/presentation/screens/notifications/notifications_screen.dart` |
| Modify | `web_app/lib/app/router/app_router.dart` |
| Modify | `web_app/lib/app/shell/app_shell.dart` |

## Dependency Order

Steps 1 and 2 are independent of each other but both must complete before steps 3 and 4 (router and shell import from the new screen). Step 5 depends on all prior steps.
