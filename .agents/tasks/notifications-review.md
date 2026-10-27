# Notifications screen for CampusCore web app

The change upgrades the `/notifications` route from a `ComingSoonScreen` placeholder to a fully functional notifications screen. It adds a `NotificationsScreen` with All/Unread tab filtering, per-type icon dispatch, relative timestamps, tap-to-mark-read, mark-all-as-read, loading skeleton, empty state, and error state. The `app_shell.dart` is updated to show a live unread count badge on both the sidebar icon and the mobile AppBar bell. Three new `ApiConstants` entries back the network calls. `flutter analyze` reports zero issues and the release build produces an artefact successfully.

**Watch for:** `notifUnreadCountProvider` hits a separate `/notifications/unread-count` endpoint rather than deriving the count from the already-fetched list — two network requests per load and a stale-count risk when the two endpoints diverge. The tap-to-mark-read path silently swallows errors, leaving the UI in a visually inconsistent state. The `unreadCount` constant name deviates from the `notifications`/`notificationsReadAll`/`markNotificationRead` naming pattern.

**Verdict**: APPROVED

---

## High-level view

All required UI features are present and structurally correct. The tab controller, skeleton, empty state, error state, unread tint, unread dot, per-type icons, and relative timestamps all land in this diff. Provider scoping is correct: `notificationsProvider` and `notifUnreadCountProvider` are file-level declarations, not nested in a class, so `app_shell.dart` can import and watch them without circular dependencies.

The `app_shell.dart` changes cover both form factors correctly. The sidebar wraps the Notifications icon in `_NotifBadge` (a `ConsumerWidget` watching `notifUnreadCountProvider`). The mobile AppBar replaces the former 'Soon' text badge with a `Consumer` rendering the live count with identical styling. No hardcoded hex values appear in either file.

The unread count is fetched from a dedicated backend endpoint rather than derived from the already-loaded notifications list. This introduces a double-fetch on every page load and a window where the badge count can disagree with what the list actually shows — for example, immediately after a tap-to-read invalidates `notificationsProvider` but `notifUnreadCountProvider` hasn't revalidated yet.

The tap-to-mark-read handler catches all errors and discards them silently. This means a network failure leaves the row visually unread (dot still visible, background tinted) with no feedback. Mark-all-as-read has the opposite treatment: it shows a SnackBar on both success and failure, which is the better pattern for mutation operations.


<details>
<summary>Issues (3)</summary>

1. **Double-fetch unread count** � `notifUnreadCountProvider` calls `/notifications/unread-count` independently of `notificationsProvider`. After any read mutation both providers are invalidated, but between invalidation and revalidation the badge and the list count can diverge. Consider deriving the count from `notificationsProvider`'s data (`ref.watch(notificationsProvider).maybeWhen(data: (l) => l.where((n) => !n.isRead).length, orElse: () => 0)`) to eliminate the second endpoint and the drift window. Confidence: confirmed.

2. **Silent tap-to-mark-read failure** � `_NotificationTile.onTap` catches all exceptions with `catch (_) {}` and does nothing. A network error leaves the tile looking unread (dot visible, background tinted) with no user feedback. Add a SnackBar or brief error indicator matching the pattern already used in `_markAllRead`. Confidence: confirmed.

3. **Inconsistent ApiConstants naming** � The three new constants follow two patterns: `notifications`, `notificationsReadAll`, `markNotificationRead(id)` are self-consistent, but the unread-count entry is named `unreadCount` rather than `notificationsUnreadCount`. This is a minor style issue but will cause confusion when scanning the class alongside the connections constants. Confidence: confirmed.

</details>

<details>
<summary>Details</summary>

### Double-fetch and stale-badge window

`notifUnreadCountProvider` is a separate `FutureProvider.autoDispose` that calls `/notifications/unread-count`. Every time the screen is entered, two HTTP requests go out in parallel. The providers are both invalidated after `_markAllRead` and after tap-to-read � but because `autoDispose` tears them down on navigation and rebuilds them on re-entry, the badge in `app_shell.dart` (which persists across navigation) will keep the last-seen count until both providers revalidate. The safer design is to watch `notificationsProvider` and count locally, making the badge count definitionally consistent with the rendered list.

### Tap-to-mark-read failure mode

```dart
try {
  await api.patch(ApiConstants.markNotificationRead(notification.id));
  ref.invalidate(notificationsProvider);
  ref.invalidate(notifUnreadCountProvider);
} catch (_) {
  // silently ignore tap-to-read errors
}
```

On a transient network error the tile stays tinted and dotted. The user has no way to know the read-mark failed and may tap again (harmless) or assume the item is already processed (incorrect). A brief SnackBar on failure would align this path with `_markAllRead`.



</details>

---

<details>
<summary>File map</summary>

| File | Change |
|---|---|
| `web_app/lib/presentation/screens/notifications/notifications_screen.dart` | New file � full notifications screen implementation |
| `web_app/lib/app/shell/app_shell.dart` | Added Notifications to nav, live badge on sidebar and mobile bell |
| `web_app/lib/app/router/app_router.dart` | `/notifications` route points to `NotificationsScreen` |
| `web_app/lib/core/constants/api_constants.dart` | Added 4 notification endpoint constants |

</details>
