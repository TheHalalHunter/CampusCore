import 'package:flutter/material.dart';
import '../../../app/theme/admin_theme.dart';
import '../../../core/utils/responsive.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _searchQuery = '';
  String _roleFilter = 'All';

  final _roleOptions = ['All', 'Student', 'Moderator', 'Lecturer', 'Admin'];

  static final _users = List.generate(12, (i) => {
    'name': 'Student ${i + 1}',
    'email': 'student${i + 1}@lautech.edu.ng',
    'role': i == 0 ? 'Admin' : i < 3 ? 'Moderator' : 'Student',
    'level': '${(i % 4 + 1) * 100}L',
    'status': i == 5 ? 'Suspended' : 'Active',
    'joined': '${i + 1} Jan 2026',
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getPadding(context);
    final spacing = Responsive.getSpacing(context);

    final filtered = _users.where((u) {
      final matchSearch = _searchQuery.isEmpty ||
          (u['name']!).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (u['email']!).toLowerCase().contains(_searchQuery.toLowerCase());
      final matchRole = _roleFilter == 'All' || u['role'] == _roleFilter;
      return matchSearch && matchRole;
    }).toList();

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            title: 'Users',
            subtitle: 'Manage all registered users',
            isMobile: isMobile,
          ),
          SizedBox(height: spacing + 12),
          // Toolbar
          if (isMobile)
            Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search…',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _roleFilter,
                  isExpanded: true,
                  items: _roleOptions
                      .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (v) => setState(() => _roleFilter = v ?? 'All'),
                  underline: Container(),
                  style: const TextStyle(fontSize: 12, color: AdminColors.grey800),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                DropdownButton<String>(
                  value: _roleFilter,
                  items: _roleOptions
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _roleFilter = v ?? 'All'),
                  underline: const SizedBox(),
                ),
              ],
            ),
          SizedBox(height: spacing + 8),
          Expanded(
            child: Card(
              child: isMobile
                  ? ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final u = filtered[index];
                        final isSuspended = u['status'] == 'Suspended';
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          u['name']!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          u['email']!,
                                          style: const TextStyle(fontSize: 11, color: AdminColors.grey600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  _RoleChip(role: u['role']!, isMobile: true),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Wrap(
                                    spacing: 4,
                                    children: [
                                      _StatusChip(status: u['status']!, isMobile: true),
                                      Text(
                                        u['level']!,
                                        style: const TextStyle(fontSize: 11, color: AdminColors.grey600),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          isSuspended ? Icons.check_circle_outline : Icons.block,
                                          size: 16,
                                          color:
                                              isSuspended ? AdminColors.success : AdminColors.warning,
                                        ),
                                        onPressed: () {},
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.more_vert, size: 16),
                                        onPressed: () =>
                                            _showChangeRoleDialog(context, u['name']!),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Role')),
                          DataColumn(label: Text('Level')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: filtered.map((u) {
                          final isSuspended = u['status'] == 'Suspended';
                          return DataRow(cells: [
                            DataCell(Text(
                              u['name']!,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            )),
                            DataCell(Text(u['email']!)),
                            DataCell(_RoleChip(role: u['role']!)),
                            DataCell(Text(u['level']!)),
                            DataCell(_StatusChip(status: u['status']!)),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isSuspended ? Icons.check_circle_outline : Icons.block,
                                    size: 18,
                                    color: isSuspended ? AdminColors.success : AdminColors.warning,
                                  ),
                                  tooltip: isSuspended ? 'Activate' : 'Suspend',
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.manage_accounts_outlined, size: 18),
                                  tooltip: 'Change role',
                                  onPressed: () =>
                                      _showChangeRoleDialog(context, u['name']!),
                                ),
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(BuildContext context, String userName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Change Role — $userName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Student', 'Moderator', 'Lecturer', 'Admin']
              .map((r) => ListTile(
                title: Text(r),
                onTap: () => Navigator.pop(context),
              ))
              .toList(),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  final bool isMobile;

  const _RoleChip({required this.role, this.isMobile = false});

  static const _colors = {
    'Admin': AdminColors.error,
    'Moderator': AdminColors.warning,
    'Lecturer': AdminColors.info,
    'Student': AdminColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[role] ?? AdminColors.primary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: isMobile ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: color,
          fontSize: isMobile ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final bool isMobile;

  const _StatusChip({required this.status, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'Active';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: isMobile ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: (isActive ? AdminColors.success : AdminColors.error).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isActive ? AdminColors.success : AdminColors.error,
          fontSize: isMobile ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isMobile;

  const _PageHeader({
    required this.title,
    required this.subtitle,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: isMobile ? 20 : 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(
        subtitle,
        style: TextStyle(
          color: AdminColors.grey600,
          fontSize: isMobile ? 12 : 14,
        ),
      ),
    ],
  );
}
