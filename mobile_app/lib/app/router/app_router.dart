import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/onboarding_screen.dart';
import '../../presentation/screens/auth/integrity_policy_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/courses/courses_screen.dart';
import '../../presentation/screens/courses/course_detail_screen.dart';
import '../../presentation/screens/resources/resources_screen.dart';
import '../../presentation/screens/resources/resource_viewer_screen.dart';
import '../../presentation/screens/resources/upload_resource_screen.dart';
import '../../presentation/screens/community/community_screen.dart';
import '../../presentation/screens/community/question_detail_screen.dart';
import '../../presentation/screens/community/post_question_screen.dart';
import '../../presentation/screens/community/discussions_screen.dart';
import '../../presentation/screens/community/thread_detail_screen.dart';
import '../../presentation/screens/ai_assistant/ai_assistant_screen.dart';
import '../../presentation/screens/progress/progress_screen.dart';
import '../../presentation/screens/gpa_calculator/gpa_calculator_screen.dart';
import '../../presentation/screens/library/library_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/profile/public_profile_screen.dart';
import '../../presentation/screens/profile/connections_screen.dart';
import '../../presentation/screens/notifications/notifications_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/providers/user_provider.dart';

export 'app_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerKey = GlobalKey<NavigatorState>(debugLabel: 'campuscore');
  return GoRouter(
    navigatorKey: routerKey,
    initialLocation: AppRoutes.onboarding,
    debugLogDiagnostics: false,
    // Redirect to integrity policy if user hasn't accepted it yet
    redirect: (context, state) {
      final user = ref.read(currentUserProvider).valueOrNull;
      final onPolicyScreen = state.matchedLocation == AppRoutes.integrityPolicy;
      final onAuthScreens = [
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.register,
      ].contains(state.matchedLocation);

      // If user is logged in, hasn't accepted policy, and isn't already on the policy screen
      if (user != null && !user.acceptedIntegrityPolicy && !onPolicyScreen && !onAuthScreens) {
        return AppRoutes.integrityPolicy;
      }
      return null;
    },
    routes: [
      // Auth flow
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.integrityPolicy, builder: (_, __) => const IntegrityPolicyScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordScreen()),

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
      GoRoute(path: AppRoutes.notifications,  builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.uploadResource, builder: (_, __) => const UploadResourceScreen()),
      GoRoute(path: AppRoutes.postQuestion,   builder: (_, __) => const PostQuestionScreen()),
      GoRoute(path: AppRoutes.search,          builder: (_, __) => const SearchScreen()),
      GoRoute(path: AppRoutes.discussions,     builder: (_, __) => const DiscussionsScreen()),
      GoRoute(path: AppRoutes.connections,     builder: (_, __) => const ConnectionsScreen()),
      GoRoute(
        path: '${AppRoutes.discussions}/:threadId',
        builder: (_, state) => ThreadDetailScreen(threadId: state.pathParameters['threadId']!),
      ),
      GoRoute(
        path: '${AppRoutes.profile}/:userId',
        builder: (_, state) => PublicProfileScreen(userId: state.pathParameters['userId']!),
      ),
    ],
  );
});

class AppRoutes {
  static const String onboarding = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword  = '/forgot-password';
  static const String integrityPolicy = '/integrity-policy';
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
  static const String postQuestion   = '/post-question';
  static const String search         = '/search';
  static const String discussions    = '/discussions';
  static const String connections    = '/connections';
  static const String publicProfile  = '/profile/:userId';
}

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
