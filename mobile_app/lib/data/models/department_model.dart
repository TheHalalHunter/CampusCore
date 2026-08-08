class DepartmentModel {
  final String id;
  final String name;
  final String universityName;
  final bool isActive;

  const DepartmentModel({
    required this.id,
    required this.name,
    required this.universityName,
    required this.isActive,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      universityName: json['universityName'] as String? ??
          json['university_name'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
    );
  }
}
