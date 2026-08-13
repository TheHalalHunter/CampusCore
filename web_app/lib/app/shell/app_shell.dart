import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../../core/utils/responsive.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;

  final List<({String label, String route, IconData icon})> _navItems = [
    (label: 'Home', route: '/', icon: Icons.home_outlined),
    (label: 'Courses', route: '/courses', icon: Icons.school_outlined),
    (label: 'Resources', route: '/resources', icon: Icons.library_books_outlined),
    (label: 'Community', route: '/community', icon: Icons.people_outlined),
    (label: 'Progress', route: '/progress', icon: Icons.trending_up_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('CampusCore'),
          elevation: 0,
          centerTitle: false,
        ),
        body: widget.child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          items: _navItems
              .map(
                (item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  label: item.label,
                ),
              )
              .toList(),
          onTap: (index) {
            setState(() => _selectedIndex = index);
            context.go(_navItems[index].route);
          },
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _sidebarExpanded ? (isTablet ? 200 : 280) : 80,
            color: AppColors.grey50,
            child: Column(
              children: [
                // Logo/Header
                Padding(
                  padding: EdgeInsets.all(_sidebarExpanded ? 16 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_sidebarExpanded)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CampusCore',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppColors.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Learn. Connect.',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.grey500,
                                      fontSize: 10,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          IconButton(
                            icon: Icon(
                              _sidebarExpanded ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onPressed: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Navigation items
                Expanded(
                  child: ListView.builder(
                    itemCount: _navItems.length,
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final isSelected = _selectedIndex == index;
                      return Tooltip(
                        message: _sidebarExpanded ? '' : item.label,
                        child: ListTile(
                          leading: Icon(
                            item.icon,
                            color: isSelected ? AppColors.primary : AppColors.grey500,
                            size: 20,
                          ),
                          title: _sidebarExpanded
                              ? Text(
                                  item.label,
                                  style: TextStyle(
                                    color: isSelected ? AppColors.primary : AppColors.grey700,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: isTablet ? 13 : 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          selected: isSelected,
                          selectedTileColor: AppColors.primary.withOpacity(0.08),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: _sidebarExpanded ? 16 : 8,
                          ),
                          onTap: () {
                            setState(() => _selectedIndex = index);
                            context.go(item.route);
                          },
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                // User profile
                if (_sidebarExpanded)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: const Text('ST', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      title: const Text('Student', style: TextStyle(fontSize: 12)),
                      subtitle: const Text('student@lautech.edu.ng', 
                        style: TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      child: const Text('ST', style: TextStyle(color: Colors.white, fontSize: 12)),
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
}
