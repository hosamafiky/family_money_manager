import 'package:family_money_manager/core/navigation/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Creates and owns the single [GoRouter] instance for the application.
///
/// Route definitions live in [routes.dart] as typed [GoRouteData] subclasses.
/// Navigation calls use `const SmokeRouteData().go(context)` (or the relevant
/// typed route) — never raw string paths.
///
/// Phase 1.5 defines two routes: [SmokeRouteData] and [FoundationDetailRouteData].
/// Feature routes are added in later phases as their screens are implemented.
abstract final class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: const SmokeRouteData().location,
      debugLogDiagnostics: false,
      errorBuilder: (context, state) => AppErrorScreen(error: state.error),
      routes: $appRoutes,
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
              onPressed: () => const SmokeRouteData().go(context),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    );
  }
}
