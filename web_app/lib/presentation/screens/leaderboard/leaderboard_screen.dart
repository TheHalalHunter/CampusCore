import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/auth_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────
final leaderboardProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api  = ref.read(apiClientProvider);
  final resp = await api.get(ApiConstants.leaderboard);
  final data = resp.data['data'];
  if (data is List) return data.cast<Map<String, dynamic>>();
  return [];
});

// ── Screen ────────────────────────────────────────────────────────────────────
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderAsync = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: leaderAsync.when(
        loading: () => _buildSkeleton(),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.leaderboard_outlined,
                  size: 64, color: AppColors.border),
              const SizedBox(height: 16),
              const Text('Could not load leaderboard',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontFamily: 'Nunito')),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => ref.invalidate(leaderboardProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.leaderboard_outlined,
                      size: 64, color: AppColors.border),
                  SizedBox(height: 16),
                  Text('No data yet.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontFamily: 'Nunito')),
                ],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user    = users[index];
                    final userId  = user['id']?.toString() ?? '';
                    final isMe    = userId == (currentUser?.id ?? '');
                    return _LeaderboardTile(
                      rank: index + 1,
                      user: user,
                      isCurrentUser: isMe,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 44),
          Expanded(
            child: Text(
              'Student',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Nunito',
              ),
            ),
          ),
          Text(
            'Points',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(18))),
            const SizedBox(width: 12),
            Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(20))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 140, height: 13, color: AppColors.surfaceAlt),
                  const SizedBox(height: 6),
                  Container(width: 80, height: 10, color: AppColors.surfaceAlt),
                ],
              ),
            ),
            Container(width: 56, height: 24,
                decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12))),
          ],
        ),
      ),
    );
  }
}

// ── Single leaderboard tile ───────────────────────────────────────────────────
class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> user;
  final bool isCurrentUser;

  const _LeaderboardTile({
    required this.rank,
    required this.user,
    required this.isCurrentUser,
  });

  String _initials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final fullName    = user['fullName']?.toString()    ?? 'Unknown';
    final level       = user['academicLevel']?.toString() ?? '';
    final reputation  = user['reputationPoints'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? AppColors.primary : AppColors.border,
          width: isCurrentUser ? 1.5 : 0.8,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: SizedBox(
          width: 44,
          child: Row(
            children: [
              _rankWidget(),
            ],
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isCurrentUser
                  ? AppColors.primary
                  : AppColors.primaryLight.withValues(alpha: 0.8),
              child: Text(
                _initials(fullName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: TextStyle(
                      color: isCurrentUser
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      fontFamily: 'Nunito',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (level.isNotEmpty)
                    Text(
                      level,
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                        fontFamily: 'Nunito',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$reputation pts',
            style: TextStyle(
              color: isCurrentUser
                  ? AppColors.primary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              fontFamily: 'Nunito',
            ),
          ),
        ),
      ),
    );
  }

  Widget _rankWidget() {
    if (rank == 1) {
      return const Icon(Icons.emoji_events,
          color: Color(0xFFFFD700), size: 28);
    } else if (rank == 2) {
      return const Icon(Icons.emoji_events,
          color: AppColors.grey400, size: 28);
    } else if (rank == 3) {
      return const Icon(Icons.emoji_events,
          color: Color(0xFFCD7F32), size: 28);
    }
    return SizedBox(
      width: 28,
      child: Text(
        '$rank',
        style: const TextStyle(
          color: AppColors.textHint,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          fontFamily: 'Nunito',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
