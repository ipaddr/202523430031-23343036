part of 'loading_bloc.dart';

@immutable
sealed class LoadingEvent {
  const LoadingEvent();
}

/// Start loading operation
class LoadingEventStart extends LoadingEvent {
  final String message;
  final LoadingOperationType operationType;

  const LoadingEventStart({
    required this.message,
    this.operationType = LoadingOperationType.general,
  });
}

/// Update loading progress
class LoadingEventUpdate extends LoadingEvent {
  final String message;
  final double progress;
  final LoadingOperationType operationType;

  const LoadingEventUpdate({
    required this.message,
    required this.progress,
    this.operationType = LoadingOperationType.general,
  });
}

/// Complete loading operation
class LoadingEventComplete extends LoadingEvent {
  const LoadingEventComplete();
}

/// Loading error
class LoadingEventError extends LoadingEvent {
  final String message;
  final LoadingOperationType operationType;

  const LoadingEventError({
    required this.message,
    this.operationType = LoadingOperationType.general,
  });
}

/// Types of loading operations
enum LoadingOperationType {
  login,
  registration,
  emailVerification,
  passwordReset,
  dataFetch,
  dataSave,
  general,
}
