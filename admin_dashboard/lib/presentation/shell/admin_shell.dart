import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/admin_router.dart';
import '../../app/theme/admin_theme.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Persistent left sidebar
          _AdminSidebar(),
          // Main content area
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final _navItems = const [
    _NavItem(icon: Icons.dashboard_outlined,   label: 'Dashboard',   route: AdminRoutes.dashboard),
    _NavItem(icon: Icons.people_outlined,       label: 'Users',       route: AdminRoutes.users),
    _NavItem(icon: Icons.fact_check_outlined,   label: 'Moderation',  route: AdminRoutes.moderation),
    _NavItem(icon: Icons.school_outlined,       label: 'Departments', route: AdminRoutes.departments),
    _NavItem(icon: Icons.flag_outlined,         label: 'Reports',     route: AdminRoutes.reports),
    _NavItem(icon: Icons.settings_outlined,     label: 'Settings',    route: AdminRoutes.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 220,
      color: AdminColors.sidebar,
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: const Row(
              children: [
                Icon(Icons.school, color: Colors.white, size: 26),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'CampusCore\nAdmin',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          // Nav items
          ..._navItems.map((item) {
            final isSelected = currentRoute.startsWith(item.route);
            return _SidebarTile(item: item, isSelected: isSelected);
          }),
          const Spacer(),
          const Divider(color: Colors.white12),
          // Sign out
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white54, size: 20),
            title: const Text('Sign Out',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
            onTap: () => context.go(AdminRoutes.login),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  const _SidebarTile({required this.item, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AdminColors.sidebarSelected.withOpacity(0.25) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          item.icon,
          color: isSelected ? Colors.white : Colors.white54,
          size: 20,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
        onTap: () => context.go(item.route),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({required this.icon, required this.label, required this.route});
}
