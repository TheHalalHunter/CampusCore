import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/auth/admin_login_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/users/users_screen.dart';
import '../../presentation/screens/resources/moderation_screen.dart';
import '../../presentation/screens/departments/departments_screen.dart';
import '../../presentation/screens/reports/reports_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/exam_lock/exam_lock_screen.dart';
import '../../presentation/screens/courses/courses_management_screen.dart';
import '../../presentation/screens/gamification/gamification_screen.dart';
import '../../presentation/shell/admin_shell.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AdminRoutes.login,
    routes: [
      GoRoute(
        path: AdminRoutes.login,
        builder: (_, __) => const AdminLoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
              path: AdminRoutes.dashboard,
              builder: (_, __) => const DashboardScreen()),
          GoRoute(
              path: AdminRoutes.users, builder: (_, __) => const UsersScreen()),
          GoRoute(
              path: AdminRoutes.moderation,
              builder: (_, __) => const ModerationScreen()),
          GoRoute(
              path: AdminRoutes.departments,
              builder: (_, __) => const DepartmentsScreen()),
          GoRoute(
              path: AdminRoutes.reports,
              builder: (_, __) => const ReportsScreen()),
          GoRoute(
              path: AdminRoutes.settings,
              builder: (_, __) => const SettingsScreen()),
          GoRoute(
              path: AdminRoutes.examLock,
              builder: (_, __) => const ExamLockScreen()),
          GoRoute(
              path: AdminRoutes.courses,
              builder: (_, __) => const CoursesManagementScreen()),
          GoRoute(
              path: AdminRoutes.gamification,
              builder: (_, __) => const GamificationScreen()),
        ],
      ),
    ],
  );
});

class AdminRoutes {
  static const String login = '/';
  static const String dashboard = '/dashboard';
  static const String users = '/users';
  static const String moderation = '/moderation';
  static const String departments = '/departments';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String examLock = '/exam-lock';
  static const String courses = '/courses';
  static const String gamification = '/gamification';
}
