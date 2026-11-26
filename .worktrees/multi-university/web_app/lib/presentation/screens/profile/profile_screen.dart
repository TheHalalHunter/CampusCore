import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/storage/supabase_storage.dart';
import '../../../core/utils/responsive.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  String? _selectedLevel;
  final _levels = ['100L', '200L', '300L', '400L', '500L'];
  bool _editing  = false;
  bool _saving   = false;
  String? _successMsg;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _firstNameCtrl.text = user?.firstName ?? '';
    _lastNameCtrl.text  = user?.lastName  ?? '';
    _phoneCtrl.text     = user?.phone     ?? '';
    _selectedLevel      = user?.level != null ? '${user!.level}L' : null;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _successMsg = null; });

    final error = await ref.read(authProvider.notifier).updateProfile(
      firstName: _firstNameCtrl.text.trim(),
      lastName:  _lastNameCtrl.text.trim(),
      phone:     _phoneCtrl.text.trim(),
      academicLevel: _selectedLevel,
    );

    setState(() {
      _saving  = false;
      _editing = error != null; // stay in edit mode on error
      _successMsg = error == null ? 'Profile updated successfully!' : null;
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    final rawExt  = (file.extension ?? 'jpg').toLowerCase();
    final ext     = rawExt == 'png' ? 'png' : 'jpg';
    final mime    = ext == 'png' ? 'image/png' : 'image/jpeg';
    final path    = 'avatars/${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      final downloadUrl = await SupabaseStorageService.uploadFile(
        bytes: file.bytes!,
        path: path,
        mimeType: mime,
      );
      final error = await ref.read(authProvider.notifier).updateAvatar(downloadUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'Profile picture updated!',
            style: const TextStyle(fontFamily: 'Nunito'),
          ),
          backgroundColor: error == null ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload failed. Please try again.', style: TextStyle(fontFamily: 'Nunito')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user     = ref.watch(currentUserProvider);
    final authState = ref.watch(authProvider);
    final isMobile = Responsive.isMobile(context);
    final padding  = Responsive.getPaddingEdgeInsets(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_editing)
            TextButton.icon(
              onPressed: () => setState(() { _editing = true; _successMsg = null; }),
              icon: const Icon(Icons.edit_outlined, color: AppColors.coreBlue, size: 18),
              label: const Text('Edit', style: TextStyle(color: AppColors.coreBlue, fontFamily: 'Nunito')),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar card ───────────────────────────────────────────
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 20 : 28),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _pickAndUploadAvatar,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: isMobile ? 32 : 40,
                                backgroundColor: AppColors.primary,
                                child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          user.avatarUrl!,
                                          width:  (isMobile ? 32 : 40) * 2,
                                          height: (isMobile ? 32 : 40) * 2,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Text(
                                            user.initials,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isMobile ? 22 : 28,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'Nunito',
                                            ),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        user?.initials ?? 'ST',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isMobile ? 22 : 28,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Nunito',
                                        ),
                                      ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Student',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textHint,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _Tag(
                                    label: _roleLabel(user?.role ?? 'student'),
                                    color: AppColors.primary,
                                  ),
                                  if (user?.level != null) ...[
                                    const SizedBox(width: 8),
                                    _Tag(label: '${user!.level}L', color: AppColors.cyan),
                                  ],
                                  if (user?.reputationPoints != null) ...[
                                    const SizedBox(width: 8),
                                    _Tag(
                                      label: '${user!.reputationPoints} pts',
                                      color: AppColors.success,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Edit form ─────────────────────────────────────────────
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 20 : 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Information',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 20),

                          // First name
                          TextFormField(
                            controller: _firstNameCtrl,
                            enabled: _editing,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                              prefixIcon: Icon(Icons.person_outlined),
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),

                          // Last name
                          TextFormField(
                            controller: _lastNameCtrl,
                            enabled: _editing,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              prefixIcon: Icon(Icons.person_outlined),
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),

                          // Email (read-only)
                          TextFormField(
                            initialValue: user?.email ?? '',
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                              helperText: 'Email cannot be changed here.',
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Phone
                          TextFormField(
                            controller: _phoneCtrl,
                            enabled: _editing,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number (optional)',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Academic Level
                          DropdownButtonFormField<String>(
                            value: _selectedLevel,
                            decoration: const InputDecoration(
                              labelText: 'Academic Level',
                              prefixIcon: Icon(Icons.school_outlined),
                            ),
                            items: _levels.map((l) => DropdownMenuItem(
                              value: l,
                              child: Text(l, style: const TextStyle(fontFamily: 'Nunito')),
                            )).toList(),
                            onChanged: _editing ? (v) => setState(() => _selectedLevel = v) : null,
                          ),

                          // Error
                          if (authState.error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      authState.error!,
                                      style: const TextStyle(color: AppColors.error, fontSize: 13, fontFamily: 'Nunito'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Success
                          if (_successMsg != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    _successMsg!,
                                    style: const TextStyle(color: AppColors.success, fontSize: 13, fontFamily: 'Nunito'),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (_editing) ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _saving
                                        ? null
                                        : () {
                                            // Reset fields
                                            final u = ref.read(currentUserProvider);
                                            _firstNameCtrl.text = u?.firstName ?? '';
                                            _lastNameCtrl.text  = u?.lastName  ?? '';
                                            _phoneCtrl.text     = u?.phone     ?? '';
                                            _selectedLevel      = u?.level != null ? '${u!.level}L' : null;
                                            setState(() => _editing = false);
                                          },
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _saving ? null : _save,
                                    child: _saving
                                        ? const SizedBox(
                                            width: 18, height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text('Save Changes'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Account actions ───────────────────────────────────────
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.logout_outlined, color: AppColors.error),
                          title: const Text('Sign Out',
                              style: TextStyle(color: AppColors.error, fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
                          onTap: () => _confirmSignOut(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':     return 'Admin';
      case 'moderator': return 'Moderator';
      case 'lecturer':  return 'Lecturer';
      default:          return 'Student';
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Nunito')),
    );
  }
}
