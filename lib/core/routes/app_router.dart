import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/applications/views/my_applications_screen.dart';
import '../../features/assessments/views/candidate_assessment_list_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/jobs/models/job_model.dart';
import '../../features/jobs/views/job_detail_screen.dart';
import '../../features/jobs/views/job_list_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/shell/views/main_shell_screen.dart';
import '../../features/tenant/views/tenant_selection_screen.dart';
import '../storage/storage_service.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellJobsKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellAppsKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellAssessmentsKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellProfileKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(StorageService storageService) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: storageService.getTenantCode() != null ? '/jobs' : '/select-tenant',
    redirect: (context, state) {
      final hasTenant = storageService.getTenantCode() != null;
      final isSelectingTenant = state.matchedLocation == '/select-tenant';

      if (!hasTenant && !isSelectingTenant) {
        return '/select-tenant';
      }
      if (hasTenant && isSelectingTenant) {
        return '/jobs';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/select-tenant',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TenantSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/jobs/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final extraJob = state.extra as JobModel?;
          return JobDetailScreen(jobId: id, initialJob: extraJob);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellJobsKey,
            routes: [
              GoRoute(
                path: '/jobs',
                builder: (context, state) => const JobListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellAppsKey,
            routes: [
              GoRoute(
                path: '/applications',
                builder: (context, state) => const MyApplicationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellAssessmentsKey,
            routes: [
              GoRoute(
                path: '/assessments',
                builder: (context, state) => const CandidateAssessmentListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
