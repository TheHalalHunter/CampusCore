import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/admin_theme.dart';
import '../../../core/utils/api_client.dart';
import '../exam_lock/exam_lock_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // TODO: Wire to backend once a settings endpoint for registrations/AI toggle
  // is implemented. These remain as UI-only toggles for now.
  bool _newRegistrations = true;
  bool _aiAssistantEnabled = true;

  @override
  Widget build(BuildContext context) {
    final locksAsync = ref.watch(examLocksProvider);
    final examLockEnabled = locksAsync.maybeWhen(
      data: (locks) => locks.any((l) => l.isCurrentlyActive),
      orElse: () => false,
    );

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Platform Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const Text('Configure platform-wide behaviour',
              style: TextStyle(color: AdminColors.grey600)),
          const SizedBox(height: 28),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.lock_clock,
                  iconColor: AdminColors.error,
                  title: 'Examination Lock Mode',
                  subtitle:
                      'Restricts AI assistant and discussions during exam periods',
                  value: examLockEnabled,
                  onChanged: (v) async {
                    if (v) {
                      // Turn ON — show create dialog
                      await showDialog(
                        context: context,
                        builder: (_) => CreateLockDialog(
                          onCreated: () =>
                              ref.invalidate(examLocksProvider),
                        ),
                      );
                    } else {
                      // Turn OFF — delete all currently active locks
                      final locks = locksAsync.asData?.value ?? [];
                      for (final lock
                          in locks.where((l) => l.isCurrentlyActive)) {
                        try {
                          await adminApi.delete('/exam-lock/${lock.id}');
                        } catch (_) {}
                      }
                      ref.invalidate(examLocksProvider);
                    }
                  },
                ),
                const Divider(height: 1, indent: 60),
                _SettingsTile(
                  icon: Icons.app_registration,
                  iconColor: AdminColors.info,
                  title: 'Allow New Registrations',
                  subtitle: 'New students can sign up for an account',
                  value: _newRegistrations,
                  onChanged: (v) => setState(() => _newRegistrations = v),
                ),
                const Divider(height: 1, indent: 60),
                _SettingsTile(
                  icon: Icons.auto_awesome,
                  iconColor: AdminColors.accent,
                  title: 'AI Study Assistant',
                  subtitle: 'Enable or disable the AI assistant platform-wide',
                  value: _aiAssistantEnabled,
                  onChanged: (v) => setState(() => _aiAssistantEnabled = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Integrity Policy',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text(
                    'All students must accept the Academic Integrity Policy on first login. '
                    'The AI assistant automatically detects and refuses live exam question patterns. '
                    'Contact your system administrator to update the policy document.',
                    style: TextStyle(color: AdminColors.grey600, height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Policy'),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AdminColors.grey600, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AdminColors.primary,
    );
  }
}
