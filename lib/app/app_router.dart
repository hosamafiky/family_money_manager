import 'package:family_money_manager/core/navigation/route_paths.dart';
import 'package:family_money_manager/features/smoke_screen/smoke_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Creates and owns the single [GoRouter] instance for the application.
///
/// Phase 1 defines one route only: the foundation smoke screen.
/// Feature routes are added in later phases as their screens are implemented.
abstract final class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: RoutePaths.smoke,
      debugLogDiagnostics: false,
      errorBuilder: (context, state) => _ErrorScreen(state.error),
      routes: [
        GoRoute(
          path: RoutePaths.smoke,
          builder: (context, state) => const SmokeScreen(),
        ),
      ],
    );
  }
}

/// Minimal error screen shown when no route matches.
///
/// Provides a back button to return to the initial route.
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen(this.error);
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(error?.toString() ?? 'Page not found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.smoke),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    );
  }
}
