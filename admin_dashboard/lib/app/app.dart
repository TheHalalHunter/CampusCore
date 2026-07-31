import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/admin_router.dart';
import 'theme/admin_theme.dart';

class CampusCoreAdminApp extends ConsumerWidget {
  const CampusCoreAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);
    return MaterialApp.router(
      title: 'CampusCore Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.light(),
      routerConfig: router,
    );
  }
}
