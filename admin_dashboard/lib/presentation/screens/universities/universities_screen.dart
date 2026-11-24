import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/admin_theme.dart';
import '../../../core/utils/api_client.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _universitiesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final resp = await adminApi.get('/universities');
  final data = resp.data['data'] ?? resp.data;
  if (data is List) return data.cast<Map<String, dynamic>>();
  return [];
});

// ── Screen ────────────────────────────────────────────────────────────────────

class UniversitiesScreen extends ConsumerWidget {
  const UniversitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unisAsync = ref.watch(_universitiesProvider);

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
                  Text('Universities',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w700)),
                  Text('Manage universities on the platform',
                      style: TextStyle(color: AdminColors.grey600)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add University'),
                onPressed: () => _showDialog(context, ref, existing: null),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: unisAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('Could not load universities: $e',
                      style: const TextStyle(color: AdminColors.error))),
              data: (unis) {
                if (unis.isEmpty) {
                  return const Center(
                      child: Text('No universities yet.',
                          style: TextStyle(color: AdminColors.grey600)));
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        AdminColors.sidebar.withValues(alpha: 0.06)),
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Short Name')),
                      DataColumn(label: Text('State')),
                      DataColumn(label: Text('Country')),
                      DataColumn(label: Text('Active')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: unis.map((u) {
                      final isActive = u['isActive'] as bool? ?? true;
                      return DataRow(cells: [
                        DataCell(Text(u['name']?.toString() ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600))),
                        DataCell(Text(u['shortName']?.toString() ?? '—')),
                        DataCell(Text(u['state']?.toString() ?? '—')),
                        DataCell(Text(u['country']?.toString() ?? '—')),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isActive
                                    ? AdminColors.success
                                    : AdminColors.grey600)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: isActive
                                  ? AdminColors.success
                                  : AdminColors.grey600,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )),
                        DataCell(IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: AdminColors.primary),
                          tooltip: 'Edit',
                          onPressed: () =>
                              _showDialog(context, ref, existing: u),
                        )),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref,
      {required Map<String, dynamic>? existing}) {
    showDialog(
      context: context,
      builder: (_) => _UniversityDialog(
        existing: existing,
        onSaved: () => ref.invalidate(_universitiesProvider),
      ),
    );
  }
}

// ── Add / Edit Dialog ─────────────────────────────────────────────────────────

class _UniversityDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;

  const _UniversityDialog({required this.existing, required this.onSaved});

  @override
  State<_UniversityDialog> createState() => _UniversityDialogState();
}

class _UniversityDialogState extends State<_UniversityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _shortNameCtrl;
  late final TextEditingController _stateCtrl;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?['name']?.toString() ?? '');
    _shortNameCtrl =
        TextEditingController(text: e?['shortName']?.toString() ?? '');
    _stateCtrl = TextEditingController(text: e?['state']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortNameCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final payload = {
        'name': _nameCtrl.text.trim(),
        if (_shortNameCtrl.text.trim().isNotEmpty)
          'shortName': _shortNameCtrl.text.trim(),
        if (_stateCtrl.text.trim().isNotEmpty)
          'state': _stateCtrl.text.trim(),
      };

      if (_isEdit) {
        await adminApi.patch(
            '/universities/${widget.existing!['id']}',
            data: payload);
      } else {
        await adminApi.post('/universities', data: payload);
      }

      widget.onSaved();
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
      title: Text(_isEdit ? 'Edit University' : 'Add University'),
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
                    const InputDecoration(labelText: 'University Name *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _shortNameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Short Name (e.g. LAUTECH)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stateCtrl,
                decoration: const InputDecoration(labelText: 'State'),
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
              : Text(_isEdit ? 'Save Changes' : 'Create'),
        ),
      ],
    );
  }
}
