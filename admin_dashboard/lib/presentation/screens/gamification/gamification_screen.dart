import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/admin_theme.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/responsive.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class BadgeStatsModel {
  final String badge;
  final int count;

  const BadgeStatsModel({required this.badge, required this.count});
}

class TopUserModel {
  final String id;
  final String fullName;
  final String email;
  final int reputationPoints;
  final String role;

  const TopUserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.reputationPoints,
    required this.role,
  });

  factory TopUserModel.fromJson(Map<String, dynamic> json) {
    return TopUserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      reputationPoints: (json['reputationPoints'] as num?)?.toInt() ??
          (json['reputation_points'] as num?)?.toInt() ?? 0,
      role: json['role'] as String? ?? 'student',
    );
  }
}

class GamificationOverview {
  final List<TopUserModel> topUsers;
  final Map<String, int> badgeCounts;
  final int totalBadgesAwarded;

  const GamificationOverview({
    required this.topUsers,
    required this.badgeCounts,
    required this.totalBadgesAwarded,
  });
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final gamificationOverviewProvider =
    FutureProvider<GamificationOverview>((ref) async {
  // Fetch top users by reputation (sorted desc)
  final usersResponse = await adminApi.get(
    '/admin/users',
    queryParameters: {'limit': 20, 'page': 1},
  );
  final usersRaw = (usersResponse.data['data'] ?? usersResponse.data);
  final usersList = (usersRaw is List
          ? usersRaw
          : (usersRaw as Map<String, dynamic>).values.first as List)
      .map((u) => TopUserModel.fromJson(u as Map<String, dynamic>))
      .toList();

  // Sort by reputation descending
  usersList.sort((a, b) => b.reputationPoints.compareTo(a.reputationPoints));
  final topUsers = usersList.take(10).toList();

  // Fetch all badges to compute counts per type
  // We aggregate from users' badges — use per-user badge endpoint for top users
  // For simplicity, aggregate badge names from badge endpoint responses
  final badgeCounts = <String, int>{};
  int totalBadges = 0;

  for (final user in topUsers) {
    try {
      final badgeResponse =
          await adminApi.get('/gamification/badges/${user.id}');
      final badges = (badgeResponse.data['data'] ?? badgeResponse.data) as List;
      for (final b in badges) {
        final name = b['badge'] as String? ?? '';
        badgeCounts[name] = (badgeCounts[name] ?? 0) + 1;
        totalBadges++;
      }
    } catch (_) {}
  }

  return GamificationOverview(
    topUsers: topUsers,
    badgeCounts: badgeCounts,
    totalBadgesAwarded: totalBadges,
  );
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getPadding(context);
    final overviewAsync = ref.watch(gamificationOverviewProvider);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gamification',
              style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w700)),
          const Text('Reputation points and badge distribution',
              style: TextStyle(color: AdminColors.grey600)),
          const SizedBox(height: 24),

