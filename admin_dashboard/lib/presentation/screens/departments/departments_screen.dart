import 'package:flutter/material.dart';
import '../../../app/theme/admin_theme.dart';

class DepartmentsScreen extends StatelessWidget {
  const DepartmentsScreen({super.key});

  static final _departments = [
    {
      'name': 'Fisheries & Aquaculture',
      'university': 'LAUTECH',
      'courses': '24',
      'students': '312',
      'status': 'Active'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Departments',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700)),
                    Text('Manage departments and courses',
                        style: TextStyle(color: AdminColors.grey600)),
                  ]),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Department'),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                childAspectRatio: 1.4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount:
                  _departments.length + 1, // last card = "add" placeholder
              itemBuilder: (_, i) {
                if (i == _departments.length) {
                  return Card(
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(12),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline,
                              size: 36, color: AdminColors.grey600),
                          SizedBox(height: 8),
                          Text('Add Department',
                              style: TextStyle(color: AdminColors.grey600)),
                        ],
                      ),
                    ),
                  );
                }
                final dept = _departments[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    AdminColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.school,
                                  color: AdminColors.primary, size: 20),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    AdminColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(dept['status']!,
                                  style: const TextStyle(
                                      color: AdminColors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(dept['name']!,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(dept['university']!,
                            style: const TextStyle(
                                color: AdminColors.grey600, fontSize: 12)),
                        const Spacer(),
                        Row(
                          children: [
                            _Stat(label: 'Courses', value: dept['courses']!),
                            const SizedBox(width: 16),
                            _Stat(label: 'Students', value: dept['students']!),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          Text(label,
              style: const TextStyle(color: AdminColors.grey600, fontSize: 11)),
        ],
      );
}
