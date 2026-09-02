import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/theme/admin_theme.dart';
import '../../../core/utils/api_client.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final statsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final response = await adminApi.get('/admin/stats');
    final data = response.data['data'] ?? response.data;
    return data as Map<String, dynamic>;
  } catch (_) {
    return {'totalUsers': 0, 'activeUsers': 0, 'byRole': []};
  }
});

final pendingCountProvider = FutureProvider<int>((ref) async {
  try {
    final response = await adminApi.get('/resources/moderation/pending');
    final data = response.data['data'] ?? response.data;
    return (data as List).length;
  } catch (_) {
    return 0;
  }
});

final departmentCountProvider = FutureProvider<int>((ref) async {
  try {
    final response = await adminApi.get('/departments');
    final data = response.data['data'] ?? response.data;
    return (data as List).length;
  } catch (_) {
    return 0;
  }
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final pendingAsync = ref.watch(pendingCountProvider);
    final deptsAsync = ref.watch(departmentCountProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PageHeader(
              title: 'Dashboard', subtitle: 'Platform overview'),
          const SizedBox(height: 28),

          // Stat cards
          statsAsync.when(
            data: (stats) {
              final total =
                  (stats['totalUsers'] as num?)?.toInt() ?? 0;
              final active =
                  (stats['activeUsers'] as num?)?.toInt() ?? 0;
              final pending =
                  pendingAsync.valueOrNull ?? 0;
              final depts = deptsAsync.valueOrNull ?? 0;

              return LayoutBuilder(builder: (context, constraints) {
                final crossCount =
                    constraints.maxWidth > 900 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: crossCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.7,
                  children: [
                    _StatCard(
                        label: 'Total Users',
                        value: '$total',
                        icon: Icons.people,
                        color: AdminColors.info),
                    _StatCard(
                        label: 'Active Users',
                        value: '$active',
                        icon: Icons.person_outline,
                        color: AdminColors.success),
                    _StatCard(
                        label: 'Pending Review',
                        value: '$pending',
                        icon: Icons.pending_actions,
                        color: AdminColors.warning),
                    _StatCard(
                        label: 'Departments',
                        value: '$depts',
                        icon: Icons.school,
                        color: AdminColors.primary),
                  ],
                );
              });
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Text('Could not load stats'),
          ),
          const SizedBox(height: 28),

          // Charts row — role breakdown from real data
          statsAsync.when(
            data: (stats) {
              final byRole = stats['byRole'] as List? ?? [];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(child: _UserGrowthChart()),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 260,
                    child: _RoleBreakdownChart(byRole: byRole),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(height: 200,
                child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 28),

          // Recent activity — real pending resources
          _RecentActivity(),
        ],
      ),
    );
  }
}

// ─── Recent Activity (live) ───────────────────────────────────────────────────

class _RecentActivity extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingCountProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Stats',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              dense: true,
              leading: const Icon(Icons.pending_actions,
                  color: AdminColors.warning, size: 20),
              title: Text(
                pendingAsync.valueOrNull == 0
                    ? 'No resources pending review'
                    : '${pendingAsync.valueOrNull} resource(s) awaiting review',
                style: const TextStyle(
                    color: AdminColors.grey900,
                    fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 12, color: AdminColors.grey600),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.check_circle_outline,
                  color: AdminColors.success, size: 20),
              title: const Text('Platform is running normally',
                  style: TextStyle(
                      color: AdminColors.grey900,
                      fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 12, color: AdminColors.grey600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _PageHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AdminColors.grey900)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(color: AdminColors.grey600)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.grey900)),
                Text(label,
                    style: const TextStyle(
                        color: AdminColors.grey600, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserGrowthChart extends StatelessWidget {
  const _UserGrowthChart();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('User Growth (cumulative)',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AdminColors.grey900)),
            const SizedBox(height: 8),
            const Text('Historical trend — update with real data via analytics API',
                style: TextStyle(
                    color: AdminColors.grey600, fontSize: 12)),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: LineChart(LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const months = [
                          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'
                        ];
                        return Text(
                          months[v.toInt() % months.length],
                          style: const TextStyle(
                              fontSize: 11,
                              color: AdminColors.grey600),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 0),
                      FlSpot(1, 50),
                      FlSpot(2, 120),
                      FlSpot(3, 200),
                      FlSpot(4, 310),
                      FlSpot(5, 450),
                    ],
                    isCurved: true,
                    color: AdminColors.primary,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AdminColors.primary.withValues(alpha: 0.08),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBreakdownChart extends StatelessWidget {
  final List byRole;
  const _RoleBreakdownChart({required this.byRole});

  @override
  Widget build(BuildContext context) {
    // Map role name to color
    final colors = {
      'student': AdminColors.primary,
      'moderator': AdminColors.accent,
      'lecturer': AdminColors.info,
      'admin': AdminColors.grey600,
    };

    final sections = byRole.map<PieChartSectionData>((r) {
      final role = r['role'] as String? ?? '';
      final count = double.tryParse(r['count'].toString()) ?? 0;
      final color = colors[role] ?? AdminColors.grey300;
      return PieChartSectionData(
        value: count,
        color: color,
        title: count > 0 ? '${count.toInt()}' : '',
        radius: 50,
        titleStyle:
            const TextStyle(color: Colors.white, fontSize: 10),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Users by Role',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AdminColors.grey900)),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: sections.isEmpty
                  ? const Center(
                      child: Text('No data',
                          style: TextStyle(
                              color: AdminColors.grey600)))
                  : PieChart(PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 36,
                      sections: sections,
                    )),
            ),
            const SizedBox(height: 12),
            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: colors.entries.map((e) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: e.value,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(
                    '${e.key[0].toUpperCase()}${e.key.substring(1)}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AdminColors.grey600),
                  ),
                ],
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
