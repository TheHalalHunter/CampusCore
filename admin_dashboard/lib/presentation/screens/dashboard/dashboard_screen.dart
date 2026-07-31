import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/theme/admin_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(title: 'Dashboard', subtitle: 'Platform overview'),
          const SizedBox(height: 28),

          // Stat cards row
          LayoutBuilder(builder: (context, constraints) {
            final crossCount = constraints.maxWidth > 900 ? 4 : 2;
            return GridView.count(
              crossAxisCount: crossCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.7,
              children: const [
                _StatCard(label: 'Total Users',    value: '1,248',  icon: Icons.people,       color: AdminColors.info),
                _StatCard(label: 'Resources',      value: '326',    icon: Icons.folder,       color: AdminColors.success),
                _StatCard(label: 'Pending Review', value: '12',     icon: Icons.pending_actions, color: AdminColors.warning),
                _StatCard(label: 'Q&A Posts',      value: '589',    icon: Icons.question_answer, color: AdminColors.primary),
              ],
            );
          }),
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
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 16),
                  ..._recentActivity.map((a) => ListTile(
                        dense: true,
                        leading: Icon(a['icon'] as IconData,
                            color: a['color'] as Color, size: 20),
                        title: Text(a['text'] as String),
                        trailing: Text(a['time'] as String,
                            style: TextStyle(color: AdminColors.grey600, fontSize: 12)),
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
    {'icon': Icons.upload_file,   'color': AdminColors.success, 'text': 'New resource submitted: AQU 305 Past Questions', 'time': '2m ago'},
    {'icon': Icons.person_add,    'color': AdminColors.info,    'text': 'New user registered: student@lautech.edu.ng',     'time': '15m ago'},
    {'icon': Icons.flag,          'color': AdminColors.error,   'text': 'Content flagged for review in Q&A',               'time': '1h ago'},
    {'icon': Icons.check_circle,  'color': AdminColors.success, 'text': 'Resource approved: Fish Parasitology Notes',       'time': '2h ago'},
  ];
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

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
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: AdminColors.grey600)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

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
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                Text(label,
                    style: const TextStyle(color: AdminColors.grey600, fontSize: 12)),
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
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                          return Text(months[value.toInt() % months.length],
                              style: const TextStyle(fontSize: 11, color: AdminColors.grey600));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                ),
              ),
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
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: PieChart(PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 36,
                sections: [
                  PieChartSectionData(value: 1180, color: AdminColors.primary,   title: 'Students', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 10)),
                  PieChartSectionData(value: 42,   color: AdminColors.accent,    title: 'Mods',     radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 10)),
                  PieChartSectionData(value: 18,   color: AdminColors.info,      title: 'Lecturers',radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 10)),
                  PieChartSectionData(value: 8,    color: AdminColors.grey600,   title: 'Admins',   radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 10)),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }
}
