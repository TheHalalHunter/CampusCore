import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/onboarding_screen.dart';
import '../../presentation/screens/auth/integrity_policy_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/verify_email_screen.dart';
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
import '../../presentation/screens/leaderboard/leaderboard_screen.dart';
import '../../presentation/screens/study_groups/study_groups_screen.dart';
import '../../presentation/providers/user_provider.dart';
import '../../presentation/providers/notifications_provider.dart';
import '../../app/theme/app_theme.dart';

export 'app_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerKey = GlobalKey<NavigatorState>(debugLabel: 'campuscore');
  return GoRouter(
    navigatorKey: routerKey,
    initialLocation: AppRoutes.onboarding,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final user = ref.read(currentUserProvider).valueOrNull;
      final location = state.matchedLocation;

      final onAuthScreens = [
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.verifyEmail,
      ].contains(location);

      // Not logged in — send to onboarding
      if (user == null && !onAuthScreens) {
        return AppRoutes.onboarding;
      }

      // Logged in — don't go back to auth screens
      if (user != null && onAuthScreens) {
        return AppRoutes.home;
      }

      // Integrity policy check
      final onPolicyScreen = location == AppRoutes.integrityPolicy;
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
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (_, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),

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
        final courseId = state.uri.queryParameters['courseId'];
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
      GoRoute(path: AppRoutes.leaderboard,     builder: (_, __) => const LeaderboardScreen()),
      GoRoute(path: AppRoutes.studyGroups,     builder: (_, __) => const StudyGroupsScreen()),
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
  static const String verifyEmail     = '/verify-email';
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
  static const String leaderboard    = '/leaderboard';
  static const String studyGroups    = '/study-groups';
}

/// Bottom navigation shell with AppBar and Drawer
class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.courses)) return 1;
    if (location.startsWith(AppRoutes.community)) return 2;
    if (location.startsWith(AppRoutes.library)) return 3;
    if (location.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _selectedIndex(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'CampusCore',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => context.push(AppRoutes.search),
          ),
          // Notification bell with unread badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                tooltip: 'Notifications',
                onPressed: () => context.push(AppRoutes.notifications),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Consumer(
                  builder: (_, ref, __) {
                    final count = ref.watch(unreadCountProvider)
                        .maybeWhen(data: (n) => n, orElse: () => 0);
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Nunito',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: const _AppDrawer(),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
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

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.navyDark),
            child: Row(
              children: [
                Icon(Icons.school, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Text(
                  'CampusCore',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(icon: Icons.home_outlined,              label: 'Home',          route: AppRoutes.home,          drawerContext: context),
                _DrawerItem(icon: Icons.menu_book_outlined,         label: 'Courses',       route: AppRoutes.courses,       drawerContext: context),
                _DrawerItem(icon: Icons.folder_outlined,            label: 'Resources',     route: AppRoutes.resources,     drawerContext: context),
                _DrawerItem(icon: Icons.forum_outlined,             label: 'Community',     route: AppRoutes.community,     drawerContext: context),
                _DrawerItem(icon: Icons.auto_awesome_outlined,      label: 'AI Assistant',  route: AppRoutes.aiAssistant,   drawerContext: context),
                _DrawerItem(icon: Icons.trending_up_outlined,       label: 'Progress',      route: AppRoutes.progress,      drawerContext: context),
                _DrawerItem(icon: Icons.leaderboard_outlined,       label: 'Leaderboard',   route: AppRoutes.leaderboard,   drawerContext: context),
                _DrawerItem(icon: Icons.bookmark_outline,           label: 'Library',       route: AppRoutes.library,       drawerContext: context),
                _DrawerItem(icon: Icons.groups_outlined,            label: 'Study Groups',  route: AppRoutes.studyGroups,   drawerContext: context),
                _DrawerItem(icon: Icons.people_outline,             label: 'Connections',   route: AppRoutes.connections,   drawerContext: context),
                _DrawerItem(icon: Icons.notifications_outlined,     label: 'Notifications', route: AppRoutes.notifications, drawerContext: context),
                _DrawerItem(icon: Icons.person_outline,             label: 'Profile',       route: AppRoutes.profile,       drawerContext: context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final BuildContext drawerContext;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.drawerContext,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.navyMid),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: () {
        Navigator.of(drawerContext).pop(); // close drawer
        drawerContext.go(route);
      },
    );
  }
}
