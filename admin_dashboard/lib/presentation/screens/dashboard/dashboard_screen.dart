import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/theme/admin_theme.dart';
import '../../../core/utils/api_client.dart';

// Provider for platform stats
final statsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final response = await adminApi.get('/admin/stats');
    final data = response.data['data'] ?? response.data;
    return data as Map<String, dynamic>;
  } catch (_) {
    return {'totalUsers': 0, 'activeUsers': 0, 'byRole': []};
  }
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

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
            data: (stats) => LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = constraints.maxWidth > 900 ? 4 : 2;
                final total = (stats['totalUsers'] as num?)?.toInt() ?? 0;
                final active = (stats['activeUsers'] as num?)?.toInt() ?? 0;
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
                    const _StatCard(
                        label: 'Pending Review',
                        value: '—',
                        icon: Icons.pending_actions,
                        color: AdminColors.warning),
                    const _StatCard(
                        label: 'Departments',
                        value: '1',
                        icon: Icons.school,
                        color: AdminColors.primary),
                  ],
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Could not load stats'),
          ),
          const SizedBox(height: 28),

          // Charts row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _UserGrowthChart()),
              const SizedBox(width: 20),
              SizedBox(width: 260, child: _RoleBreakdownChart()),
            ],
          ),
          const SizedBox(height: 28),

          // Recent activity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Activity',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 16),
                  ..._recentActivity.map((a) => ListTile(
                        dense: true,
                        leading: Icon(a['icon'] as IconData,
                            color: a['color'] as Color, size: 20),
                        title: Text(a['text'] as String,
                            style: const TextStyle(
                                color: AdminColors.grey900,
                                fontWeight: FontWeight.w500)),
                        trailing: Text(a['time'] as String,
                            style: const TextStyle(
                                color: AdminColors.grey600,
                                fontSize: 12)),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static final _recentActivity = [
    {
      'icon': Icons.upload_file,
      'color': AdminColors.success,
      'text': 'New resource submitted for review',
      'time': '2m ago'
    },
    {
      'icon': Icons.person_add,
      'color': AdminColors.info,
      'text': 'New user registered',
      'time': '15m ago'
    },
    {
      'icon': Icons.flag,
      'color': AdminColors.error,
      'text': 'Content flagged for review',
      'time': '1h ago'
    },
    {
      'icon': Icons.check_circle,
      'color': AdminColors.success,
      'text': 'Resource approved',
      'time': '2h ago'
    },
  ];
}

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
                color: color.withOpacity(0.12),
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
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('User Growth',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AdminColors.grey900)),
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
                        const months = ['Jan','Feb','Mar','Apr','May','Jun'];
                        return Text(
                          months[v.toInt() % months.length],
                          style: const TextStyle(
                              fontSize: 11, color: AdminColors.grey600),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 80), FlSpot(1, 220), FlSpot(2, 410),
                      FlSpot(3, 680), FlSpot(4, 950), FlSpot(5, 1248),
                    ],
                    isCurved: true,
                    color: AdminColors.primary,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AdminColors.primary.withOpacity(0.08),
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
  @override
  Widget build(BuildContext context) {
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
              child: PieChart(PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 36,
                sections: [
                  PieChartSectionData(
                      value: 1180,
                      color: AdminColors.primary,
                      title: 'Students',
                      radius: 50,
                      titleStyle: const TextStyle(
                          color: Colors.white, fontSize: 10)),
                  PieChartSectionData(
                      value: 42,
                      color: AdminColors.accent,
                      title: 'Mods',
                      radius: 50,
                      titleStyle: const TextStyle(
                          color: Colors.white, fontSize: 10)),
                  PieChartSectionData(
                      value: 18,
                      color: AdminColors.info,
                      title: 'Lecturers',
                      radius: 50,
                      titleStyle: const TextStyle(
                          color: Colors.white, fontSize: 10)),
                  PieChartSectionData(
                      value: 8,
                      color: AdminColors.grey600,
                      title: 'Admins',
                      radius: 50,
                      titleStyle: const TextStyle(
                          color: Colors.white, fontSize: 10)),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }
}
