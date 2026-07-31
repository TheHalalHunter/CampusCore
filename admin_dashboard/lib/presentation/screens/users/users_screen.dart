import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../app/theme/admin_theme.dart';

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
    'name':   'Student ${i + 1}',
    'email':  'student${i + 1}@lautech.edu.ng',
    'role':   i == 0 ? 'Admin' : i < 3 ? 'Moderator' : 'Student',
    'level':  '${(i % 4 + 1) * 100}L',
    'status': i == 5 ? 'Suspended' : 'Active',
    'joined': '${i + 1} Jan 2026',
  });

  @override
  Widget build(BuildContext context) {
    final filtered = _users.where((u) {
      final matchSearch = _searchQuery.isEmpty ||
          (u['name']!).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (u['email']!).toLowerCase().contains(_searchQuery.toLowerCase());
      final matchRole = _roleFilter == 'All' || u['role'] == _roleFilter;
      return matchSearch && matchRole;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PageHeader(title: 'Users', subtitle: 'Manage all registered users'),
          const SizedBox(height: 24),
          // Toolbar
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
              const SizedBox(width: 12),
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
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: DataTable2(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                columnSpacing: 12,
                columns: const [
                  DataColumn2(label: Text('Name'), size: ColumnSize.L),
                  DataColumn2(label: Text('Email'), size: ColumnSize.L),
                  DataColumn2(label: Text('Role'), size: ColumnSize.S),
                  DataColumn2(label: Text('Level'), size: ColumnSize.S),
                  DataColumn2(label: Text('Status'), size: ColumnSize.S),
                  DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                ],
                rows: filtered.map((u) {
                  final isSuspended = u['status'] == 'Suspended';
                  return DataRow2(cells: [
                    DataCell(Text(u['name']!, style: const TextStyle(fontWeight: FontWeight.w600))),
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
                          onPressed: () => _showChangeRoleDialog(context, u['name']!),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
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
          children: ['Student', 'Moderator', 'Lecturer', 'Admin'].map((r) => ListTile(
            title: Text(r),
            onTap: () => Navigator.pop(context),
          )).toList(),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(role, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    final isActive = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isActive ? AdminColors.success : AdminColors.error).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status, style: TextStyle(
        color: isActive ? AdminColors.success : AdminColors.error,
        fontSize: 12, fontWeight: FontWeight.w600,
      )),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _PageHeader({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
      Text(subtitle, style: const TextStyle(color: AdminColors.grey600)),
    ],
  );
}
