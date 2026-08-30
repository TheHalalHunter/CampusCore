import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/admin_theme.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/responsive.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class AdminCourseModel {
  final String id;
  final String title;
  final String courseCode;
  final String? description;
  final String departmentId;
  final int creditUnits;
  final String academicLevel;
  final int semester;
  final bool isActive;

  const AdminCourseModel({
    required this.id,
    required this.title,
    required this.courseCode,
    this.description,
    required this.departmentId,
    required this.creditUnits,
    required this.academicLevel,
    required this.semester,
    required this.isActive,
  });

  factory AdminCourseModel.fromJson(Map<String, dynamic> json) {
    return AdminCourseModel(
      id: json['id'] as String,
      title: json['title'] as String,
      courseCode: json['courseCode'] as String? ?? json['course_code'] as String? ?? '',
      description: json['description'] as String?,
      departmentId: json['departmentId'] as String? ?? json['department_id'] as String? ?? '',
      creditUnits: (json['creditUnits'] as num?)?.toInt() ?? (json['credit_units'] as num?)?.toInt() ?? 2,
      academicLevel: json['academicLevel'] as String? ?? json['academic_level'] as String? ?? '',
      semester: (json['semester'] as num?)?.toInt() ?? 1,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
    );
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final adminDepartmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await adminApi.get('/departments');
    final data = (response.data['data'] ?? response.data) as List;
    return data.cast<Map<String, dynamic>>();
  } catch (_) {
    return [];
  }
});

final adminCoursesProvider =
    FutureProvider.family<List<AdminCourseModel>, String>((ref, departmentId) async {
  try {
    final response = await adminApi.get('/courses', params: {'departmentId': departmentId});
    final data = (response.data['data'] ?? response.data) as List;
    return data.map((c) => AdminCourseModel.fromJson(c as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class CoursesManagementScreen extends ConsumerStatefulWidget {
  const CoursesManagementScreen({super.key});

  @override
  ConsumerState<CoursesManagementScreen> createState() => _CoursesManagementScreenState();
}

class _CoursesManagementScreenState extends ConsumerState<CoursesManagementScreen> {
  String? _selectedDeptId;
  String _levelFilter = 'All';
  final _levels = ['All', '100L', '200L', '300L', '400L', '500L'];

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getPadding(context);
    final deptsAsync = ref.watch(adminDepartmentsProvider);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Courses',
                        style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.w700)),
                    const Text('Manage department courses',
                        style: TextStyle(color: AdminColors.grey600)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _selectedDeptId == null
                    ? null
                    : () => _showCreateDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Course'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AdminColors.grey300,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Department picker
          deptsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (depts) => DropdownButtonFormField<String>(
              value: _selectedDeptId,
              decoration: InputDecoration(
                labelText: 'Select Department',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: depts.map((d) => DropdownMenuItem(
                value: d['id'] as String,
                child: Text(d['name'] as String? ?? ''),
              )).toList(),
              onChanged: (v) => setState(() {
                _selectedDeptId = v;
                _levelFilter = 'All';
              }),
            ),
          ),

          if (_selectedDeptId != null) ...[
            const SizedBox(height: 16),
            // Level filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _levels.map((l) {
                  final selected = _levelFilter == l;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(l),
                      selected: selected,
                      onSelected: (_) => setState(() => _levelFilter = l),
                      selectedColor: AdminColors.primary.withOpacity(0.15),
                      checkmarkColor: AdminColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? AdminColors.primary : AdminColors.grey600,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Courses table / list
            Expanded(
              child: ref.watch(adminCoursesProvider(_selectedDeptId!)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Could not load courses.')),
                data: (courses) {
                  final filtered = _levelFilter == 'All'
                      ? courses
                      : courses.where((c) => c.academicLevel == _levelFilter).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.menu_book_outlined, size: 48, color: AdminColors.grey600),
                          SizedBox(height: 12),
                          Text('No courses found',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ],
                      ),
                    );
                  }

                  return isMobile
                      ? ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _CourseCard(course: filtered[i]),
                        )
                      : Card(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                              columns: const [
                                DataColumn(label: Text('Code')),
                                DataColumn(label: Text('Title')),
                                DataColumn(label: Text('Level')),
                                DataColumn(label: Text('Semester')),
                                DataColumn(label: Text('Credits')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: filtered.map((c) => DataRow(cells: [
                                DataCell(Text(c.courseCode,
                                    style: const TextStyle(fontWeight: FontWeight.w700,
                                        color: AdminColors.primary))),
                                DataCell(Text(c.title,
                                    style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(Text(c.academicLevel)),
                                DataCell(Text('Sem ${c.semester}')),
                                DataCell(Text('${c.creditUnits} CU')),
                                DataCell(_ActiveBadge(active: c.isActive)),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 16, color: AdminColors.primary),
                                      tooltip: 'Edit',
                                      onPressed: () => _showEditDialog(context, c),
                                    ),
                                  ],
                                )),
                              ])).toList(),
                            ),
                          ),
                        );
                },
              ),
            ),
          ] else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.school_outlined, size: 56, color: AdminColors.grey600),
                    SizedBox(height: 16),
                    Text('Select a department to view courses',
                        style: TextStyle(color: AdminColors.grey600, fontSize: 15)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _CourseFormDialog(
        departmentId: _selectedDeptId!,
        onSaved: () => ref.invalidate(adminCoursesProvider(_selectedDeptId!)),
      ),
    );
  }

  void _showEditDialog(BuildContext context, AdminCourseModel course) {
    showDialog(
      context: context,
      builder: (_) => _CourseFormDialog(
        departmentId: _selectedDeptId!,
        existing: course,
        onSaved: () => ref.invalidate(adminCoursesProvider(_selectedDeptId!)),
      ),
    );
  }
}

