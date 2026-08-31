import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../providers/gpa_provider.dart';

class GpaCalculatorScreen extends ConsumerStatefulWidget {
  const GpaCalculatorScreen({super.key});

  @override
  ConsumerState<GpaCalculatorScreen> createState() => _GpaCalculatorScreenState();
}

class _GpaCalculatorScreenState extends ConsumerState<GpaCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final List<_CourseEntry> _entries = [_CourseEntry()];
  double? _gpa;
  int? _totalUnits;
  String _selectedLevel = '100L';
  int _selectedSemester = 1;
  final _yearCtrl = TextEditingController();

  static const Map<String, double> _gradePoints = {
    'A': 5.0, 'B': 4.0, 'C': 3.0, 'D': 2.0, 'E': 1.0, 'F': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    double totalPoints = 0;
    int totalUnits = 0;
    bool hasError = false;

    for (final e in _entries) {
      final units = int.tryParse(e.unitsCtrl.text.trim());
      if (units == null || units <= 0) { hasError = true; break; }
      totalPoints += units * (_gradePoints[e.selectedGrade] ?? 0);
      totalUnits += units;
    }

    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter valid credit units for all courses.'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    setState(() {
      _gpa = totalUnits > 0 ? totalPoints / totalUnits : 0;
      _totalUnits = totalUnits;
    });
  }

  Future<void> _save() async {
    if (_gpa == null) { _calculate(); return; }

    final courses = _entries.map((e) => GpaCourseModel(
      name: e.nameCtrl.text.trim().isEmpty ? 'Course' : e.nameCtrl.text.trim(),
      creditUnits: int.tryParse(e.unitsCtrl.text.trim()) ?? 2,
      grade: e.selectedGrade,
      gradePoints: _gradePoints[e.selectedGrade] ?? 0,
    )).toList();

    final ok = await ref.read(gpaActionsProvider.notifier).saveSemester(
      academicLevel: _selectedLevel,
      semester: _selectedSemester,
      academicYear: _yearCtrl.text.trim().isNotEmpty ? _yearCtrl.text.trim() : null,
      courses: courses,
      gpa: _gpa!,
      totalUnits: _totalUnits!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Semester saved!' : 'Could not save. Try again.'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ));
      if (ok) _tabCtrl.animateTo(1);
    }
  }

  void _reset() => setState(() {
    _entries.clear();
    _entries.add(_CourseEntry());
    _gpa = null;
    _totalUnits = null;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPA Calculator'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Calculator'),
            Tab(text: 'My GPA'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildCalculator(),
          _buildSavedGpa(),
        ],
      ),
    );
  }

  // ─── Calculator tab ─────────────────────────────────────────────────────────

  Widget _buildCalculator() {
    return SingleChildScrollView(
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
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(children: [
                const Text('Your GPA', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(_gpa!.toStringAsFixed(2),
                    style: const TextStyle(color: Colors.white, fontSize: 56,
                        fontWeight: FontWeight.w700, height: 1)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_gradeClass(_gpa!),
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                const SizedBox(height: 12),
                Text('Total Credit Units: $_totalUnits',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save Semester'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(onPressed: _reset, child: const Text('Reset')),
            ]),
            const SizedBox(height: 24),
          ],

          // Semester selector
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedLevel,
                decoration: const InputDecoration(labelText: 'Level'),
                items: ['100L','200L','300L','400L','500L']
                    .map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) => setState(() => _selectedLevel = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedSemester,
                decoration: const InputDecoration(labelText: 'Semester'),
                items: [1, 2].map((s) =>
                    DropdownMenuItem(value: s, child: Text('Semester $s'))).toList(),
                onChanged: (v) => setState(() => _selectedSemester = v!),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _yearCtrl,
            decoration: const InputDecoration(
              labelText: 'Academic Year (optional)',
              hintText: 'e.g. 2024/2025',
            ),
          ),
          const SizedBox(height: 20),

          // Scale info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: AppColors.info, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Nigerian 5-point scale: A=5.0  B=4.0  C=3.0  D=2.0  E=1.0  F=0.0',
                    style: TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Column headers
          const Row(children: [
            Expanded(flex: 3, child: Text('Course Title / Code',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
            SizedBox(width: 64, child: Center(child: Text('Units',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)))),
            SizedBox(width: 8),
            SizedBox(width: 72, child: Center(child: Text('Grade',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)))),
            SizedBox(width: 40),
          ]),
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
              child: Row(children: [
                Expanded(flex: 3,
                  child: TextField(
                    controller: e.nameCtrl,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. AQU 201',
                      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                      filled: true, fillColor: AppColors.grey100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 64,
                  child: TextField(
                    controller: e.unitsCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: '2', hintStyle: const TextStyle(color: AppColors.textHint),
                      filled: true, fillColor: AppColors.grey100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: e.selectedGrade,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                      items: _gradePoints.keys.map((g) => DropdownMenuItem(
                          value: g,
                          child: Text('$g (${_gradePoints[g]!.toStringAsFixed(1)})',
                              style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (g) => setState(() => e.selectedGrade = g ?? 'A'),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline,
                      color: _entries.length > 1 ? AppColors.error : AppColors.grey200, size: 22),
                  onPressed: _entries.length > 1 ? () => setState(() => _entries.removeAt(idx)) : null,
                ),
              ]),
            );
          }),

          TextButton.icon(
            onPressed: () => setState(() => _entries.add(_CourseEntry())),
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text('Add Course'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          const SizedBox(height: 24),

          ElevatedButton(onPressed: _calculate, child: const Text('Calculate GPA')),

          const SizedBox(height: 32),
          const Text('Grade Classes',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          _GradeClassTable(),
        ],
      ),
    );
  }

  // ─── Saved GPA tab ──────────────────────────────────────────────────────────

  Widget _buildSavedGpa() {
    final semestersAsync = ref.watch(gpaSemestersProvider);
    final cgpaAsync = ref.watch(cgpaProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CGPA card
          cgpaAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (cgpa) {
              if (cgpa == null || cgpa.semesters == 0) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(children: [
                  const Text('Cumulative GPA',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(cgpa.cgpa.toStringAsFixed(2),
                      style: const TextStyle(color: Colors.white, fontSize: 52,
                          fontWeight: FontWeight.w700, height: 1)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(cgpa.gradeClass,
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  const SizedBox(height: 10),
                  Text('${cgpa.semesters} semester(s) • ${cgpa.totalUnits} total units',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
              );
            },
          ),

          // Semesters list
          semestersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Could not load saved GPA.')),
            data: (semesters) {
              if (semesters.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: const [
                    SizedBox(height: 40),
                    Icon(Icons.calculate_outlined, size: 56, color: AppColors.grey400),
                    SizedBox(height: 16),
                    Text('No saved semesters yet',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Calculate your GPA and tap Save to record it here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary)),
                  ]),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Saved Semesters',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  ...semesters.map((s) => _SemesterCard(
                    semester: s,
                    onDelete: () async {
                      final ok = await ref.read(gpaActionsProvider.notifier).deleteSemester(s.id);
                      if (mounted && ok) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Semester deleted.'),
                        ));
                      }
                    },
                  )),
                ],
              );
            },
          ),
        ],
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

