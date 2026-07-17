// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$smokeRouteData];

RouteBase get $smokeRouteData => GoRouteData.$route(
  path: '/',
  factory: $SmokeRouteData._fromState,
  routes: [
    GoRouteData.$route(
      path: 'detail/:probeId',
      factory: $FoundationDetailRouteData._fromState,
    ),
  ],
);

mixin $SmokeRouteData on GoRouteData {
  static SmokeRouteData _fromState(GoRouterState state) =>
      const SmokeRouteData();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $FoundationDetailRouteData on GoRouteData {
  static FoundationDetailRouteData _fromState(GoRouterState state) =>
      FoundationDetailRouteData(probeId: state.pathParameters['probeId']!);

  FoundationDetailRouteData get _self => this as FoundationDetailRouteData;

  @override
  String get location =>
      GoRouteData.$location('/detail/${Uri.encodeComponent(_self.probeId)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
