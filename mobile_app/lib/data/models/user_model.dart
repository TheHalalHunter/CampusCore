class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? avatar;
  final String role;
  final String? departmentId;
  final String? academicLevel;
  final int reputationPoints;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatar,
    required this.role,
    this.departmentId,
    this.academicLevel,
    required this.reputationPoints,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      avatar: json['avatar'] as String?,
      role: json['role'] as String? ?? 'student',
      departmentId: json['departmentId'] as String? ?? json['department_id'] as String?,
      academicLevel: json['academicLevel'] as String? ?? json['academic_level'] as String?,
      reputationPoints: (json['reputationPoints'] as num?)?.toInt() ??
          (json['reputation_points'] as num?)?.toInt() ?? 0,
    );
  }

  String get firstName => fullName.split(' ').first;

  String get displayLevel => academicLevel ?? 'Student';
}
