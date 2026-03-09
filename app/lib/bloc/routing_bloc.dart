import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'routing_event.dart';
part 'routing_state.dart';

class RoutingBloc extends Bloc<RoutingEvent, RoutingState> {
  RoutingBloc() : super(const RoutingStateInitial()) {
    on<RoutingEventNavigateTo>(_onNavigateTo);
    on<RoutingEventNavigateToAndReplace>(_onNavigateToAndReplace);
    on<RoutingEventPopRoute>(_onPopRoute);
    on<RoutingEventClearNavigation>(_onClearNavigation);
  }

  /// Handle navigation to a route
  Future<void> _onNavigateTo(
    RoutingEventNavigateTo event,
    Emitter<RoutingState> emit,
  ) async {
    emit(
      RoutingStateNavigateTo(
        routeName: event.routeName,
        arguments: event.arguments,
      ),
    );
  }

  /// Handle navigation with route replacement
  Future<void> _onNavigateToAndReplace(
    RoutingEventNavigateToAndReplace event,
    Emitter<RoutingState> emit,
  ) async {
    emit(
      RoutingStateNavigateToAndReplace(
        routeName: event.routeName,
        arguments: event.arguments,
      ),
    );
  }

  /// Handle pop navigation
  Future<void> _onPopRoute(
    RoutingEventPopRoute event,
    Emitter<RoutingState> emit,
  ) async {
    emit(const RoutingStatePopRoute());
  }

  /// Handle clearing navigation stack
  Future<void> _onClearNavigation(
    RoutingEventClearNavigation event,
    Emitter<RoutingState> emit,
  ) async {
    emit(const RoutingStateInitial());
  }
}
