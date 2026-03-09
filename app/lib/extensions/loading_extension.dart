import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/loading_bloc.dart';

/// Extension methods for easy loading state management
extension LoadingBlocExtension on BuildContext {
  /// Start loading with a message
  void showLoading({
    required String message,
    LoadingOperationType operationType = LoadingOperationType.general,
  }) {
    read<LoadingBloc>().add(
      LoadingEventStart(message: message, operationType: operationType),
    );
  }

  /// Update loading progress
  void updateLoading({
    required String message,
    required double progress,
    LoadingOperationType operationType = LoadingOperationType.general,
  }) {
    read<LoadingBloc>().add(
      LoadingEventUpdate(
        message: message,
        progress: progress.clamp(0.0, 1.0),
        operationType: operationType,
      ),
    );
  }

  /// Complete loading
  void hideLoading() {
    read<LoadingBloc>().add(const LoadingEventComplete());
  }

  /// Show loading and execute async operation with error handling
  Future<T?> withLoading<T>({
    required Future<T> Function() operation,
    required String loadingMessage,
    LoadingOperationType operationType = LoadingOperationType.general,
    bool shouldHideOnComplete = true,
  }) async {
    try {
      showLoading(message: loadingMessage, operationType: operationType);

      final result = await operation();

      if (shouldHideOnComplete && mounted) {
        hideLoading();
      }

      return result;
    } catch (e) {
      hideLoading();
      rethrow;
    }
  }
}

/// Extension for custom loading error handling
extension LoadingErrorExtension on BuildContext {
  /// Show loading error (shows error state in loading overlay)
  void showLoadingError({
    required String message,
    LoadingOperationType operationType = LoadingOperationType.general,
  }) {
    read<LoadingBloc>().add(
      LoadingEventError(message: message, operationType: operationType),
    );

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      read<LoadingBloc>().add(const LoadingEventComplete());
    });
  }
}
