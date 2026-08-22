import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/admin_router.dart';
import '../../app/theme/admin_theme.dart';
import '../../core/utils/responsive.dart';

class AdminShell extends StatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  bool _sidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('CampusCore Admin'),
          backgroundColor: AdminColors.sidebar,
          elevation: 0,
          centerTitle: false,
        ),
        body: widget.child,
        drawer: _AdminSidebar(isMobile: true),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _sidebarExpanded ? (isTablet ? 200 : 220) : 80,
            child: _AdminSidebar(
              isMobile: false,
              expanded: _sidebarExpanded,
              onToggle: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final _navItems = const [
    _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', route: AdminRoutes.dashboard),
    _NavItem(icon: Icons.people_outlined, label: 'Users', route: AdminRoutes.users),
    _NavItem(icon: Icons.fact_check_outlined, label: 'Moderation', route: AdminRoutes.moderation),
    _NavItem(icon: Icons.school_outlined, label: 'Departments', route: AdminRoutes.departments),
    _NavItem(icon: Icons.menu_book_outlined, label: 'Courses', route: AdminRoutes.courses),
    _NavItem(icon: Icons.lock_clock_outlined, label: 'Exam Lock', route: AdminRoutes.examLock),
    _NavItem(icon: Icons.military_tech_outlined, label: 'Gamification', route: AdminRoutes.gamification),
    _NavItem(icon: Icons.flag_outlined, label: 'Reports', route: AdminRoutes.reports),
    _NavItem(icon: Icons.settings_outlined, label: 'Settings', route: AdminRoutes.settings),
  ];

  final bool isMobile;
  final bool expanded;
  final VoidCallback? onToggle;

  const _AdminSidebar({
    this.isMobile = false,
    this.expanded = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;

    if (isMobile) {
      return Drawer(
        child: Container(
          color: AdminColors.sidebar,
          child: Column(
            children: [
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
              ..._navItems.map((item) {
                final isSelected = currentRoute.startsWith(item.route);
                return _SidebarTile(item: item, isSelected: isSelected);
              }),
              const Spacer(),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white54, size: 20),
                title: const Text('Sign Out',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
                onTap: () => context.go(AdminRoutes.login),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    }

    return Container(
      color: AdminColors.sidebar,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 20 : 12,
              vertical: 28,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (expanded)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.school, color: Colors.white, size: 26),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'CampusCore',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Admin',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Icon(Icons.school, color: Colors.white, size: 26),
                if (onToggle != null)
                  IconButton(
                    icon: Icon(
                      expanded ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                      color: Colors.white54,
                      size: 16,
                    ),
                    onPressed: onToggle,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = currentRoute.startsWith(item.route);
                return Tooltip(
                  message: expanded ? '' : item.label,
                  child: _SidebarTile(
                    item: item,
                    isSelected: isSelected,
                    expanded: expanded,
                  ),
                );
              },
            ),
          ),
          const Divider(color: Colors.white12),
          Padding(
            padding: EdgeInsets.all(expanded ? 12 : 8),
            child: Tooltip(
              message: expanded ? '' : 'Sign Out',
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.logout, color: Colors.white54, size: 20),
                title: expanded
                    ? const Text('Sign Out',
                        style: TextStyle(color: Colors.white54, fontSize: 14))
                    : null,
                onTap: () => context.go(AdminRoutes.login),
                contentPadding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0),
              ),
            ),
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
  final bool expanded;

  const _SidebarTile({
    required this.item,
    required this.isSelected,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: expanded ? 10 : 6, vertical: 2),
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
        title: expanded
            ? Text(
                item.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              )
            : null,
        onTap: () => context.go(item.route),
        contentPadding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0),
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
