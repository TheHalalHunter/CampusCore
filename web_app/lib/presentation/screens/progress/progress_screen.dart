import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final cgpaProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final resp = await api.get(ApiConstants.gpaCgpa);
  final data = resp.data['data'];
  if (data is Map) return Map<String, dynamic>.from(data);
  return {};
});

final semestersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final resp = await api.get(ApiConstants.gpaSemesters);
  final data = resp.data['data'];
  if (data is List) {
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return [];
});

// ── Grade helpers (const, used by both tabs) ──────────────────────────────────

const Map<String, double> _kGradePoints = {
  'A': 5.0,
  'B': 4.0,
  'C': 3.0,
  'D': 2.0,
  'E': 1.0,
  'F': 0.0,
};

Color _gpaColor(double gpa) {
  if (gpa >= 4.5) return AppColors.success;
  if (gpa >= 3.5) return AppColors.primary;
  if (gpa >= 2.4) return AppColors.warning;
  if (gpa >= 1.5) return AppColors.cyan;
  return AppColors.error;
}

String _gpaClass(double gpa) {
  if (gpa >= 4.5) return 'First Class';
  if (gpa >= 3.5) return 'Second Class Upper';
  if (gpa >= 2.4) return 'Second Class Lower';
  if (gpa >= 1.5) return 'Third Class';
  return 'Pass';
}

Color _gradeColor(String grade) {
  switch (grade.toUpperCase()) {
    case 'A':
      return AppColors.success;
    case 'B':
      return AppColors.primary;
    case 'C':
      return AppColors.warning;
    case 'D':
      return AppColors.cyan;
    case 'E':
      return Colors.orange;
    case 'F':
      return AppColors.error;
    default:
      return AppColors.textHint;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('GPA Calculator'),
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.cyanBright,
          unselectedLabelColor: AppColors.textOnDarkSub,
          indicatorColor: AppColors.cyanBright,
          labelStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'CGPA Overview'),
            Tab(text: 'GPA Calculator'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CgpaOverviewTab(tabController: _tabController),
          _GpaCalculatorTab(tabController: _tabController),
        ],
      ),
    );
  }
}

// ── Tab 0: CGPA Overview ──────────────────────────────────────────────────────

