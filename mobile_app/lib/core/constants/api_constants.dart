/// Base URL for the CampusCore API.
/// Override at build time:
///   flutter run --dart-define=API_BASE_URL=https://your-app.railway.app/api/v1
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://campuscore-bfrq.onrender.com/api/v1',
  );

  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';

  // Users
  static const String me = '/users/me';
  static const String acceptPolicy = '/users/me/accept-policy';
  static const String updateFcmToken = '/users/me';
  static const String leaderboard = '/users/leaderboard';
  static String userProfile(String id) => '/users/$id/profile';

  // Departments
  static const String departments = '/departments';

  // Courses
  static const String courses = '/courses';

  // Resources
  static const String resources = '/resources';

  // Community / Q&A
  static const String questions = '/community/questions';
  static String questionDetail(String id) => '/community/questions/$id';
  static String questionAnswers(String id) => '/community/questions/$id/answers';
  static String upvoteQuestion(String id) => '/community/questions/$id/upvote';
  static String downvoteQuestion(String id) => '/community/questions/$id/downvote';
  static String resolveQuestion(String id) => '/community/questions/$id/resolve';
  static String upvoteAnswer(String id) => '/community/answers/$id/upvote';
  static String downvoteAnswer(String id) => '/community/answers/$id/downvote';
  static String flagQuestion(String id) => '/community/flag/question/$id';
  static String flagAnswer(String id) => '/community/flag/answer/$id';

  // AI
  static const String aiExplain = '/ai/explain';
  static const String aiQuiz = '/ai/quiz';
  static const String aiSummarize = '/ai/summarize';
  static const String aiFlashcards = '/ai/flashcards';
  static const String aiPredictTopics = '/ai/predict-topics';

  // Progress
  static const String progress = '/progress';
  static const String progressStreak = '/progress/streak';
  static String courseProgress(String courseId) => '/progress/courses/$courseId';
  static String markTopicComplete(String courseId, String topicId) =>
      '/progress/courses/$courseId/topics/$topicId/complete';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String unreadCount = '/notifications/unread-count';
  static String markNotificationRead(String id) => '/notifications/$id/read';

  // Gamification
  static const String badges = '/gamification/badges';

  // Connections
  static const String connections = '/connections';
  static const String connectionRequest = '/connections/request';
  static const String connectionsPendingReceived = '/connections/pending/received';
  static const String connectionsPendingSent = '/connections/pending/sent';
  static String connectionAccept(String id) => '/connections/$id/accept';
  static String connectionRemove(String id) => '/connections/$id';
  static String connectionStatus(String userId) => '/connections/status/$userId';

  // Search
  static const String search = '/search';

  // Discussions
  static const String discussions = '/discussions';
  static String discussionReplies(String threadId) => '/discussions/$threadId/replies';

  // GPA
  static const String gpaSemesters = '/gpa/semesters';
  static const String gpaCgpa = '/gpa/cgpa';
  static String deleteSemester(String id) => '/gpa/semesters/$id';

  // Personal Library
  static const String library = '/library';
  static String libraryRemove(String resourceId) => '/library/$resourceId';
}
