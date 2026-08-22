import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/course_model.dart';
import '../../data/models/resource_model.dart';
import '../../data/models/question_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

// ─── Result model ─────────────────────────────────────────────────────────────

class SearchResults {
  final List<CourseModel> courses;
  final List<ResourceModel> resources;
  final List<QuestionModel> questions;
  final int total;

  const SearchResults({
    required this.courses,
    required this.resources,
    required this.questions,
    required this.total,
  });

  bool get isEmpty => total == 0;

  factory SearchResults.empty() => const SearchResults(
        courses: [],
        resources: [],
        questions: [],
        total: 0,
      );

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    final courses = (json['courses'] as List? ?? [])
        .map((c) => CourseModel.fromJson(c as Map<String, dynamic>))
        .toList();
    final resources = (json['resources'] as List? ?? [])
        .map((r) => ResourceModel.fromJson(r as Map<String, dynamic>))
        .toList();
    final questions = (json['questions'] as List? ?? [])
        .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
        .toList();
    return SearchResults(
      courses: courses,
      resources: resources,
      questions: questions,
      total: (json['total'] as num?)?.toInt() ??
          courses.length + resources.length + questions.length,
    );
  }
}

// ─── Search state ─────────────────────────────────────────────────────────────

class SearchState {
  final String query;
  final SearchResults? results;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.query = '',
    this.results,
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    SearchResults? results,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearResults = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: clearResults ? null : (results ?? this.results),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get hasResults => results != null && !results!.isEmpty;
  bool get hasQuery => query.trim().isNotEmpty;
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final searchProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  Future<void> search(String query, {String? departmentId}) async {
    final q = query.trim();
    if (q.isEmpty) {
      state = state.copyWith(query: '', clearResults: true, clearError: true);
      return;
    }

    state = state.copyWith(query: q, isLoading: true, clearError: true);
    try {
      final api = ref.read(apiClientProvider);
      final params = <String, dynamic>{'q': q, 'limit': 8};
      if (departmentId != null) params['departmentId'] = departmentId;
      final response = await api.get(ApiConstants.search, queryParams: params);
      final data = response.data['data'] ?? response.data;
      final results = SearchResults.fromJson(data as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, results: results);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Search failed. Please try again.');
    }
  }

  void clear() => state = const SearchState();
}
