import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/error_helper.dart';
import '../../data/models/question_model.dart';
import '../../data/models/resource_model.dart';
import 'department_provider.dart';

// ─── Generic paginated state ──────────────────────────────────────────────────

class PaginatedState<T> {
  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const PaginatedState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    bool clearError = false,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isEmpty => items.isEmpty && !isLoading;
}

// ─── Paginated questions ──────────────────────────────────────────────────────

class PaginatedQuestionsNotifier
    extends Notifier<PaginatedState<QuestionModel>> {
  static const _limit = 20;
  String? _departmentId;
  String? _courseId;
  String? _level;

  @override
  PaginatedState<QuestionModel> build() => const PaginatedState();

  Future<void> load({
    String? courseId,
    String? level,
    bool refresh = false,
  }) async {
    if (state.isLoading || state.isLoadingMore) return;

    _courseId = courseId;
    _level = level;

    if (refresh) {
      state = const PaginatedState(isLoading: true);
    } else if (state.currentPage == 0) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      if (!state.hasMore) return;
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final dept = await ref.read(primaryDepartmentProvider.future);
      _departmentId = dept?.id;

      final api = ref.read(apiClientProvider);
      final page = refresh ? 1 : state.currentPage + 1;
      final params = <String, dynamic>{
        'page': page,
        'limit': _limit,
      };
      if (_departmentId != null) params['departmentId'] = _departmentId;
      if (_courseId != null) params['courseId'] = _courseId;
      if (_level != null) params['level'] = _level;

      final response =
          await api.get(ApiConstants.questions, queryParams: params);
      final raw = response.data['data'] ?? response.data;
      final List itemsRaw =
          raw is List && raw.length == 2 && raw[1] is int ? raw[0] as List : raw is List ? raw : [];
      final newItems =
          itemsRaw.map((q) => QuestionModel.fromJson(q as Map<String, dynamic>)).toList();

      state = state.copyWith(
        items: refresh ? newItems : [...state.items, ...newItems],
        isLoading: false,
        isLoadingMore: false,
        hasMore: newItems.length == _limit,
        currentPage: page,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: extractErrorMessage(e),
      );
    }
  }

  void reset() => state = const PaginatedState();
}

final paginatedQuestionsProvider =
    NotifierProvider<PaginatedQuestionsNotifier, PaginatedState<QuestionModel>>(
        PaginatedQuestionsNotifier.new);

// ─── Paginated resources ──────────────────────────────────────────────────────

class PaginatedResourcesNotifier
    extends FamilyNotifier<PaginatedState<ResourceModel>, String> {
  static const _limit = 20;

  @override
  PaginatedState<ResourceModel> build(String courseId) =>
      const PaginatedState(isLoading: true);

  Future<void> load({bool refresh = false}) async {
    if (state.isLoadingMore) return;
    if (!refresh && !state.hasMore && state.currentPage > 0) return;

    if (refresh) {
      state = const PaginatedState(isLoading: true);
    } else if (state.currentPage > 0) {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final api = ref.read(apiClientProvider);
      final page = refresh ? 1 : state.currentPage + 1;
      final response = await api.get(
        ApiConstants.resources,
        queryParams: {'courseId': arg, 'page': page, 'limit': _limit},
      );
      final raw = response.data['data'] ?? response.data;
      final List itemsRaw =
          raw is List && raw.length == 2 && raw[1] is int ? raw[0] as List : raw is List ? raw : [];
      final newItems = itemsRaw
          .map((r) => ResourceModel.fromJson(r as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        items: refresh ? newItems : [...state.items, ...newItems],
        isLoading: false,
        isLoadingMore: false,
        hasMore: newItems.length == _limit,
        currentPage: page,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: extractErrorMessage(e),
      );
    }
  }
}

final paginatedResourcesProvider = NotifierProviderFamily<
    PaginatedResourcesNotifier,
    PaginatedState<ResourceModel>,
    String>(PaginatedResourcesNotifier.new);
