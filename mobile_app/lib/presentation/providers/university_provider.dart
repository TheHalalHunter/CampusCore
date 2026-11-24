import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/department_model.dart';

final universitiesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get(ApiConstants.universities);
    final data = response.data['data'] ?? response.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
  } catch (_) {}
  return [];
});

final departmentsByUniversityProvider =
    FutureProvider.family<List<DepartmentModel>, String?>((ref, universityId) async {
  try {
    final api = ref.read(apiClientProvider);
    final path = universityId != null
        ? '${ApiConstants.departments}?universityId=$universityId'
        : ApiConstants.departments;
    final response = await api.get(path);
    final data = response.data['data'] ?? response.data;
    return (data as List).map((d) => DepartmentModel.fromJson(d)).toList();
  } catch (_) {
    return [];
  }
});
