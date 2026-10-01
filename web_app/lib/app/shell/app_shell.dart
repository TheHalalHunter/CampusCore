import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/providers/auth_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _sidebarExpanded = true;

  final List<({String label, String route, IconData icon})> _navItems = [
    (label: 'Home',      route: '/',          icon: Icons.home_outlined),
    (label: 'Courses',   route: '/courses',   icon: Icons.school_outlined),
    (label: 'Resources', route: '/resources', icon: Icons.library_books_outlined),
    (label: 'Community', route: '/community', icon: Icons.people_outlined),
    (label: 'Progress',  route: '/progress',  icon: Icons.trending_up_outlined),
    (label: 'AI Assist', route: '/ai',        icon: Icons.auto_awesome_outlined),
    (label: 'Profile',   route: '/profile',   icon: Icons.person_outlined),
  ];

  // Routes that show a "Soon" badge
  static const _comingSoonRoutes = {'/connections', '/notifications', '/leaderboard'};

  /// Derive selected index from the current route — survives browser refresh.
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

  @override
  Widget build(BuildContext context) {
    final isMobile  = Responsive.isMobile(context);
    final isTablet  = Responsive.isTablet(context);
    final location  = GoRouterState.of(context).matchedLocation;
    final selIndex  = _indexFromLocation(location);
    final user      = ref.watch(currentUserProvider);

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.navyDark,
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
            // Notifications bell with Coming Soon badge
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  tooltip: 'Notifications (Coming Soon)',
                  onPressed: () => context.go('/notifications'),
                ),
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Soon',
                        style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800, fontFamily: 'Nunito')),
                  ),
                ),
              ],
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
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.navyDark,
            border: Border(top: BorderSide(color: AppColors.navyMid, width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: selIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.navyDark,
            selectedItemColor: AppColors.cyanBright,
            unselectedItemColor: AppColors.textOnDarkSub,
            selectedLabelStyle: const TextStyle(
              fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 10,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Nunito', fontSize: 10,
            ),
            items: _navItems
                .map((item) => BottomNavigationBarItem(
                      icon: Icon(item.icon, size: 20),
                      label: item.label,
                    ))
                .toList(),
            onTap: (index) => context.go(_navItems[index].route),
          ),
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
                            leading: Icon(
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