// ─── Semester card ────────────────────────────────────────────────────────────

class _SemesterCard extends StatelessWidget {
  final GpaSemesterModel semester;
  final VoidCallback onDelete;
  const _SemesterCard({required this.semester, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(semester.label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(
          '${semester.academicYear ?? ''} • GPA: ${semester.gpa.toStringAsFixed(2)} • ${semester.totalUnits} units',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(semester.gpa.toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.w700,
                    color: AppColors.primary, fontSize: 15)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
            onPressed: onDelete,
          ),
        ]),
        children: semester.courses.map((c) => ListTile(
          dense: true,
          title: Text(c.name, style: const TextStyle(fontSize: 13)),
          trailing: Text('${c.grade} · ${c.creditUnits} CU',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        )).toList(),
      ),
    );
  }
}

// ─── Grade class table ────────────────────────────────────────────────────────

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
                  ? const Border(bottom: BorderSide(color: AppColors.border, width: 0.8))
                  : null,
            ),
            child: Row(children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(color: item['color'] as Color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(child: Text(item['class'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                      color: AppColors.textPrimary))),
              Text(item['range'] as String,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Course entry ─────────────────────────────────────────────────────────────

class _CourseEntry {
  final nameCtrl = TextEditingController();
  final unitsCtrl = TextEditingController(text: '2');
  String selectedGrade = 'A';
}
