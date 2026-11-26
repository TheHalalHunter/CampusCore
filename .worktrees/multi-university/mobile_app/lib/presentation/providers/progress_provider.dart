import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import 'courses_provider.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class TopicProgress {
  final String topicId;
  final String topicTitle;
  final bool isCompleted;
  final DateTime? completedAt;

  const TopicProgress({
    required this.topicId,
    required this.topicTitle,
    required this.isCompleted,
    this.completedAt,
  });

  factory TopicProgress.fromJson(Map<String, dynamic> json) => TopicProgress(
        topicId: json['topicId'] as String? ?? json['topic_id'] as String? ?? '',
        topicTitle: json['topicTitle'] as String? ?? json['topic_title'] as String? ?? '',
        isCompleted: json['isCompleted'] as bool? ?? json['is_completed'] as bool? ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
      );
}

class CourseProgressData {
  final List<TopicProgress> topics;
  final int completedCount;
  final int totalCount;
  final int percentage;

  const CourseProgressData({
    required this.topics,
    required this.completedCount,
    required this.totalCount,
    required this.percentage,
  });

  factory CourseProgressData.fromJson(Map<String, dynamic> json) {
    final topics = (json['topics'] as List? ?? [])
        .map((t) => TopicProgress.fromJson(t as Map<String, dynamic>))
        .toList();
    return CourseProgressData(
      topics: topics,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? topics.length,
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
    );
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final courseProgressProvider =
    FutureProvider.family<CourseProgressData, String>((ref, courseId) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get('${ApiConstants.progress}/courses/$courseId');
    final data = response.data['data'] ?? response.data;
    return CourseProgressData.fromJson(data as Map<String, dynamic>);
  } catch (_) {
    return const CourseProgressData(
        topics: [], completedCount: 0, totalCount: 0, percentage: 0);
  }
});

// ─── Mark topic complete / incomplete ─────────────────────────────────────────

final progressActionsProvider =
    NotifierProvider<ProgressActionsNotifier, void>(ProgressActionsNotifier.new);

class ProgressActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> markComplete(
      String courseId, String topicId, String topicTitle) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        '${ApiConstants.progress}/courses/$courseId/topics/$topicId/complete',
        data: {'topicTitle': topicTitle},
      );
      ref.invalidate(courseProgressProvider(courseId));
    } catch (_) {}
  }

  Future<void> unmark(String courseId, String topicId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.delete(
        '${ApiConstants.progress}/courses/$courseId/topics/$topicId/complete',
      );
      ref.invalidate(courseProgressProvider(courseId));
    } catch (_) {}
  }
}

// ─── Semester overview ────────────────────────────────────────────────────────

final semesterProgressProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final courses = await ref.watch(coursesProvider.future);
    if (courses.isEmpty) return {};
    final ids = courses.map((c) => c.id).join(',');
    final api = ref.read(apiClientProvider);
    final response = await api.get(
      '${ApiConstants.progress}/semester',
      queryParams: {'courseIds': ids},
    );
    return (response.data['data'] ?? response.data) as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
});

// ─── Study streak (private) ───────────────────────────────────────────────────

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final int totalStudyDays;
  final bool studiedToday;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalStudyDays,
    required this.studiedToday,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) => StreakData(
        currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
        longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
        totalStudyDays: (json['totalStudyDays'] as num?)?.toInt() ?? 0,
        studiedToday: json['studiedToday'] as bool? ?? false,
      );
}

final streakProvider = FutureProvider<StreakData>((ref) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get(ApiConstants.progressStreak);
    final data = response.data['data'] ?? response.data;
    return StreakData.fromJson(data as Map<String, dynamic>);
  } catch (_) {
    return const StreakData(
        currentStreak: 0, longestStreak: 0, totalStudyDays: 0, studiedToday: false);
  }
});
