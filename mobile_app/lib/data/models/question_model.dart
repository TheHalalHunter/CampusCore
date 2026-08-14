class QuestionModel {
  final String id;
  final String title;
  final String body;
  final String authorId;
  final String? courseId;
  final String? departmentId;
  final String? academicLevel;
  final int upvoteCount;
  final int answerCount;
  final bool isResolved;
  final bool isFlagged;
  final List<String> tags;
  final DateTime createdAt;

  const QuestionModel({
    required this.id,
    required this.title,
    required this.body,
    required this.authorId,
    this.courseId,
    this.departmentId,
    this.academicLevel,
    required this.upvoteCount,
    required this.answerCount,
    required this.isResolved,
    required this.isFlagged,
    required this.tags,
    required this.createdAt,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      authorId: json['authorId'] as String? ?? json['author_id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? json['course_id'] as String?,
      departmentId: json['departmentId'] as String? ?? json['department_id'] as String?,
      academicLevel: json['academicLevel'] as String? ?? json['academic_level'] as String?,
      upvoteCount: (json['upvoteCount'] as num?)?.toInt() ??
          (json['upvote_count'] as num?)?.toInt() ?? 0,
      answerCount: (json['answerCount'] as num?)?.toInt() ??
          (json['answer_count'] as num?)?.toInt() ?? 0,
      isResolved: json['isResolved'] as bool? ?? json['is_resolved'] as bool? ?? false,
      isFlagged: json['isFlagged'] as bool? ?? json['is_flagged'] as bool? ?? false,
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
      createdAt: DateTime.tryParse(
            json['createdAt'] as String? ?? json['created_at'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class AnswerModel {
  final String id;
  final String body;
  final String questionId;
  final String authorId;
  final int upvoteCount;
  final bool isVerified;
  final DateTime createdAt;

  const AnswerModel({
    required this.id,
    required this.body,
    required this.questionId,
    required this.authorId,
    required this.upvoteCount,
    required this.isVerified,
    required this.createdAt,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      id: json['id'] as String,
      body: json['body'] as String,
      questionId: json['questionId'] as String? ?? json['question_id'] as String? ?? '',
      authorId: json['authorId'] as String? ?? json['author_id'] as String? ?? '',
      upvoteCount: (json['upvoteCount'] as num?)?.toInt() ??
          (json['upvote_count'] as num?)?.toInt() ?? 0,
      isVerified: json['isVerified'] as bool? ?? json['is_verified'] as bool? ?? false,
      createdAt: DateTime.tryParse(
            json['createdAt'] as String? ?? json['created_at'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
