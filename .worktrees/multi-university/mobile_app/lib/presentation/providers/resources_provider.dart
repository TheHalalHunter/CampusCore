import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/resource_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

/// Resources for a specific course (paginated, first page).
final resourcesByCourseProvider =
    FutureProvider.family<List<ResourceModel>, String>((ref, courseId) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get(
      ApiConstants.resources,
      queryParams: {'courseId': courseId, 'page': 1, 'limit': 20},
    );
    final raw = response.data['data'] ?? response.data;
    // Handle both array and [items, count] tuple
    final List items = raw is List
        ? (raw.length == 2 && raw[1] is int ? raw[0] as List : raw)
        : [];
    return items.map((r) => ResourceModel.fromJson(r as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
});

/// Resources filtered by type for a course.
final resourcesByTypeProvider =
    FutureProvider.family<List<ResourceModel>, ({String courseId, String type})>(
        (ref, params) async {
  final all = await ref.watch(
      resourcesByCourseProvider(params.courseId).future);
  if (params.type == 'all') return all;
  return all.where((r) => r.type == params.type).toList();
});
