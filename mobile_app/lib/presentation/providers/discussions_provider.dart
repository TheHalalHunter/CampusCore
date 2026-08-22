import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import 'department_provider.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class ThreadModel {
  final String id;
  final String title;
  final String body;
  final String authorId;
  final String departmentId;
  final String? academicLevel;
  final int replyCount;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ThreadModel({
    required this.id,
    required this.title,
    required this.body,
    required this.authorId,
    required this.departmentId,
    this.academicLevel,
    required this.replyCount,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ThreadModel.fromJson(Map<String, dynamic> json) {
    return ThreadModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      authorId: json['authorId'] as String? ?? json['author_id'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? json['department_id'] as String? ?? '',
      academicLevel: json['academicLevel'] as String? ?? json['academic_level'] as String?,
      replyCount: (json['replyCount'] as num?)?.toInt() ?? (json['reply_count'] as num?)?.toInt() ?? 0,
      isPinned: json['isPinned'] as bool? ?? json['is_pinned'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class ThreadReplyModel {
  final String id;
  final String body;
  final String threadId;
  final String authorId;
  final DateTime createdAt;

  const ThreadReplyModel({
    required this.id,
    required this.body,
    required this.threadId,
    required this.authorId,
    required this.createdAt,
  });

  factory ThreadReplyModel.fromJson(Map<String, dynamic> json) {
    return ThreadReplyModel(
      id: json['id'] as String,
      body: json['body'] as String,
      threadId: json['threadId'] as String? ?? json['thread_id'] as String? ?? '',
      authorId: json['authorId'] as String? ?? json['author_id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Threads list ─────────────────────────────────────────────────────────────

final threadsProvider =
    FutureProvider.family<List<ThreadModel>, String?>((ref, level) async {
  try {
    final dept = await ref.watch(primaryDepartmentProvider.future);
    if (dept == null) return [];
    final api = ref.read(apiClientProvider);
    final params = <String, dynamic>{'departmentId': dept.id};
    if (level != null) params['level'] = level;
    final response = await api.get(ApiConstants.discussions, queryParams: params);
    final data = response.data['data'] ?? response.data;
    return (data as List).map((t) => ThreadModel.fromJson(t)).toList();
  } catch (_) {
    return [];
  }
});

// ─── Thread detail (thread + replies) ────────────────────────────────────────

class ThreadDetail {
  final ThreadModel thread;
  final List<ThreadReplyModel> replies;
  const ThreadDetail({required this.thread, required this.replies});
}

final threadDetailProvider =
    FutureProvider.family<ThreadDetail?, String>((ref, threadId) async {
  try {
    final api = ref.read(apiClientProvider);
    final response = await api.get('${ApiConstants.discussions}/$threadId');
    final data = response.data['data'] ?? response.data;
    return ThreadDetail(
      thread: ThreadModel.fromJson(data['thread'] as Map<String, dynamic>),
      replies: (data['replies'] as List? ?? [])
          .map((r) => ThreadReplyModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  } catch (_) {
    return null;
  }
});

// ─── Thread actions ───────────────────────────────────────────────────────────

final threadActionsProvider =
    NotifierProvider<ThreadActionsNotifier, AsyncValue<void>>(
        ThreadActionsNotifier.new);

class ThreadActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> createThread({
    required String title,
    required String body,
    String? academicLevel,
    required String departmentId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        '${ApiConstants.discussions}?departmentId=$departmentId',
        data: {'title': title, 'body': body, if (academicLevel != null) 'academicLevel': academicLevel},
      );
      state = const AsyncValue.data(null);
      ref.invalidate(threadsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> addReply(String threadId, String body) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      await api.post('${ApiConstants.discussions}/$threadId/replies',
          data: {'body': body});
      state = const AsyncValue.data(null);
      ref.invalidate(threadDetailProvider(threadId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

// ─── Upvote actions ───────────────────────────────────────────────────────────

final upvoteProvider =
    NotifierProvider<UpvoteNotifier, Map<String, int>>(UpvoteNotifier.new);

class UpvoteNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => {};

  Future<void> upvoteQuestion(String questionId, int currentCount) async {
    // Optimistic update
    state = {...state, 'q_$questionId': currentCount + 1};
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post(
          '${ApiConstants.questions}/$questionId/upvote');
      final data = response.data['data'] ?? response.data;
      state = {...state, 'q_$questionId': (data['upvoteCount'] as num).toInt()};
    } catch (_) {
      state = {...state, 'q_$questionId': currentCount};
    }
  }

  Future<void> upvoteAnswer(String answerId, int currentCount) async {
    state = {...state, 'a_$answerId': currentCount + 1};
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post(
          '${ApiConstants.questions}/answers/$answerId/upvote');
      final data = response.data['data'] ?? response.data;
      state = {...state, 'a_$answerId': (data['upvoteCount'] as num).toInt()};
    } catch (_) {
      state = {...state, 'a_$answerId': currentCount};
    }
  }

  int getCount(String key, int fallback) => state[key] ?? fallback;
}
