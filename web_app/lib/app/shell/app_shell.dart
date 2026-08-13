import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final List<({String label, String route, IconData icon})> _navItems = [
    (label: 'Home', route: '/', icon: Icons.home_outlined),
    (label: 'Courses', route: '/courses', icon: Icons.school_outlined),
    (label: 'Resources', route: '/resources', icon: Icons.library_books_outlined),
    (label: 'Community', route: '/community', icon: Icons.people_outlined),
    (label: 'Progress', route: '/progress', icon: Icons.trending_up_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            color: AppColors.grey50,
            child: Column(
              children: [
                // Logo
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CampusCore',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Learn. Connect. Achieve.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey500,
                        ),
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
                      return ListTile(
                        leading: Icon(
                          item.icon,
                          color: isSelected ? AppColors.primary : AppColors.grey500,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.grey700,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: AppColors.primary.withOpacity(0.08),
                        onTap: () {
                          setState(() => _selectedIndex = index);
                          context.go(item.route);
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                // User profile
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: const Text('ST', style: TextStyle(color: Colors.white)),
                    ),
                    title: const Text('Student Name'),
                    subtitle: const Text('student@lautech.edu.ng'),
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
