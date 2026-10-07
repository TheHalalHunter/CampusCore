import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/api_client.dart';

class AdminUser {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? academicLevel;
  final bool isActive;
  final String createdAt;

  const AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.academicLevel,
    required this.isActive,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id:            json['id']?.toString() ?? '',
      fullName:      json['fullName']?.toString() ??
                     json['full_name']?.toString() ?? '',
      email:         json['email']?.toString() ?? '',
      role:          json['role']?.toString() ?? 'student',
      academicLevel: json['academicLevel']?.toString() ??
                     json['academic_level']?.toString(),
      isActive:      json['isActive'] as bool? ??
                     json['is_active'] as bool? ?? true,
      createdAt:     json['createdAt']?.toString() ??
                     json['created_at']?.toString() ?? '',
    );
  }
}

final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) async {
  try {
    final response = await adminApi.get('/admin/users', params: {'limit': 100});
    final raw = response.data['data'] ?? response.data;
    List list;
    if (raw is Map) {
      // Shaped response: { users: [...], total: N }
      list = raw['users'] as List? ?? [];
    } else if (raw is List && raw.isNotEmpty && raw[0] is List) {
      // Tuple response: [[...users], count] — legacy fallback
      list = raw[0] as List;
    } else if (raw is List) {
      list = raw;
    } else {
      list = [];
    }
    return list
        .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    // ignore: avoid_print
    print('adminUsersProvider error: $e');
    return [];
  }
});
