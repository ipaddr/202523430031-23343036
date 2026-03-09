part of 'routing_bloc.dart';

@immutable
sealed class RoutingEvent {
  const RoutingEvent();
}

/// Navigate to a route (push)
class RoutingEventNavigateTo extends RoutingEvent {
  final String routeName;
  final Object? arguments;

  const RoutingEventNavigateTo({required this.routeName, this.arguments});
}

/// Navigate and replace current route
class RoutingEventNavigateToAndReplace extends RoutingEvent {
  final String routeName;
  final Object? arguments;

  const RoutingEventNavigateToAndReplace({
    required this.routeName,
    this.arguments,
  });
}

/// Pop current route
class RoutingEventPopRoute extends RoutingEvent {
  const RoutingEventPopRoute();
}

/// Clear navigation stack
class RoutingEventClearNavigation extends RoutingEvent {
  const RoutingEventClearNavigation();
}
