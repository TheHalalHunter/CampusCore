import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/course_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/storage/offline_cache.dart';
import 'department_provider.dart';

/// All courses for the primary department — offline-aware.
final coursesProvider = FutureProvider<List<CourseModel>>((ref) async {
  final dept = await ref.watch(primaryDepartmentProvider.future);
  if (dept == null) return [];

  final cacheKey = 'courses_${dept.id}';

  // Return fresh cache without hitting network
  if (OfflineCache.isFresh(cacheKey)) {
    final cached = OfflineCache.get<List>(cacheKey);
    if (cached != null) {
      return cached.map((c) => CourseModel.fromJson(c as Map<String, dynamic>)).toList();
    }
  }

  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get(
      ApiConstants.courses,
      queryParams: {'departmentId': dept.id},
    );
    final data = response.data['data'] ?? response.data;
    final List list = data is List ? data : [];
    await OfflineCache.put(cacheKey, list);
    return list.map((c) => CourseModel.fromJson(c as Map<String, dynamic>)).toList();
  } catch (e) {
    // Network failed — fall back to stale cache
    final stale = OfflineCache.get<List>(cacheKey);
    if (stale != null) {
      return stale.map((c) => CourseModel.fromJson(c as Map<String, dynamic>)).toList();
    }
    rethrow;
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
