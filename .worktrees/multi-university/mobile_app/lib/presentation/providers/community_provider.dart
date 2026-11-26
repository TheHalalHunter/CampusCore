import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/question_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/storage/offline_cache.dart';
import '../../core/utils/error_helper.dart';
import 'department_provider.dart';

// ─── Questions (paginated) ────────────────────────────────────────────────────

final questionsProvider = FutureProvider.family<List<QuestionModel>,
    ({String? courseId, String? level})>((ref, filters) async {
  final dept = await ref.watch(primaryDepartmentProvider.future);
  final cacheKey = 'questions_${dept?.id ?? 'all'}_${filters.level ?? ''}';

  if (OfflineCache.isFresh(cacheKey)) {
    final cached = OfflineCache.get<List>(cacheKey);
    if (cached != null) return cached.map((q) => QuestionModel.fromJson(q as Map<String, dynamic>)).toList();
  }

  try {
    final api = ref.read(apiClientProvider);
    final params = <String, dynamic>{'page': 1, 'limit': 20};
    if (dept != null) params['departmentId'] = dept.id;
    if (filters.courseId != null) params['courseId'] = filters.courseId;
    if (filters.level != null) params['level'] = filters.level;
    final response = await api.get(ApiConstants.questions, queryParams: params);
    final raw = response.data['data'] ?? response.data;
    List items;
    if (raw is Map && raw['questions'] is List) {
      items = raw['questions'] as List;
    } else if (raw is List && raw.length == 2 && raw[1] is int) {
      items = raw[0] as List;
    } else if (raw is List) {
      items = raw;
    } else {
      items = [];
    }
    await OfflineCache.put(cacheKey, items);
    return items.map((q) => QuestionModel.fromJson(q as Map<String, dynamic>)).toList();
  } catch (e) {
    final stale = OfflineCache.get<List>(cacheKey);
    if (stale != null) return stale.map((q) => QuestionModel.fromJson(q as Map<String, dynamic>)).toList();
    rethrow;
  }
});

// All questions (no filter)
final allQuestionsProvider = FutureProvider<List<QuestionModel>>((ref) async {
  const cacheKey = 'questions_all';

  if (OfflineCache.isFresh(cacheKey)) {
    final cached = OfflineCache.get<List>(cacheKey);
    if (cached != null) return cached.map((q) => QuestionModel.fromJson(q as Map<String, dynamic>)).toList();
  }

  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get(ApiConstants.questions, queryParams: {'limit': 30});
    final data = response.data['data'] ?? response.data;
    List raw;
    if (data is Map && data['questions'] is List) {
      raw = data['questions'] as List;
    } else if (data is List && data.length == 2 && data[1] is int) {
      raw = data[0] as List;
    } else if (data is List) {
      raw = data;
    } else {
      return [];
    }
    await OfflineCache.put(cacheKey, raw);
    return raw.map((q) => QuestionModel.fromJson(q as Map<String, dynamic>)).toList();
  } catch (e) {
    final stale = OfflineCache.get<List>(cacheKey);
    if (stale != null) return stale.map((q) => QuestionModel.fromJson(q as Map<String, dynamic>)).toList();
    rethrow;
  }
});

// ─── Answers ──────────────────────────────────────────────────────────────────

final answersProvider =
    FutureProvider.family<List<AnswerModel>, String>((ref, questionId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.questionDetail(questionId));
  final data = response.data['data'] ?? response.data;
  // Backend returns { question, answers }
  final answers = data['answers'] as List? ?? [];
  return answers.map((a) => AnswerModel.fromJson(a)).toList();
});

/// Fetches a single question with its answers — used by question_detail_screen
/// so it doesn't rely on the allQuestionsProvider cache.
class QuestionWithAnswers {
  final QuestionModel question;
  final List<AnswerModel> answers;
  const QuestionWithAnswers({required this.question, required this.answers});
}

final questionDetailProvider =
    FutureProvider.family<QuestionWithAnswers?, String>((ref, questionId) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.questionDetail(questionId));
  final data = response.data['data'] ?? response.data;
  return QuestionWithAnswers(
    question: QuestionModel.fromJson(data['question'] as Map<String, dynamic>),
    answers: (data['answers'] as List? ?? [])
        .map((a) => AnswerModel.fromJson(a))
        .toList(),
  );
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
        if (body.isNotEmpty) 'body': body,
        if (courseId != null) 'courseId': courseId,
        if (dept?.id != null) 'departmentId': dept!.id,
        if (academicLevel != null) 'academicLevel': academicLevel,
        if (tags.isNotEmpty) 'tags': tags,
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
      ref.invalidate(questionDetailProvider(questionId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(extractErrorMessage(e), st);
      return false;
    }
  }
}
