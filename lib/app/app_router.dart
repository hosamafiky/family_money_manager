import 'package:family_money_manager/core/navigation/app_route.dart';
import 'package:family_money_manager/features/smoke_screen/smoke_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Creates and owns the single [GoRouter] instance for the application.
///
/// Phase 1 defines one route only: the foundation smoke screen.
/// Feature routes are added in later phases as their screens are implemented.
///
/// Navigation is typed: use `const SmokeRoute().go(context)` instead of
/// raw string paths.
abstract final class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: const SmokeRoute().path,
      debugLogDiagnostics: false,
      errorBuilder: (context, state) => AppErrorScreen(error: state.error),
      routes: [
        GoRoute(
          path: const SmokeRoute().path,
          builder: (context, state) => const SmokeScreen(),
        ),
      ],
    );
  }
}

/// Minimal error screen shown when no route matches.
///
/// Exposed as a public class so it can be widget-tested directly without
/// requiring a live router instance.
class AppErrorScreen extends StatelessWidget {
  const AppErrorScreen({this.error, super.key});
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
              onPressed: () => const SmokeRoute().go(context),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    );
  }
}