// ─── Course card (mobile) ─────────────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  final AdminCourseModel course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AdminColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu_book_outlined,
                  color: AdminColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    '${course.courseCode} • ${course.academicLevel} • Sem ${course.semester} • ${course.creditUnits} CU',
                    style: const TextStyle(fontSize: 12, color: AdminColors.grey600),
                  ),
                ],
              ),
            ),
            _ActiveBadge(active: course.isActive),
          ],
        ),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  final bool active;
  const _ActiveBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (active ? AdminColors.success : AdminColors.grey600).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          color: active ? AdminColors.success : AdminColors.grey600,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Course form dialog (create / edit) ───────────────────────────────────────

class _CourseFormDialog extends StatefulWidget {
  final String departmentId;
  final AdminCourseModel? existing;
  final VoidCallback onSaved;

  const _CourseFormDialog({
    required this.departmentId,
    this.existing,
    required this.onSaved,
  });

  @override
  State<_CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<_CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _descCtrl;
  late String _level;
  late int _semester;
  late int _credits;
  late bool _isActive;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _codeCtrl = TextEditingController(text: e?.courseCode ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _level = e?.academicLevel ?? '100L';
    _semester = e?.semester ?? 1;
    _credits = e?.creditUnits ?? 2;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final payload = {
        'title': _titleCtrl.text.trim(),
        'courseCode': _codeCtrl.text.trim(),
        'description': _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        'departmentId': widget.departmentId,
        'academicLevel': _level,
        'semester': _semester,
        'creditUnits': _credits,
        'isActive': _isActive,
      };
      if (widget.existing != null) {
        await adminApi.patch('/courses/${widget.existing!.id}', data: payload);
      } else {
        await adminApi.post('/courses', data: payload);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AdminColors.error));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Course' : 'Add Course'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Course Title'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _codeCtrl,
                  decoration: const InputDecoration(labelText: 'Course Code (e.g. AQU 201)'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _level,
                        decoration: const InputDecoration(labelText: 'Level'),
                        items: ['100L', '200L', '300L', '400L', '500L']
                            .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                            .toList(),
                        onChanged: (v) => setState(() => _level = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _semester,
                        decoration: const InputDecoration(labelText: 'Semester'),
                        items: [1, 2]
                            .map((s) => DropdownMenuItem(value: s, child: Text('Semester $s')))
                            .toList(),
                        onChanged: (v) => setState(() => _semester = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _credits,
                        decoration: const InputDecoration(labelText: 'Credit Units'),
                        items: [1, 2, 3, 4, 5, 6]
                            .map((c) => DropdownMenuItem(value: c, child: Text('$c CU')))
                            .toList(),
                        onChanged: (v) => setState(() => _credits = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Active', style: TextStyle(fontSize: 13)),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeColor: AdminColors.primary,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.primary, foregroundColor: Colors.white),
          child: _submitting
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? 'Save Changes' : 'Create'),
        ),
      ],
    );
  }
}
