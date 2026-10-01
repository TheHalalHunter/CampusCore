import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/api_client.dart';

class DepartmentModel {
  final String id;
  final String name;
  final String? university;
  final bool isActive;

  const DepartmentModel({
    required this.id,
    required this.name,
    this.university,
    required this.isActive,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id:         json['id']?.toString() ?? '',
      name:       json['name']?.toString() ?? '',
      university: json['university']?.toString(),
      isActive:   json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
    );
  }
}

final adminDepartmentsSharedProvider =
    FutureProvider<List<DepartmentModel>>((ref) async {
  try {
    final response = await adminApi.get('/departments');
    final data = (response.data['data'] ?? response.data) as List;
    return data
        .map((e) => DepartmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});
