import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/journey_runner/presentation/screens/runner_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/runner',
        builder: (context, state) {
          final stepId = state.uri.queryParameters['step'];
          return JourneyRunnerScreen(initialStepId: stepId);
        },
      ),
    ],
  );
});
