import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../shell/app_shell.dart';
import '../../core/providers/auth_provider.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/courses/courses_screen.dart';
import '../../presentation/screens/courses/course_detail_screen.dart';
import '../../presentation/screens/resources/resources_screen.dart';
import '../../presentation/screens/community/community_screen.dart';
import '../../presentation/screens/progress/progress_screen.dart';
import '../../presentation/screens/ai/ai_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/coming_soon/coming_soon_screen.dart';
import '../../presentation/screens/connections/connections_screen.dart';
import '../../presentation/screens/notifications/notifications_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth    = ref.read(authProvider);
      final isLogin = state.matchedLocation == '/login';

      if (!auth.initialized) return null;
      if (!auth.isAuthenticated && !isLogin) return '/login';
      if (auth.isAuthenticated  &&  isLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/',          name: 'home',      builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/courses',   name: 'courses',   builder: (_, __) => const CoursesScreen()),
          GoRoute(
            path: '/courses/:id',
            name: 'course-detail',
            builder: (_, state) => CourseDetailScreen(
              courseId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(path: '/resources', name: 'resources', builder: (_, __) => const ResourcesScreen()),
          GoRoute(path: '/community', name: 'community', builder: (_, __) => const CommunityScreen()),
          GoRoute(path: '/progress',  name: 'progress',  builder: (_, __) => const ProgressScreen()),
          GoRoute(path: '/ai',        name: 'ai',        builder: (_, __) => const AiScreen()),
          GoRoute(path: '/profile',   name: 'profile',   builder: (_, __) => const ProfileScreen()),
          GoRoute(
            path: '/connections',
            name: 'connections',
            builder: (_, __) => const ConnectionsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/leaderboard',
            name: 'leaderboard',
            builder: (_, __) => const ComingSoonScreen(
              featureName: 'Leaderboard',
              description: 'See top contributors in your department, earn badges, and climb the reputation ranks. Coming soon!',
              icon: Icons.leaderboard_outlined,
            ),
          ),
        ],
      ),
    ],
  );
});

/// Listens to auth state changes and notifies GoRouter to re-evaluate redirects.
class _AuthChangeNotifier extends ChangeNotifier {
  late final ProviderSubscription<AuthState> _sub;

  _AuthChangeNotifier(Ref ref) {
    _sub = ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.isAuthenticated != next.isAuthenticated ||
          prev?.initialized     != next.initialized) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
