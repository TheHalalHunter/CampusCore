import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/resource_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

/// Resources for a specific course.
final resourcesByCourseProvider =
    FutureProvider.family<List<ResourceModel>, String>((ref, courseId) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get(
      ApiConstants.resources,
      queryParams: {'courseId': courseId},
    );
    final data = response.data['data'] ?? response.data;
    return (data as List).map((r) => ResourceModel.fromJson(r)).toList();
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