          overviewAsync.when(
            loading: () => const Expanded(
                child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const Expanded(
                child: Center(child: Text('Could not load gamification data.'))),
            data: (overview) => Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary cards
                    isMobile
                        ? Column(
                            children: [
                              _SummaryCard(
                                  label: 'Total Badges Awarded',
                                  value: '${overview.totalBadgesAwarded}',
                                  icon: Icons.military_tech_outlined,
                                  color: AdminColors.accent),
                              const SizedBox(height: 12),
                              _SummaryCard(
                                  label: 'Badge Types',
                                  value: '${overview.badgeCounts.length}',
                                  icon: Icons.category_outlined,
                                  color: AdminColors.primary),
                              const SizedBox(height: 12),
                              _SummaryCard(
                                  label: 'Top Contributors',
                                  value: '${overview.topUsers.length}',
                                  icon: Icons.leaderboard_outlined,
                                  color: AdminColors.success),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                  child: _SummaryCard(
                                      label: 'Total Badges Awarded',
                                      value: '${overview.totalBadgesAwarded}',
                                      icon: Icons.military_tech_outlined,
                                      color: AdminColors.accent)),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: _SummaryCard(
                                      label: 'Badge Types',
                                      value: '${overview.badgeCounts.length}',
                                      icon: Icons.category_outlined,
                                      color: AdminColors.primary)),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: _SummaryCard(
                                      label: 'Top Contributors',
                                      value: '${overview.topUsers.length}',
                                      icon: Icons.leaderboard_outlined,
                                      color: AdminColors.success)),
                            ],
                          ),
                    const SizedBox(height: 24),

                    // Badge distribution
                    if (overview.badgeCounts.isNotEmpty) ...[
                      const Text('Badge Distribution',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: overview.badgeCounts.entries.map((e) {
                              final pct = overview.totalBadgesAwarded > 0
                                  ? e.value / overview.totalBadgesAwarded
                                  : 0.0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _BadgeIcon(badge: e.key),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _badgeLabel(e.key),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13),
                                          ),
                                        ),
                                        Text('${e.value}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AdminColors.primary)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 6,
                                        backgroundColor:
                                            AdminColors.grey300,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                _badgeColor(e.key)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Top users leaderboard
                    const Text('Reputation Leaderboard',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 12),
                    Card(
                      child: isMobile
                          ? ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: overview.topUsers.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) =>
                                  _LeaderboardTile(
                                      rank: i + 1,
                                      user: overview.topUsers[i]),
                            )
                          : DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFFF9FAFB)),
                              columns: const [
                                DataColumn(label: Text('#')),
                                DataColumn(label: Text('Name')),
                                DataColumn(label: Text('Email')),
                                DataColumn(label: Text('Role')),
                                DataColumn(
                                    label: Text('Reputation'),
                                    numeric: true),
                              ],
                              rows: overview.topUsers
                                  .asMap()
                                  .entries
                                  .map((e) => DataRow(cells: [
                                        DataCell(_RankBadge(rank: e.key + 1)),
                                        DataCell(Text(e.value.fullName,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.w600))),
                                        DataCell(Text(e.value.email,
                                            style: const TextStyle(
                                                fontSize: 13))),
                                        DataCell(_RoleChip(
                                            role: e.value.role)),
                                        DataCell(Text(
                                            '${e.value.reputationPoints}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AdminColors.primary))),
                                      ]))
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _badgeLabel(String badge) {
    switch (badge) {
      case 'fresh_scholar': return 'Fresh Scholar';
      case 'bookworm': return 'Bookworm';
      case 'top_contributor': return 'Top Contributor';
      case 'community_helper': return 'Community Helper';
      case 'ai_explorer': return 'AI Explorer';
      default: return badge;
    }
  }

  Color _badgeColor(String badge) {
    switch (badge) {
      case 'fresh_scholar': return AdminColors.success;
      case 'bookworm': return AdminColors.primary;
      case 'top_contributor': return AdminColors.accent;
      case 'community_helper': return AdminColors.info;
      case 'ai_explorer': return AdminColors.warning;
      default: return AdminColors.grey600;
    }
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 24)),
                Text(label,
                    style: const TextStyle(
                        color: AdminColors.grey600, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final String badge;
  const _BadgeIcon({required this.badge});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (badge) {
      case 'fresh_scholar': icon = Icons.school_outlined; break;
      case 'bookworm': icon = Icons.menu_book_outlined; break;
      case 'top_contributor': icon = Icons.upload_outlined; break;
      case 'community_helper': icon = Icons.people_outline; break;
      case 'ai_explorer': icon = Icons.auto_awesome_outlined; break;
      default: icon = Icons.military_tech_outlined;
    }
    return Icon(icon, size: 20, color: AdminColors.primary);
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (rank == 1) color = const Color(0xFFFFD700);
    else if (rank == 2) color = const Color(0xFFC0C0C0);
    else if (rank == 3) color = const Color(0xFFCD7F32);
    else color = AdminColors.grey600;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text('$rank',
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12, color: color)),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'admin': AdminColors.error,
      'moderator': AdminColors.warning,
      'lecturer': AdminColors.info,
      'student': AdminColors.success,
    };
    final color = colors[role] ?? AdminColors.grey600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${role[0].toUpperCase()}${role.substring(1)}',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final TopUserModel user;
  const _LeaderboardTile({required this.rank, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _RankBadge(rank: rank),
      title: Text(user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(user.email,
          style: const TextStyle(fontSize: 12, color: AdminColors.grey600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: AdminColors.accent),
          const SizedBox(width: 4),
          Text('${user.reputationPoints}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AdminColors.primary)),
        ],
      ),
    );
  }
}
