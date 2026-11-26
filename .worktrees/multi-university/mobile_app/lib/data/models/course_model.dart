class CourseModel {
  final String id;
  final String title;
  final String courseCode;
  final String? description;
  final String departmentId;
  final int creditUnits;
  final String academicLevel;
  final int semester;
  final bool isActive;

  const CourseModel({
    required this.id,
    required this.title,
    required this.courseCode,
    this.description,
    required this.departmentId,
    required this.creditUnits,
    required this.academicLevel,
    required this.semester,
    required this.isActive,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String,
      title: json['title'] as String,
      courseCode: json['courseCode'] as String? ?? json['course_code'] as String? ?? '',
      description: json['description'] as String?,
      departmentId: json['departmentId'] as String? ?? json['department_id'] as String? ?? '',
      creditUnits: (json['creditUnits'] as num?)?.toInt() ??
          (json['credit_units'] as num?)?.toInt() ?? 2,
      academicLevel: json['academicLevel'] as String? ?? json['academic_level'] as String? ?? '',
      semester: (json['semester'] as num?)?.toInt() ?? 1,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
    );
  }
}
