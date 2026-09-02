/// Base URL for the CampusCore API.
/// Change this to your deployed backend URL before release.
class ApiConstants {
  static const String baseUrl = 'http://localhost:3000/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';

  // Users
  static const String me = '/users/me';
  static const String acceptPolicy = '/users/me/accept-policy';
  static const String updateFcmToken = '/users/me';

  // Departments
  static const String departments = '/departments';

  // Courses
  static const String courses = '/courses';

  // Resources
  static const String resources = '/resources';

  // Community
  static const String questions = '/community/questions';
  // AI
  static const String aiExplain = '/ai/explain';
  static const String aiQuiz = '/ai/quiz';
  static const String aiSummarize = '/ai/summarize';
  static const String aiFlashcards = '/ai/flashcards';
  static const String aiPredictTopics = '/ai/predict-topics';

  // Progress
  static const String progress = '/progress';
  static const String progressStreak = '/progress/streak';

  // Notifications
  static const String notifications = '/notifications';

  // Gamification
  static const String badges = '/gamification/badges';

  // Connections
  static const String connections = '/connections';
  static const String connectionRequest = '/connections/request';
  static const String connectionsPendingReceived = '/connections/pending/received';
  static const String connectionsPendingSent = '/connections/pending/sent';

  // Search
  static const String search = '/search';

  // Discussions
  static const String discussions = '/discussions';

  // GPA
  static const String gpaSemesters = '/gpa/semesters';
  static const String gpaCgpa = '/gpa/cgpa';
}
