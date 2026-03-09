part of 'routing_bloc.dart';

@immutable
sealed class RoutingState {
  const RoutingState();
}

/// Initial routing state
class RoutingStateInitial extends RoutingState {
  const RoutingStateInitial();
}

/// Navigation to a specific route (push)
class RoutingStateNavigateTo extends RoutingState {
  final String routeName;
  final Object? arguments;

  const RoutingStateNavigateTo({required this.routeName, this.arguments});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutingStateNavigateTo &&
          runtimeType == other.runtimeType &&
          routeName == other.routeName &&
          arguments == other.arguments;

  @override
  int get hashCode => routeName.hashCode ^ (arguments?.hashCode ?? 0);
}

/// Navigation with route replacement
class RoutingStateNavigateToAndReplace extends RoutingState {
  final String routeName;
  final Object? arguments;

  const RoutingStateNavigateToAndReplace({
    required this.routeName,
    this.arguments,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutingStateNavigateToAndReplace &&
          runtimeType == other.runtimeType &&
          routeName == other.routeName &&
          arguments == other.arguments;

  @override
  int get hashCode => routeName.hashCode ^ (arguments?.hashCode ?? 0);
}

/// Pop route state
class RoutingStatePopRoute extends RoutingState {
  const RoutingStatePopRoute();
}
