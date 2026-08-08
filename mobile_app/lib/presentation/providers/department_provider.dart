import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/department_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

/// All active departments.
final departmentsProvider = FutureProvider<List<DepartmentModel>>((ref) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get(ApiConstants.departments);
    final data = response.data['data'] ?? response.data;
    return (data as List).map((d) => DepartmentModel.fromJson(d)).toList();
  } catch (_) {
    return [];
  }
});

/// The first (and currently only) department — Fisheries & Aquaculture.
final primaryDepartmentProvider = FutureProvider<DepartmentModel?>((ref) async {
  final depts = await ref.watch(departmentsProvider.future);
  return depts.isNotEmpty ? depts.first : null;
});
