import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class GpaCourseModel {
  final String name;
  final int creditUnits;
  final String grade;
  final double gradePoints;

  const GpaCourseModel({
    required this.name,
    required this.creditUnits,
    required this.grade,
    required this.gradePoints,
  });

  factory GpaCourseModel.fromJson(Map<String, dynamic> json) => GpaCourseModel(
        name: json['name'] as String? ?? '',
        creditUnits: (json['creditUnits'] as num?)?.toInt() ?? 0,
        grade: json['grade'] as String? ?? 'A',
        gradePoints: (json['gradePoints'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'creditUnits': creditUnits,
        'grade': grade,
        'gradePoints': gradePoints,
      };
}

class GpaSemesterModel {
  final String id;
  final String academicLevel;
  final int semester;
  final String? academicYear;
  final List<GpaCourseModel> courses;
  final double gpa;
  final int totalUnits;

  const GpaSemesterModel({
    required this.id,
    required this.academicLevel,
    required this.semester,
    this.academicYear,
    required this.courses,
    required this.gpa,
    required this.totalUnits,
  });

  factory GpaSemesterModel.fromJson(Map<String, dynamic> json) {
    return GpaSemesterModel(
      id: json['id'] as String,
      academicLevel: json['academicLevel'] as String? ?? json['academic_level'] as String? ?? '',
      semester: (json['semester'] as num?)?.toInt() ?? 1,
      academicYear: json['academicYear'] as String? ?? json['academic_year'] as String?,
      courses: (json['courses'] as List? ?? [])
          .map((c) => GpaCourseModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      gpa: (json['gpa'] as num?)?.toDouble() ?? 0,
      totalUnits: (json['totalUnits'] as num?)?.toInt() ?? (json['total_units'] as num?)?.toInt() ?? 0,
    );
  }

  String get label => '$academicLevel Semester $semester';
}

class CgpaModel {
  final double cgpa;
  final int totalUnits;
  final int semesters;
  final String gradeClass;

  const CgpaModel({
    required this.cgpa,
    required this.totalUnits,
    required this.semesters,
    required this.gradeClass,
  });

  factory CgpaModel.fromJson(Map<String, dynamic> json) => CgpaModel(
        cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0,
        totalUnits: (json['totalUnits'] as num?)?.toInt() ?? (json['total_units'] as num?)?.toInt() ?? 0,
        semesters: (json['semesters'] as num?)?.toInt() ?? 0,
        gradeClass: json['gradeClass'] as String? ?? json['grade_class'] as String? ?? 'N/A',
      );
}

// ─── Providers ────────────────────────────────────────────────────────────────

final gpaSemestersProvider = FutureProvider<List<GpaSemesterModel>>((ref) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get(ApiConstants.gpaSemesters);
    final data = response.data['data'] ?? response.data;
    return (data as List).map((s) => GpaSemesterModel.fromJson(s as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
});

final cgpaProvider = FutureProvider<CgpaModel?>((ref) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get(ApiConstants.gpaCgpa);
    final data = response.data['data'] ?? response.data;
    return CgpaModel.fromJson(data as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});

// ─── Actions ──────────────────────────────────────────────────────────────────

final gpaActionsProvider =
    NotifierProvider<GpaActionsNotifier, AsyncValue<void>>(GpaActionsNotifier.new);

class GpaActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> saveSemester({
    required String academicLevel,
    required int semester,
    String? academicYear,
    required List<GpaCourseModel> courses,
    required double gpa,
    required int totalUnits,
  }) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiConstants.gpaSemesters, data: {
        'academicLevel': academicLevel,
        'semester': semester,
        if (academicYear != null) 'academicYear': academicYear,
        'courses': courses.map((c) => c.toJson()).toList(),
        'gpa': gpa,
        'totalUnits': totalUnits,
      });
      state = const AsyncValue.data(null);
      ref.invalidate(gpaSemestersProvider);
      ref.invalidate(cgpaProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteSemester(String id) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('${ApiConstants.gpaSemesters}/$id');
      state = const AsyncValue.data(null);
      ref.invalidate(gpaSemestersProvider);
      ref.invalidate(cgpaProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
