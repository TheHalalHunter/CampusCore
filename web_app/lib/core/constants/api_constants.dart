class ApiConstants {
  static const String baseUrl =
      'https://campuscore-bfrq.onrender.com/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String me    = '/users/me';

  // Users / Profile
  static const String updateProfile = '/users/me';

  // Courses
  static const String courses     = '/courses';
  static const String departments = '/departments';

  // Resources
  static const String resources      = '/resources';
  static const String uploadResource = '/resources';

  // Community / Q&A
  static const String questions    = '/community/questions';
  static const String postQuestion = '/community/questions';
  static String questionAnswers(String id) => '/community/questions/$id/answers';
  static String postAnswer(String id)      => '/community/questions/$id/answers';

  // Progress / GPA
  static const String gpa      = '/gpa';
  static const String progress = '/progress';

  // AI — all real backend endpoints
  static const String aiExplain       = '/ai/explain';       // POST {concept, courseContext?}
  static const String aiQuiz          = '/ai/quiz';          // POST {topic, count?}
  static const String aiSummarize     = '/ai/summarize';     // POST {text}
  static const String aiFlashcards    = '/ai/flashcards';    // POST {topic, count?}
  static const String aiPredictTopics = '/ai/predict-topics';// POST {courseTitle, recentTopics[]}

  // Notifications
  static const String unreadCount = '/notifications/unread-count';
}
