import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/course_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import 'department_provider.dart';

/// All courses for the primary department.
final coursesProvider = FutureProvider<List<CourseModel>>((ref) async {
  final dept = await ref.watch(primaryDepartmentProvider.future);
  if (dept == null) return [];
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get(
      ApiConstants.courses,
      queryParams: {'departmentId': dept.id},
    );
    final data = response.data['data'] ?? response.data;
    return (data as List).map((c) => CourseModel.fromJson(c)).toList();
  } catch (_) {
    return [];
  }
});

/// Courses filtered by academic level.
final coursesByLevelProvider = FutureProvider.family<List<CourseModel>, String>((ref, level) async {
  final all = await ref.watch(coursesProvider.future);
  return all.where((c) => c.academicLevel == level).toList();
});

/// Available academic levels derived from courses.
final academicLevelsProvider = FutureProvider<List<String>>((ref) async {
  final all = await ref.watch(coursesProvider.future);
  final levels = all.map((c) => c.academicLevel).toSet().toList();
  levels.sort();
  return levels;
});
