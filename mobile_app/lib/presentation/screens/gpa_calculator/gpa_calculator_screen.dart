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
  int? _totalUnits;

  /// Nigerian 5-point grading scale
  static const Map<String, double> _gradePoints = {
    'A': 5.0,
    'B': 4.0,
    'C': 3.0,
    'D': 2.0,
    'E': 1.0,
    'F': 0.0,
  };

  void _calculate() {
    double totalPoints = 0;
    int totalUnits = 0;
    bool hasError = false;

    for (final e in _entries) {
      final units = int.tryParse(e.unitsCtrl.text.trim());
      if (units == null || units <= 0) {
        hasError = true;
        break;
      }
      final points = _gradePoints[e.selectedGrade] ?? 0;
      totalPoints += units * points;
      totalUnits += units;
    }

    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid credit units for all courses.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _gpa = totalUnits > 0 ? totalPoints / totalUnits : 0;
      _totalUnits = totalUnits;
    });
  }

  void _reset() {
    setState(() {
      _entries.clear();
      _entries.add(_CourseEntry());
      _gpa = null;
      _totalUnits = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPA Calculator'),
        actions: [
          if (_gpa != null)
            TextButton(
              onPressed: _reset,
              child: const Text('Reset', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Result card
            if (_gpa != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your GPA',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _gpa!.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _gradeClass(_gpa!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Total Credit Units: $_totalUnits',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Grading scale info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nigerian 5-point scale: A=5.0  B=4.0  C=3.0  D=2.0  E=1.0  F=0.0',
                      style: const TextStyle(
                        color: AppColors.info,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Column headers
            const Row(
              children: [
                Text(
                  'Courses',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Course Title / Code',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: const Text(
                    'Units',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: const Text(
                    'Grade',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 8),

            // Course entries
            ..._entries.asMap().entries.map((entry) {
              final idx = entry.key;
              final e = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // Course name
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: e.nameCtrl,
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'e.g. AQU 201',
                          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                          filled: true,
                          fillColor: AppColors.grey100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Credit units
                    SizedBox(
                      width: 64,
                      child: TextField(
                        controller: e.unitsCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '2',
                          hintStyle: const TextStyle(color: AppColors.textHint),
                          filled: true,
                          fillColor: AppColors.grey100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Grade dropdown
                    Container(
                      width: 72,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: e.selectedGrade,
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          items: _gradePoints.keys
                              .map((g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(
                                      '$g (${_gradePoints[g]!.toStringAsFixed(1)})',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (g) => setState(() => e.selectedGrade = g ?? 'A'),
                        ),
                      ),
                    ),

                    // Remove button
                    IconButton(
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: _entries.length > 1 ? AppColors.error : AppColors.grey200,
                        size: 22,
                      ),
                      onPressed: _entries.length > 1
                          ? () => setState(() => _entries.removeAt(idx))
                          : null,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),

            // Add course button
            TextButton.icon(
              onPressed: () => setState(() => _entries.add(_CourseEntry())),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('Add Course'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
            const SizedBox(height: 24),

            // Calculate button
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('Calculate GPA'),
            ),

            // Grade classes reference
            const SizedBox(height: 32),
            const Text(
              'Grade Classes',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _GradeClassTable(),
          ],
        ),
      ),
    );
  }

  String _gradeClass(double gpa) {
    if (gpa >= 4.5) return 'First Class';
    if (gpa >= 3.5) return 'Second Class Upper';
    if (gpa >= 2.4) return 'Second Class Lower';
    if (gpa >= 1.5) return 'Third Class';
    return 'Fail';
  }
}

// ─── Grade class reference table ─────────────────────────────────────────────

class _GradeClassTable extends StatelessWidget {
  final _classes = const [
    {'range': '4.50 – 5.00', 'class': 'First Class', 'color': Color(0xFF16A34A)},
    {'range': '3.50 – 4.49', 'class': 'Second Class Upper', 'color': Color(0xFF2563EB)},
    {'range': '2.40 – 3.49', 'class': 'Second Class Lower', 'color': Color(0xFF7C3AED)},
    {'range': '1.50 – 2.39', 'class': 'Third Class', 'color': Color(0xFFD97706)},
    {'range': '0.00 – 1.49', 'class': 'Fail', 'color': Color(0xFFDC2626)},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: _classes.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: i < _classes.length - 1
                  ? const Border(
                      bottom: BorderSide(color: AppColors.border, width: 0.8),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['class'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  item['range'] as String,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Course entry data ────────────────────────────────────────────────────────

class _CourseEntry {
  final nameCtrl = TextEditingController();
  final unitsCtrl = TextEditingController(text: '2');
  String selectedGrade = 'A';
}
