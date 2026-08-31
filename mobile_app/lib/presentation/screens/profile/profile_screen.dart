import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/router/app_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/connections_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit Profile',
          onPressed: () => _showEditSheet(context, ref, userAsync.valueOrNull),
        ),
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            userAsync.when(
              data: (user) => Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary,
                    backgroundImage: user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                    child: user?.avatar == null
                        ? Text(
                            user?.firstName.substring(0, 1).toUpperCase() ?? 'S',
                            style: const TextStyle(color: Colors.white, fontSize: 36,
                                fontWeight: FontWeight.w700))
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(user?.fullName ?? 'Student',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('${user?.displayLevel ?? ''} • Fisheries & Aquaculture',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.star, color: AppColors.accent, size: 18),
                    const SizedBox(width: 4),
                    Text('${user?.reputationPoints ?? 0} reputation points',
                        style: const TextStyle(fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  ]),
                ],
              ),
              loading: () => Column(children: [
                const CircleAvatar(radius: 48, backgroundColor: AppColors.grey200),
                const SizedBox(height: 12),
                Container(width: 120, height: 20, color: AppColors.grey200),
              ]),
              error: (_, __) => const CircleAvatar(
                radius: 48, backgroundColor: AppColors.primary,
                child: Icon(Icons.person, size: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Badges',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            const Wrap(spacing: 8, runSpacing: 8, children: [
              _Badge(label: 'Fresh Scholar', icon: Icons.school),
              _Badge(label: 'Bookworm', icon: Icons.menu_book),
            ]),
            const SizedBox(height: 28),
            Card(
              child: Column(children: [
                _ProfileTile(Icons.people_outline, 'Connections',
                    () => context.push(AppRoutes.connections)),
                const Divider(height: 1, indent: 56),
                _ProfileTile(Icons.calculate, 'GPA Calculator',
                    () => context.push(AppRoutes.gpaCalculator)),
                const Divider(height: 1, indent: 56),
                _ProfileTile(Icons.trending_up, 'My Progress',
                    () => context.push(AppRoutes.progress)),
                const Divider(height: 1, indent: 56),
                _ProfileTile(Icons.auto_awesome, 'AI Assistant',
                    () => context.push(AppRoutes.aiAssistant)),
              ]),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).signOut(),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, dynamic user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditProfileSheet(user: user, ref: ref),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Badge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey900)),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProfileTile(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

// ─── Edit Profile Sheet ───────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final dynamic user;
  final WidgetRef ref;
  const _EditProfileSheet({required this.user, required this.ref});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _matricCtrl;
  String? _selectedLevel;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: widget.user?.phone ?? '');
    _matricCtrl = TextEditingController(text: widget.user?.matricNumber ?? '');
    _selectedLevel = widget.user?.academicLevel;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _matricCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final api = widget.ref.read(apiClientProvider);
      await api.patch(ApiConstants.me, data: {
        'fullName': _nameCtrl.text.trim(),
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        if (_matricCtrl.text.trim().isNotEmpty) 'matricNumber': _matricCtrl.text.trim(),
        if (_selectedLevel != null) 'academicLevel': _selectedLevel,
      });
      widget.ref.invalidate(currentUserProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not save: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 20),
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Full Name'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone (optional)'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _matricCtrl,
          decoration: const InputDecoration(labelText: 'Matric Number (optional)'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedLevel,
          decoration: const InputDecoration(labelText: 'Academic Level'),
          items: ['100L', '200L', '300L', '400L', '500L']
              .map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
          onChanged: (v) => setState(() => _selectedLevel = v),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Changes'),
        ),
      ]),
    );
  }
}
