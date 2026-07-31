import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';

class GpaCalculatorScreen extends ConsumerStatefulWidget {
  const GpaCalculatorScreen({super.key});

  @override
  ConsumerState<GpaCalculatorScreen> createState() => _GpaCalculatorScreenState();
}

class _GpaCalculatorScreenState extends ConsumerState<GpaCalculatorScreen> {
  final List<_CourseEntry> _entries = [_CourseEntry()];
  double? _gpa;

  /// Nigerian 5-point grading scale
  static const Map<String, double> _gradePoints = {
    'A': 5.0, 'B': 4.0, 'C': 3.0, 'D': 2.0, 'E': 1.0, 'F': 0.0,
  };

  void _calculate() {
    double totalPoints = 0;
    int totalUnits = 0;
    for (final e in _entries) {
      final units = int.tryParse(e.unitsCtrl.text) ?? 0;
      final points = _gradePoints[e.selectedGrade] ?? 0;
      totalPoints += units * points;
      totalUnits += units;
    }
    setState(() => _gpa = totalUnits > 0 ? totalPoints / totalUnits : 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GPA Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Result card
            if (_gpa != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('Your GPA', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(
                      _gpa!.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white, fontSize: 48, fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _gradeClass(_gpa!),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            const Text('Courses', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),

            // Course entries
            ..._entries.asMap().entries.map((entry) {
              final idx = entry.key;
              final e = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: e.nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Course', hintText: 'AQU 201',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: e.unitsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Units'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: e.selectedGrade,
                        items: _gradePoints.keys
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (g) => setState(() => e.selectedGrade = g ?? 'A'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                        onPressed: _entries.length > 1
                            ? () => setState(() => _entries.removeAt(idx))
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),

            TextButton.icon(
              onPressed: () => setState(() => _entries.add(_CourseEntry())),
              icon: const Icon(Icons.add),
              label: const Text('Add Course'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('Calculate GPA'),
            ),
          ],
        ),
      ),
    );
  }

  String _gradeClass(double gpa) {
    if (gpa >= 4.5) return 'First Class Distinction';
    if (gpa >= 3.5) return 'Second Class Upper';
    if (gpa >= 2.4) return 'Second Class Lower';
    if (gpa >= 1.5) return 'Third Class';
    return 'Fail';
  }
}

class _CourseEntry {
  final nameCtrl = TextEditingController();
  final unitsCtrl = TextEditingController(text: '2');
  String selectedGrade = 'A';
}
