import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/resource_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/storage/offline_cache.dart';

/// Cache key for a given course's resources.
String _cacheKey(String courseId) => 'resources_course_$courseId';

/// Offline-aware resources provider.
///
/// Strategy:
///   1. If fresh cache exists (< 24 h), return cached data immediately.
///   2. Always try the network; on success update the cache.
///   3. If network fails and stale cache exists, return stale data.
///   4. If no cache at all, rethrow so the UI can show an error.
final offlineResourcesProvider =
    FutureProvider.family<List<ResourceModel>, String>((ref, courseId) async {
  final cacheKey = _cacheKey(courseId);

  // Return fresh cache without hitting network
  if (OfflineCache.isFresh(cacheKey)) {
    final cached = OfflineCache.get<List>(cacheKey);
    if (cached != null) {
      return cached
          .map((r) => ResourceModel.fromJson(r as Map<String, dynamic>))
          .toList();
    }
  }

  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get(
      ApiConstants.resources,
      queryParams: {'courseId': courseId},
    );
    final data = response.data['data'] ?? response.data;
    final resources = (data as List)
        .map((r) => ResourceModel.fromJson(r as Map<String, dynamic>))
        .toList();

    // Update cache
    await OfflineCache.put(cacheKey, data);
    return resources;
  } catch (e) {
    // Network failed — fall back to stale cache if available
    final stale = OfflineCache.get<List>(cacheKey);
    if (stale != null) {
      return stale
          .map((r) => ResourceModel.fromJson(r as Map<String, dynamic>))
          .toList();
    }
    rethrow;
  }
});

/// Offline-aware courses provider for a department.
String _coursesCacheKey(String departmentId) => 'courses_dept_$departmentId';

final offlineCoursesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, departmentId) async {
  final cacheKey = _coursesCacheKey(departmentId);

  if (OfflineCache.isFresh(cacheKey)) {
    final cached = OfflineCache.get<List>(cacheKey);
    if (cached != null) {
      return cached.cast<Map<String, dynamic>>();
    }
  }

  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get(
      ApiConstants.courses,
      queryParams: {'departmentId': departmentId},
    );
    final data = response.data['data'] ?? response.data;
    await OfflineCache.put(cacheKey, data);
    return (data as List).cast<Map<String, dynamic>>();
  } catch (e) {
    final stale = OfflineCache.get<List>(cacheKey);
    if (stale != null) return stale.cast<Map<String, dynamic>>();
    rethrow;
  }
});

/// Manually bust the resource cache for a course (e.g. after upload).
Future<void> bustResourceCache(String courseId) async {
  await OfflineCache.remove(_cacheKey(courseId));
}
