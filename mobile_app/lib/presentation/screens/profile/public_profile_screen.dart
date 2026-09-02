import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/common/connect_button.dart';
import '../../providers/user_provider.dart';

/// Public profile viewed when tapping another user's name anywhere in the app.
class PublicProfileScreen extends ConsumerWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_publicProfileProvider(userId));
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load profile.')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found.'));
          }

          // Don't show connect button on your own profile
          final isSelf = currentUserAsync.valueOrNull?.id == userId;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.primary,
                  backgroundImage:
                      user.avatar != null ? NetworkImage(user.avatar!) : null,
                  child: user.avatar == null
                      ? Text(
                          user.firstName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(height: 14),

                // Name
                Text(user.fullName,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),

                Text(
                  '${user.displayLevel} • ${user.role[0].toUpperCase()}${user.role.substring(1)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 8),

                // Reputation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: AppColors.accent, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${user.reputationPoints} reputation points',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Connect button (only for other users)
                if (!isSelf) ConnectButton(targetUserId: userId),

                const SizedBox(height: 28),

                // Info card
                Card(
                  child: Column(
                    children: [
                      _InfoTile(
                          icon: Icons.school_outlined,
                          label: 'Level',
                          value: user.displayLevel),
                      const Divider(height: 1, indent: 56),
                      _InfoTile(
                          icon: Icons.badge_outlined,
                          label: 'Role',
                          value:
                              '${user.role[0].toUpperCase()}${user.role.substring(1)}'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Provider that fetches a user's public profile
final _publicProfileProvider =
    FutureProvider.family<UserModel?, String>((ref, userId) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api
        .get('${ApiConstants.me.replaceAll('/me', '')}/$userId/profile');
    final data = response.data['data'] ?? response.data;
    return UserModel.fromJson(data as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      trailing: Text(value,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    );
  }
}
