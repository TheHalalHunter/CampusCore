import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/admin_theme.dart';
import '../../../core/providers/admin_departments_provider.dart';
import '../../../core/utils/api_client.dart';

class DepartmentsScreen extends ConsumerWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(adminDepartmentsSharedProvider);

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
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Department'),
                onPressed: () => _showAddDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: deptsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Could not load departments.')),
              data: (depts) => GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: depts.length + 1,
                itemBuilder: (_, i) {
                  if (i == depts.length) {
                    return Card(
                      child: InkWell(
                        onTap: () => _showAddDialog(context, ref),
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
                  final dept = depts[i];
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
                                  color: AdminColors.primary
                                      .withValues(alpha: 0.1),
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
                                  color: (dept.isActive
                                          ? AdminColors.success
                                          : AdminColors.grey600)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  dept.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: dept.isActive
                                        ? AdminColors.success
                                        : AdminColors.grey600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(dept.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          if (dept.university != null)
                            Text(dept.university!,
                                style: const TextStyle(
                                    color: AdminColors.grey600, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _AddDepartmentDialog(
        onCreated: () => ref.invalidate(adminDepartmentsSharedProvider),
      ),
    );
  }
}

// ── Add Department Dialog ─────────────────────────────────────────────────────

class _AddDepartmentDialog extends StatefulWidget {
  final VoidCallback onCreated;
  const _AddDepartmentDialog({required this.onCreated});

  @override
  State<_AddDepartmentDialog> createState() => _AddDepartmentDialogState();
}

class _AddDepartmentDialogState extends State<_AddDepartmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _uniCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _uniCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await adminApi.post('/departments', data: {
        'name': _nameCtrl.text.trim(),
        'universityName': _uniCtrl.text.trim().isNotEmpty
            ? _uniCtrl.text.trim()
            : 'LAUTECH',
      });
      widget.onCreated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AdminColors.error));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Department'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Department Name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _uniCtrl,
                decoration: const InputDecoration(
                    labelText: 'University (optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.primary,
              foregroundColor: Colors.white),
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Create'),
        ),
      ],
    );
  }
}

