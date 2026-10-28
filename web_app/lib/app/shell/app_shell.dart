import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/providers/auth_provider.dart';
import '../../presentation/screens/notifications/notifications_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _sidebarExpanded = true;

  final List<({String label, String route, IconData icon})> _navItems = [
    (label: 'Home',          route: '/',               icon: Icons.home_outlined),
    (label: 'Courses',       route: '/courses',        icon: Icons.school_outlined),
    (label: 'Resources',     route: '/resources',      icon: Icons.library_books_outlined),
    (label: 'Community',     route: '/community',      icon: Icons.people_outlined),
    (label: 'Notifications', route: '/notifications',  icon: Icons.notifications_outlined),
    (label: 'Progress',      route: '/progress',       icon: Icons.trending_up_outlined),
    (label: 'AI Assist',     route: '/ai',             icon: Icons.auto_awesome_outlined),
    (label: 'Leaderboard',   route: '/leaderboard',    icon: Icons.leaderboard_outlined),
    (label: 'Library',       route: '/library',        icon: Icons.bookmark_outline),
    (label: 'Study Groups',  route: '/study-groups',   icon: Icons.groups_outlined),
    (label: 'Profile',       route: '/profile',        icon: Icons.person_outlined),
  ];

  // Primary nav items shown in bottom bar (mobile)
  final List<({String label, String route, IconData icon})> _bottomNavItems = [
    (label: 'Home',      route: '/',          icon: Icons.home_outlined),
    (label: 'Courses',   route: '/courses',   icon: Icons.school_outlined),
    (label: 'Community', route: '/community', icon: Icons.people_outlined),
    (label: 'AI Assist', route: '/ai',        icon: Icons.auto_awesome_outlined),
    (label: 'Profile',   route: '/profile',   icon: Icons.person_outlined),
  ];
  int _indexFromLocation(String location) {
    for (int i = _navItems.length - 1; i >= 0; i--) {
      if (_navItems[i].route == '/'
          ? location == '/'
          : location.startsWith(_navItems[i].route)) {
        return i;
      }
    }
    return 0;
  }

  int _bottomIndexFromLocation(String location) {
    for (int i = _bottomNavItems.length - 1; i >= 0; i--) {
      if (_bottomNavItems[i].route == '/'
          ? location == '/'
          : location.startsWith(_bottomNavItems[i].route)) {
        return i;
      }
    }
    return -1; // -1 means current page is not in bottom nav
  }

  @override
  Widget build(BuildContext context) {
    final isMobile  = Responsive.isMobile(context);
    final isTablet  = Responsive.isTablet(context);
    final location       = GoRouterState.of(context).matchedLocation;
    final selIndex       = _indexFromLocation(location);
    final bottomSelIndex = _bottomIndexFromLocation(location);
    final user           = ref.watch(currentUserProvider);

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.navyDark,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: RichText(
            text: const TextSpan(children: [
              TextSpan(
                text: 'Campus',
                style: TextStyle(
                  color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.w800, fontFamily: 'Nunito',
                ),
              ),
              TextSpan(
                text: 'Core',
                style: TextStyle(
                  color: AppColors.coreBlue, fontSize: 18,
                  fontWeight: FontWeight.w800, fontFamily: 'Nunito',
                ),
              ),
            ]),
          ),
          actions: [
            // Notifications bell with live unread badge
            Consumer(
              builder: (context, ref, _) {
                final count = ref
                    .watch(notifUnreadCountProvider)
                    .maybeWhen(data: (n) => n, orElse: () => 0);
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: Colors.white),
                      tooltip: 'Notifications',
                      onPressed: () => context.go('/notifications'),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          constraints: const BoxConstraints(
                              minWidth: 16, minHeight: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Nunito',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            IconButton(
              icon: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  user?.initials ?? 'ST',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              onPressed: () => context.go('/profile'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: widget.child,
        drawer: Drawer(
          backgroundColor: AppColors.navyMid,
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.navyDark,
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('C', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Nunito')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('CampusCore', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Nunito')),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    children: _navItems.map((item) {
                      final isSelected = location == item.route ||
                          (item.route != '/' && location.startsWith(item.route));
                      return ListTile(
                        leading: Icon(item.icon,
                            color: isSelected ? AppColors.cyanBright : AppColors.textOnDarkSub,
                            size: 20),
                        title: Text(item.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textOnDarkSub,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontFamily: 'Nunito', fontSize: 14,
                            )),
                        selected: isSelected,
                        selectedTileColor: AppColors.primary.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onTap: () {
                          Navigator.pop(context);
                          context.go(item.route);
                        },
                      );
                    }).toList(),
                  ),
                ),
                const Divider(color: Color(0x33FFFFFF), height: 1),
                ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(user?.initials ?? 'ST',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  title: Text(user?.fullName ?? 'Student',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
                  subtitle: Text(user?.email ?? '',
                      style: const TextStyle(color: AppColors.textOnDarkSub, fontSize: 11, fontFamily: 'Nunito'),
                      overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.logout_outlined, color: AppColors.textOnDarkSub, size: 18),
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmSignOut(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: bottomSelIndex < 0 ? 0 : bottomSelIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.navyDark,
          selectedItemColor: AppColors.cyanBright,
          unselectedItemColor: AppColors.textOnDarkSub,
          selectedLabelStyle: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 10),
          items: _bottomNavItems.map((item) => BottomNavigationBarItem(
            icon: Icon(item.icon, size: 22),
            label: item.label,
          )).toList(),
          onTap: (index) => context.go(_bottomNavItems[index].route),
        ),
      );
    }

    // ── Desktop / Tablet sidebar layout ──────────────────────────────────────
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: _sidebarExpanded ? (isTablet ? 200 : 260) : 72,
            decoration: const BoxDecoration(
              color: AppColors.navyMid,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Logo area
                Container(
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.navyDark,
                    border: Border(bottom: BorderSide(color: Color(0x22FFFFFF))),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('C',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Nunito',
                              )),
                        ),
                      ),
                      if (_sidebarExpanded) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            overflow: TextOverflow.ellipsis,
                            text: const TextSpan(children: [
                              TextSpan(
                                text: 'Campus',
                                style: TextStyle(
                                  color: Colors.white, fontSize: 15,
                                  fontWeight: FontWeight.w800, fontFamily: 'Nunito',
                                ),
                              ),
                              TextSpan(
                                text: 'Core',
                                style: TextStyle(
                                  color: AppColors.coreBlue, fontSize: 15,
                                  fontWeight: FontWeight.w800, fontFamily: 'Nunito',
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                      IconButton(
                        icon: Icon(
                          _sidebarExpanded
                              ? Icons.chevron_left
                              : Icons.chevron_right,
                          color: AppColors.textOnDarkSub,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () =>
                            setState(() => _sidebarExpanded = !_sidebarExpanded),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Nav items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: _navItems.length,
                    itemBuilder: (context, index) {
                      final item       = _navItems[index];
                      final isSelected = selIndex == index;
                      return Tooltip(
                        message: _sidebarExpanded ? '' : item.label,

                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: item.route == '/notifications'
                                ? _NotifBadge(
                                    child: Icon(
                                      item.icon,
                                      color: isSelected
                                          ? AppColors.cyanBright
                                          : AppColors.textOnDarkSub,
                                      size: 20,
                                    ),
                                  )
                                : Icon(
                                    item.icon,
                                    color: isSelected
                                        ? AppColors.cyanBright
                                        : AppColors.textOnDarkSub,
                                    size: 20,
                                  ),
                            title: _sidebarExpanded
                                ? Text(
                                    item.label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textOnDarkSub,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: isTablet ? 13 : 14,
                                      fontFamily: 'Nunito',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: _sidebarExpanded ? 12 : 8,
                              vertical: 2,
                            ),
                            minLeadingWidth: 0,
                            dense: true,
                            onTap: () => context.go(item.route),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Divider
                const Divider(color: Color(0x33FFFFFF), height: 1),

                // User profile
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _sidebarExpanded
                      ? Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                user?.initials ?? 'ST',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.fullName ?? 'Student',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Nunito',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    user?.email ?? '',
                                    style: const TextStyle(
                                      color: AppColors.textOnDarkSub,
                                      fontSize: 10,
                                      fontFamily: 'Nunito',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                      icon: const Icon(Icons.logout_outlined,
                          color: AppColors.textOnDarkSub, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Sign out',
                      onPressed: () => _confirmSignOut(context),
                    ),
                          ],
                        )
                      : GestureDetector(
                          onTap: () => _showUserMenu(context),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              user?.initials ?? 'ST',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context) {
    final user = ref.read(currentUserProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user?.fullName ?? 'Student'),
        content: Text(user?.email ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmSignOut(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will be taken back to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ── Notification badge overlay for sidebar icon ───────────────────────────────

class _NotifBadge extends ConsumerWidget {
  final Widget child;
  const _NotifBadge({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref
        .watch(notifUnreadCountProvider)
        .maybeWhen(data: (n) => n, orElse: () => 0);
    if (count == 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          right: -6,
          child: Container(
            constraints:
                const BoxConstraints(minWidth: 16, minHeight: 16),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                fontFamily: 'Nunito',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
