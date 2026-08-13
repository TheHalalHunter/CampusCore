import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/onboarding_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/courses/courses_screen.dart';
import '../../presentation/screens/courses/course_detail_screen.dart';
import '../../presentation/screens/resources/resources_screen.dart';
import '../../presentation/screens/resources/upload_resource_screen.dart';
import '../../presentation/screens/community/community_screen.dart';
import '../../presentation/screens/community/question_detail_screen.dart';
import '../../presentation/screens/ai_assistant/ai_assistant_screen.dart';
import '../../presentation/screens/progress/progress_screen.dart';
import '../../presentation/screens/gpa_calculator/gpa_calculator_screen.dart';
import '../../presentation/screens/library/library_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/notifications/notifications_screen.dart';

export 'app_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    debugLogDiagnostics: false,
    routes: [
      // Auth flow
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),

      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
          GoRoute(path: AppRoutes.courses, builder: (_, __) => const CoursesScreen()),
          GoRoute(
            path: '${AppRoutes.courses}/:courseId',
            builder: (_, state) => CourseDetailScreen(courseId: state.pathParameters['courseId']!),
          ),
          GoRoute(path: AppRoutes.community, builder: (_, __) => const CommunityScreen()),
          GoRoute(
            path: '${AppRoutes.community}/questions/:questionId',
            builder: (_, state) => QuestionDetailScreen(questionId: state.pathParameters['questionId']!),
          ),
          GoRoute(path: AppRoutes.library, builder: (_, __) => const LibraryScreen()),
          GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(path: AppRoutes.resources, builder: (_, state) {
        final courseId = state.uri.queryParameters['courseId'] ?? '';
        return ResourcesScreen(courseId: courseId);
      }),
      GoRoute(
        path: '${AppRoutes.resources}/:resourceId/view',
        builder: (_, state) => ResourceViewerScreen(resourceId: state.pathParameters['resourceId']!),
      ),
      GoRoute(path: AppRoutes.aiAssistant, builder: (_, __) => const AiAssistantScreen()),
      GoRoute(path: AppRoutes.progress, builder: (_, __) => const ProgressScreen()),
      GoRoute(path: AppRoutes.gpaCalculator, builder: (_, __) => const GpaCalculatorScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.uploadResource, builder: (_, __) => const UploadResourceScreen()),
    ],
  );
});

class AppRoutes {
  static const String onboarding = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String courses = '/courses';
  static const String resources = '/resources';
  static const String community = '/community';
  static const String aiAssistant = '/ai-assistant';
  static const String progress = '/progress';
  static const String gpaCalculator = '/gpa-calculator';
  static const String library = '/library';
  static const String profile = '/profile';
  static const String notifications  = '/notifications';
  static const String uploadResource = '/upload-resource';

/// Bottom navigation shell
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go(AppRoutes.home); break;
            case 1: context.go(AppRoutes.courses); break;
            case 2: context.go(AppRoutes.community); break;
            case 3: context.go(AppRoutes.library); break;
            case 4: context.go(AppRoutes.profile); break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Courses'),
          NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'Community'),
          NavigationDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
