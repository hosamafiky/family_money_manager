import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Typed route hierarchy for the application.
///
/// Every navigable destination is represented as a concrete [AppRoute]
/// subclass. Navigation calls use the typed route object, giving compile-time
/// verification that the target exists.
///
/// Usage:
/// ```dart
/// const SmokeRoute().go(context);
/// ```
///
/// Phase 1 defines one route only. Financial feature routes are added in later
/// phases as their screens are implemented. Do not add financial routes here.
sealed class AppRoute {
  const AppRoute();

  /// The URL path for this route, used by [GoRouter].
  String get path;

  /// Navigates to this route, replacing the current location.
  void go(BuildContext context) => GoRouter.of(context).go(path);

  /// Pushes this route onto the navigation stack.
  void push(BuildContext context) => GoRouter.of(context).push<void>(path);
}

/// The Phase 1 foundation smoke screen.
final class SmokeRoute extends AppRoute {
  const SmokeRoute();

  @override
  String get path => '/';
}
