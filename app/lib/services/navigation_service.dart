import 'package:flutter/material.dart';

/// GlobalKey untuk navigation tanpa context
final navigatorKey = GlobalKey<NavigatorState>();

/// Navigation Service untuk centralized navigation
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();

  factory NavigationService() {
    return _instance;
  }

  NavigationService._internal();

  /// Get current context
  BuildContext? get context => navigatorKey.currentContext;

  /// Get navigator state
  NavigatorState? get navigator => navigatorKey.currentState;

  /// Push route
  Future<dynamic> pushNamed(String routeName, {Object? arguments}) {
    return navigator?.pushNamed(routeName, arguments: arguments) ??
        Future.value(null);
  }

  /// Push replacement route
  Future<dynamic> pushReplacementNamed(String routeName, {Object? arguments}) {
    return navigator?.pushReplacementNamed(routeName, arguments: arguments) ??
        Future.value(null);
  }

  /// Pop current route
  void pop<T extends Object?>({T? result}) {
    navigator?.pop(result);
  }

  /// Pop until route
  void popUntilNamed(String routeName) {
    navigator?.popUntil(ModalRoute.withName(routeName));
  }

  /// Push and remove until
  Future<dynamic> pushNamedAndRemoveUntil(
    String newRouteName, {
    required String untilRouteName,
    Object? arguments,
  }) {
    return navigator?.pushNamedAndRemoveUntil(
          newRouteName,
          ModalRoute.withName(untilRouteName),
          arguments: arguments,
        ) ??
        Future.value(null);
  }

  /// Replace route
  void replaceRoute(String routeName, {Object? arguments}) {
    pushReplacementNamed(routeName, arguments: arguments);
  }

  /// Check if can pop
  bool canPop() {
    return navigator?.canPop() ?? false;
  }

  /// Pop until first route
  void popToFirst() {
    navigator?.popUntil((route) => route.isFirst);
  }
}

/// Extension untuk easy access navigation
extension NavigationExtension on BuildContext {
  NavigationService get navigation => NavigationService();

  void push(String routeName, {Object? arguments}) {
    NavigationService().pushNamed(routeName, arguments: arguments);
  }

  void pushReplacement(String routeName, {Object? arguments}) {
    NavigationService().pushReplacementNamed(routeName, arguments: arguments);
  }

  void pop<T extends Object?>({T? result}) {
    NavigationService().pop(result: result);
  }
}
