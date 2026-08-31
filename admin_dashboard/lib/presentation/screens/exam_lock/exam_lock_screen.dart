import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/admin_theme.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/responsive.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class ExamLockModel {
  final String id;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool lockAI;
  final bool lockDiscussions;
  final String? academicLevel;
  final String? reason;
  final bool active;

  const ExamLockModel({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.lockAI,
    required this.lockDiscussions,
    this.academicLevel,
    this.reason,
    required this.active,
  });

  factory ExamLockModel.fromJson(Map<String, dynamic> json) {
    return ExamLockModel(
      id: json['id'] as String,
      name: json['name'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String? ?? json['starts_at'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String? ?? json['ends_at'] as String),
      lockAI: json['lockAI'] as bool? ?? json['lock_ai'] as bool? ?? true,
      lockDiscussions: json['lockDiscussions'] as bool? ?? json['lock_discussions'] as bool? ?? true,
      academicLevel: json['academicLevel'] as String? ?? json['academic_level'] as String?,
      reason: json['reason'] as String?,
      active: json['active'] as bool? ?? false,
    );
  }

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return active && now.isAfter(startsAt) && now.isBefore(endsAt);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final examLocksProvider = FutureProvider<List<ExamLockModel>>((ref) async {
  try {
    final response = await adminApi.get('/exam-lock');
    final data = (response.data['data'] ?? response.data) as List;
    return data.map((e) => ExamLockModel.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class ExamLockScreen extends ConsumerStatefulWidget {
  const ExamLockScreen({super.key});

  @override
  ConsumerState<ExamLockScreen> createState() => _ExamLockScreenState();
}

class _ExamLockScreenState extends ConsumerState<ExamLockScreen> {
  final _fmt = DateFormat('dd MMM yyyy, HH:mm');

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getPadding(context);
    final locksAsync = ref.watch(examLocksProvider);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exam Lock',
                        style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.w700)),
                    Text('Control AI and discussion access during exams',
                        style: const TextStyle(color: AdminColors.grey600)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Lock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          locksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Could not load exam locks.')),
            data: (locks) {
              if (locks.isEmpty) {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock_clock_outlined, size: 56, color: AdminColors.grey600),
                        SizedBox(height: 16),
                        Text('No exam locks configured',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        SizedBox(height: 8),
                        Text('Create a lock to restrict AI and discussions during exams.',
                            style: TextStyle(color: AdminColors.grey600)),
                      ],
                    ),
                  ),
                );
              }

              return Expanded(
                child: isMobile
                    ? ListView.separated(
                        itemCount: locks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _LockCard(lock: locks[i], fmt: _fmt, onDelete: _delete),
                      )
                    : Card(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Level')),
                              DataColumn(label: Text('Starts')),
                              DataColumn(label: Text('Ends')),
                              DataColumn(label: Text('Locks')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: locks.map((lock) {
                              return DataRow(cells: [
                                DataCell(Text(lock.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(Text(lock.academicLevel ?? 'All Levels')),
                                DataCell(Text(_fmt.format(lock.startsAt))),
                                DataCell(Text(_fmt.format(lock.endsAt))),
                                DataCell(Row(
                                  children: [
                                    if (lock.lockAI)
                                      _FeatureChip(label: 'AI', color: AdminColors.error),
                                    if (lock.lockAI && lock.lockDiscussions)
                                      const SizedBox(width: 4),
                                    if (lock.lockDiscussions)
                                      _FeatureChip(label: 'Discussions', color: AdminColors.warning),
                                  ],
                                )),
                                DataCell(_StatusBadge(active: lock.isCurrentlyActive)),
                                DataCell(IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18, color: AdminColors.error),
                                  tooltip: 'Delete',
                                  onPressed: () => _delete(lock.id),
                                )),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Exam Lock'),
        content: const Text('This will remove the lock. Active restrictions will lift immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AdminColors.error))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await adminApi.delete('/exam-lock/$id');
      ref.invalidate(examLocksProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not delete.'), backgroundColor: AdminColors.error));
      }
    }
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _CreateLockDialog(onCreated: () => ref.invalidate(examLocksProvider)),
    );
  }
}

// ─── Create dialog ────────────────────────────────────────────────────────────

class _CreateLockDialog extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateLockDialog({required this.onCreated});

  @override
  State<_CreateLockDialog> createState() => _CreateLockDialogState();
}

class _CreateLockDialogState extends State<_CreateLockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  DateTime _startsAt = DateTime.now().add(const Duration(hours: 1));
  DateTime _endsAt = DateTime.now().add(const Duration(hours: 25));
  bool _lockAI = true;
  bool _lockDiscussions = true;
  String? _level;
  bool _submitting = false;
  final _fmt = DateFormat('dd MMM yyyy, HH:mm');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDateTimePicker(context, isStart ? _startsAt : _endsAt);
    if (picked != null) {
      setState(() {
        if (isStart) _startsAt = picked;
        else _endsAt = picked;
      });
    }
  }

  Future<DateTime?> showDateTimePicker(BuildContext ctx, DateTime initial) async {
    final date = await showDatePicker(
        context: ctx,
        initialDate: initial,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null) return null;
    final time = await showTimePicker(
        context: ctx, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endsAt.isBefore(_startsAt)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('End time must be after start time.'),
          backgroundColor: AdminColors.error));
      return;
    }
    setState(() => _submitting = true);
    try {
      await adminApi.post('/exam-lock', data: {
        'name': _nameCtrl.text.trim(),
        'startsAt': _startsAt.toIso8601String(),
        'endsAt': _endsAt.toIso8601String(),
        'lockAI': _lockAI,
        'lockDiscussions': _lockDiscussions,
        if (_level != null) 'academicLevel': _level,
        if (_reasonCtrl.text.trim().isNotEmpty) 'reason': _reasonCtrl.text.trim(),
      });
      widget.onCreated();
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
    return AlertDialog(
      title: const Text('Create Exam Lock'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Lock Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: _level,
                  decoration: const InputDecoration(labelText: 'Academic Level (optional)'),
                  items: [null, '100L', '200L', '300L', '400L', '500L']
                      .map((l) => DropdownMenuItem(value: l, child: Text(l ?? 'All Levels')))
                      .toList(),
                  onChanged: (v) => setState(() => _level = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(true),
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Starts At'),
                          child: Text(_fmt.format(_startsAt), style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(false),
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Ends At'),
                          child: Text(_fmt.format(_endsAt), style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Restrictions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                SwitchListTile(
                  dense: true,
                  title: const Text('Lock AI Assistant', style: TextStyle(fontSize: 13)),
                  value: _lockAI,
                  onChanged: (v) => setState(() => _lockAI = v),
                  activeColor: AdminColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  dense: true,
                  title: const Text('Lock Discussions & Q&A', style: TextStyle(fontSize: 13)),
                  value: _lockDiscussions,
                  onChanged: (v) => setState(() => _lockDiscussions = v),
                  activeColor: AdminColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Reason (optional)'),
                  maxLines: 2,
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
              : const Text('Create'),
        ),
      ],
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _LockCard extends StatelessWidget {
  final ExamLockModel lock;
  final DateFormat fmt;
  final void Function(String) onDelete;
  const _LockCard({required this.lock, required this.fmt, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(lock.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                _StatusBadge(active: lock.isCurrentlyActive),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AdminColors.error, size: 18),
                  onPressed: () => onDelete(lock.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${fmt.format(lock.startsAt)} → ${fmt.format(lock.endsAt)}',
                style: const TextStyle(color: AdminColors.grey600, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(lock.academicLevel ?? 'All Levels',
                    style: const TextStyle(fontSize: 12, color: AdminColors.grey600)),
                const Spacer(),
                if (lock.lockAI) _FeatureChip(label: 'AI Locked', color: AdminColors.error),
                if (lock.lockAI && lock.lockDiscussions) const SizedBox(width: 4),
                if (lock.lockDiscussions)
                  _FeatureChip(label: 'Discussions Locked', color: AdminColors.warning),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final Color color;
  const _FeatureChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (active ? AdminColors.error : AdminColors.grey600).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        active ? 'ACTIVE' : 'Inactive',
        style: TextStyle(
          color: active ? AdminColors.error : AdminColors.grey600,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
