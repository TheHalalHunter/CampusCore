import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/question_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/error_helper.dart';
import 'department_provider.dart';

// ─── Questions (paginated) ────────────────────────────────────────────────────

final questionsProvider = FutureProvider.family<List<QuestionModel>,
    ({String? courseId, String? level})>((ref, filters) async {
  try {
    final dept = await ref.watch(primaryDepartmentProvider.future);
    final api = ref.read(apiClientProvider);
    final params = <String, dynamic>{'page': 1, 'limit': 20};
    if (dept != null) params['departmentId'] = dept.id;
    if (filters.courseId != null) params['courseId'] = filters.courseId;
    if (filters.level != null) params['level'] = filters.level;
    final response = await api.get(ApiConstants.questions, queryParams: params);
    final raw = response.data['data'] ?? response.data;
    // Handle both array and [items, count] tuple from backend
    final List items = raw is List
        ? (raw.length == 2 && raw[1] is int ? raw[0] as List : raw)
        : [];
    return items.map((q) => QuestionModel.fromJson(q)).toList();
  } catch (_) {
    return [];
  }
});

// All questions (no filter)
final allQuestionsProvider = FutureProvider<List<QuestionModel>>((ref) async {
  return ref.watch(questionsProvider((courseId: null, level: null)).future);
});

// ─── Answers ──────────────────────────────────────────────────────────────────

final answersProvider =
    FutureProvider.family<List<AnswerModel>, String>((ref, questionId) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get('${ApiConstants.questions}/$questionId');
    final data = response.data['data'] ?? response.data;
    final answers = data['answers'] as List? ?? [];
    return answers.map((a) => AnswerModel.fromJson(a)).toList();
  } catch (_) {
    return [];
  }
});

// ─── Post Question ────────────────────────────────────────────────────────────

final postQuestionProvider =
    NotifierProvider<PostQuestionNotifier, AsyncValue<void>>(PostQuestionNotifier.new);

class PostQuestionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> post({
    required String title,
    required String body,
    String? courseId,
    String? academicLevel,
    List<String> tags = const [],
  }) async {
    state = const AsyncValue.loading();
    try {
      final dept = await ref.read(primaryDepartmentProvider.future);
      final api = ref.read(apiClientProvider);
      await api.post(ApiConstants.questions, data: {
        'title': title,
        'body': body,
        'courseId': courseId,
        'departmentId': dept?.id,
        'academicLevel': academicLevel,
        'tags': tags,
      });
      state = const AsyncValue.data(null);
      // Invalidate questions cache
      ref.invalidate(allQuestionsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(extractErrorMessage(e), st);
      return false;
    }
  }
}

// ─── Post Answer ──────────────────────────────────────────────────────────────

final postAnswerProvider =
    NotifierProvider<PostAnswerNotifier, AsyncValue<void>>(PostAnswerNotifier.new);

class PostAnswerNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> post({
    required String questionId,
    required String body,
  }) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      await api.post('${ApiConstants.questions}/$questionId/answers', data: {'body': body});
      state = const AsyncValue.data(null);
      ref.invalidate(answersProvider(questionId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(extractErrorMessage(e), st);
      return false;
    }
  }
}