class _CgpaOverviewTab extends ConsumerWidget {
  final TabController tabController;
  const _CgpaOverviewTab({required this.tabController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cgpaAsync = ref.watch(cgpaProvider);
    final semAsync = ref.watch(semestersProvider);
    final padding = Responsive.getPaddingEdgeInsets(context);
    final isMobile = Responsive.isMobile(context);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: padding.copyWith(bottom: 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CGPA card
              cgpaAsync.when(
                loading: () => const _LoadingCard(),
                error: (_, __) => _ErrorCard(
                  message: 'Could not load CGPA.',
                  onRetry: () => ref.invalidate(cgpaProvider),
                ),
                data: (data) {
                  final cgpa = (data['cgpa'] ?? 0.0).toDouble();
                  final totalUnits = (data['totalUnits'] ?? 0);
                  final semCount = (data['semesterCount'] ?? 0);
                  final color = _gpaColor(cgpa);
                  return _CgpaCard(
                    cgpa: cgpa,
                    totalUnits: totalUnits,
                    semCount: semCount,
                    color: color,
                    isMobile: isMobile,
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Saved Semesters',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: isMobile ? 16 : 18,
                    ),
              ),
              const SizedBox(height: 12),
              semAsync.when(
                loading: () => const _LoadingCard(),
                error: (_, __) => _ErrorCard(
                  message: 'Could not load semesters.',
                  onRetry: () => ref.invalidate(semestersProvider),
                ),
                data: (semesters) {
                  if (semesters.isEmpty) {
                    return _EmptyState(
                      onAddTap: () => tabController.animateTo(1),
                    );
                  }
                  return Column(
                    children: semesters
                        .map((s) => _SemesterCard(
                              semester: s,
                              isMobile: isMobile,
                              onDelete: () async {
                                final id = s['id']?.toString() ?? '';
                                if (id.isEmpty) return;
                                try {
                                  final api = ref.read(apiClientProvider);
                                  await api.delete(
                                      ApiConstants.deleteSemester(id));
                                  ref.invalidate(semestersProvider);
                                  ref.invalidate(cgpaProvider);
                                } catch (_) {}
                              },
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            onPressed: () => tabController.animateTo(1),
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text(
              'Add Semester',
              style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _CgpaCard extends StatelessWidget {
  final double cgpa;
  final dynamic totalUnits;
  final dynamic semCount;
  final Color color;
  final bool isMobile;

  const _CgpaCard({
    required this.cgpa,
    required this.totalUnits,
    required this.semCount,
    required this.color,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 20 : 28),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: isMobile ? 80 : 100,
                  height: isMobile ? 80 : 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.15),
                        color.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      cgpa.toStringAsFixed(2),
                      style: TextStyle(
                        color: color,
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _gpaClass(cgpa),
                          style: TextStyle(
                            color: color,
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cumulative GPA (CGPA)',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(
                  label: 'Total Units',
                  value: totalUnits.toString(),
                  icon: Icons.school_outlined,
                ),
                _StatChip(
                  label: 'Semesters',
                  value: semCount.toString(),
                  icon: Icons.calendar_month_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SemesterCard extends StatelessWidget {
  final Map<String, dynamic> semester;
  final bool isMobile;
  final VoidCallback onDelete;

  const _SemesterCard({
    required this.semester,
    required this.isMobile,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final level = semester['academicLevel']?.toString() ?? '';
    final sem = semester['semester']?.toString() ?? '';
    final year = semester['academicYear']?.toString() ?? '';
    final gpa = (semester['gpa'] ?? 0.0).toDouble();
    final totalUnits = semester['totalUnits'] ?? 0;
    final courses = semester['courses'] as List? ?? [];
    final gpaColor = _gpaColor(gpa);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: gpaColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              gpa.toStringAsFixed(1),
              style: TextStyle(
                color: gpaColor,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ),
        title: Text(
          '$level — Semester $sem${year.isNotEmpty ? ' ($year)' : ''}',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'GPA: ${gpa.toStringAsFixed(2)}  ·  $totalUnits units',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            color: AppColors.textHint,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
              onPressed: onDelete,
              tooltip: 'Delete semester',
            ),
            const Icon(Icons.expand_more, color: AppColors.textHint),
          ],
        ),
        children: [
          if (courses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No courses recorded.',
                style: TextStyle(
                    color: AppColors.textHint, fontFamily: 'Nunito'),
              ),
            )
          else
            Column(
              children: [
                const Divider(height: 1),
                const SizedBox(height: 8),
                // Header row
                Row(
                  children: const [
                    Expanded(
                        flex: 4,
                        child: Text('Course',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary))),
                    Expanded(
                        flex: 1,
                        child: Text('Units',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary))),
                    Expanded(
                        flex: 1,
                        child: Text('Grade',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary))),
                    Expanded(
                        flex: 1,
                        child: Text('GP',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary))),
                  ],
                ),
                const SizedBox(height: 4),
                ...courses
                    .whereType<Map>()
                    .map((c) {
                      final name = c['name']?.toString() ?? '';
                      final units = c['creditUnits'] ?? 0;
                      final grade = c['grade']?.toString() ?? '-';
                      final gp = (c['gradePoints'] ?? 0.0).toDouble();
                      final gc = _gradeColor(grade);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                name,
                                style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                    color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                units.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: gc.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      grade,
                                      style: TextStyle(
                                          color: gc,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          fontFamily: 'Nunito'),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                gp.toStringAsFixed(1),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList(),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTap;
  const _EmptyState({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(Icons.bar_chart_outlined,
                size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            const Text(
              'No semesters saved yet.',
              style: TextStyle(
                  color: AppColors.textHint,
                  fontFamily: 'Nunito',
                  fontSize: 15),
            ),
            const SizedBox(height: 6),
            const Text(
              'Use the GPA Calculator tab to add one.',
              style: TextStyle(
                  color: AppColors.textHint,
                  fontFamily: 'Nunito',
                  fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add),
              label: const Text('Go to Calculator'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textPrimary),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  color: AppColors.textHint),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Tab 1: GPA Calculator ─────────────────────────────────────────────────────

class _CourseRow {
  final TextEditingController nameCtrl;
  int creditUnits;
  String grade;

  _CourseRow()
      : nameCtrl = TextEditingController(),
        creditUnits = 3,
        grade = 'A';

  void dispose() => nameCtrl.dispose();
}

class _GpaCalculatorTab extends ConsumerStatefulWidget {
  final TabController tabController;
  const _GpaCalculatorTab({required this.tabController});

  @override
  ConsumerState<_GpaCalculatorTab> createState() => _GpaCalculatorTabState();
}

class _GpaCalculatorTabState extends ConsumerState<_GpaCalculatorTab> {
  final _formKey = GlobalKey<FormState>();
  String _selectedLevel = '100L';
  int _selectedSemester = 1;
  final _yearCtrl = TextEditingController();
  final List<_CourseRow> _courses = [_CourseRow()];
  bool _isSaving = false;

  static const List<String> _levels = [
    '100L',
    '200L',
    '300L',
    '400L',
    '500L',
  ];

  @override
  void dispose() {
    _yearCtrl.dispose();
    for (final c in _courses) {
      c.dispose();
    }
    super.dispose();
  }

  double get _liveGpa {
    double totalPoints = 0;
    int totalUnits = 0;
    for (final row in _courses) {
      final gp = _kGradePoints[row.grade] ?? 0.0;
      totalPoints += gp * row.creditUnits;
      totalUnits += row.creditUnits;
    }
    if (totalUnits == 0) return 0.0;
    return totalPoints / totalUnits;
  }

  int get _totalUnits {
    return _courses.fold(0, (sum, row) => sum + row.creditUnits);
  }

  Future<void> _saveSemester() async {
    // Validate all course names
    for (final row in _courses) {
      if (row.nameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Please enter a name for every course.',
            style: TextStyle(fontFamily: 'Nunito'),
          ),
          backgroundColor: AppColors.error,
        ));
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final gpa = _liveGpa;
      final totalUnits = _totalUnits;
      final coursesData = _courses.map((row) {
        return {
          'name': row.nameCtrl.text.trim(),
          'creditUnits': row.creditUnits,
          'grade': row.grade,
          'gradePoints': _kGradePoints[row.grade] ?? 0.0,
        };
      }).toList();

      final dto = {
        'academicLevel': _selectedLevel,
        'semester': _selectedSemester,
        if (_yearCtrl.text.trim().isNotEmpty)
          'academicYear': _yearCtrl.text.trim(),
        'courses': coursesData,
        'gpa': gpa,
        'totalUnits': totalUnits,
      };

      final api = ref.read(apiClientProvider);
      final resp = await api.post(ApiConstants.gpaSemesters, data: dto);
      final body = resp.data as Map<String, dynamic>;

      if (body['success'] == true) {
        ref.invalidate(semestersProvider);
        ref.invalidate(cgpaProvider);
        _resetForm();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              'Semester saved!',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
            backgroundColor: AppColors.success,
          ));
          widget.tabController.animateTo(0);
        }
      } else {
        _showError(
            body['message']?.toString() ?? 'Could not save semester.');
      }
    } catch (e) {
      _showError('Could not save semester. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    setState(() {
      for (final c in _courses) {
        c.dispose();
      }
      _courses.clear();
      _courses.add(_CourseRow());
      _selectedLevel = '100L';
      _selectedSemester = 1;
      _yearCtrl.clear();
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Nunito')),
      backgroundColor: AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getPaddingEdgeInsets(context);
    final gpa = _liveGpa;
    final gpaColor = _gpaColor(gpa);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: padding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Semester meta
                  Text(
                    'Semester Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  isMobile
                      ? Column(
                          children: [
                            _LevelDropdown(
                              value: _selectedLevel,
                              levels: _levels,
                              onChanged: (v) =>
                                  setState(() => _selectedLevel = v!),
                            ),
                            const SizedBox(height: 12),
                            _SemesterDropdown(
                              value: _selectedSemester,
                              onChanged: (v) =>
                                  setState(() => _selectedSemester = v!),
                            ),
                            const SizedBox(height: 12),
                            _YearField(controller: _yearCtrl),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _LevelDropdown(
                                value: _selectedLevel,
                                levels: _levels,
                                onChanged: (v) =>
                                    setState(() => _selectedLevel = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SemesterDropdown(
                                value: _selectedSemester,
                                onChanged: (v) =>
                                    setState(() => _selectedSemester = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _YearField(controller: _yearCtrl),
                            ),
                          ],
                        ),
                  const SizedBox(height: 24),

                  // Course header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Courses',
                          style:
                              Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _courses.add(_CourseRow())),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Course'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Course rows header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 4,
                          child: Text(
                            'Course Name',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Units',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Grade',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'GP',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: 40), // delete button space
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Course rows
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _courses.length,
                    itemBuilder: (context, index) =>
                        _buildCourseRow(index),
                  ),
                  const SizedBox(height: 80), // space for bottom bar
                ],
              ),
            ),
          ),
        ),

        // Sticky bottom bar
        _GpaBottomBar(
          gpa: gpa,
          gpaColor: gpaColor,
          totalUnits: _totalUnits,
          isSaving: _isSaving,
          onSave: _saveSemester,
        ),
      ],
    );
  }

  Widget _buildCourseRow(int index) {
    final row = _courses[index];
    final gp = _kGradePoints[row.grade] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Course name
          Expanded(
            flex: 4,
            child: TextFormField(
              controller: row.nameCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'e.g. Fisheries Biology',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Credit units
          Expanded(
            flex: 2,
            child: _CompactDropdown<int>(
              value: row.creditUnits,
              items: List.generate(6, (i) => i + 1),
              itemLabel: (v) => v.toString(),
              onChanged: (v) => setState(() => row.creditUnits = v!),
            ),
          ),
          const SizedBox(width: 8),

          // Grade
          Expanded(
            flex: 2,
            child: _CompactDropdown<String>(
              value: row.grade,
              items: _kGradePoints.keys.toList(),
              itemLabel: (v) => v,
              onChanged: (v) => setState(() => row.grade = v!),
            ),
          ),
          const SizedBox(width: 8),

          // Grade points (read-only)
          Expanded(
            flex: 2,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _gradeColor(row.grade).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _gradeColor(row.grade).withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  gp.toStringAsFixed(1),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: _gradeColor(row.grade),
                  ),
                ),
              ),
            ),
          ),

          // Delete button
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
              onPressed: _courses.length > 1
                  ? () => setState(() {
                        _courses[index].dispose();
                        _courses.removeAt(index);
                      })
                  : null,
              tooltip: 'Remove course',
            ),
          ),
        ],
      ),
    );
  }
}

class _GpaBottomBar extends StatelessWidget {
  final double gpa;
  final Color gpaColor;
  final int totalUnits;
  final bool isSaving;
  final VoidCallback onSave;

  const _GpaBottomBar({
    required this.gpa,
    required this.gpaColor,
    required this.totalUnits,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Live GPA display
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'GPA: ',
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: AppColors.textHint),
                    ),
                    Text(
                      gpa.toStringAsFixed(2),
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: gpaColor),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: gpaColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _gpaClass(gpa),
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: gpaColor),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Total Units: $totalUnits',
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: AppColors.textHint),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Save button
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: isSaving ? null : onSave,
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Semester'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable compact dropdown ─────────────────────────────────────────────────

class _CompactDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _CompactDropdown({
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          items: items
              .map((e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text(itemLabel(e)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Level/Semester/Year form fields ──────────────────────────────────────────

class _LevelDropdown extends StatelessWidget {
  final String value;
  final List<String> levels;
  final ValueChanged<String?> onChanged;

  const _LevelDropdown({
    required this.value,
    required this.levels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Academic Level'),
      style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 14, color: AppColors.textPrimary),
      items: levels
          .map((l) => DropdownMenuItem(value: l, child: Text(l)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _SemesterDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int?> onChanged;

  const _SemesterDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Semester'),
      style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 14, color: AppColors.textPrimary),
      items: const [
        DropdownMenuItem(value: 1, child: Text('Semester 1')),
        DropdownMenuItem(value: 2, child: Text('Semester 2')),
      ],
      onChanged: onChanged,
    );
  }
}

class _YearField extends StatelessWidget {
  final TextEditingController controller;
  const _YearField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
      decoration: const InputDecoration(
        labelText: 'Academic Year (optional)',
        hintText: '2024/2025',
      ),
    );
  }
}

// ── Shared loading/error widgets ──────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(
                    color: AppColors.textHint, fontFamily: 'Nunito')),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
