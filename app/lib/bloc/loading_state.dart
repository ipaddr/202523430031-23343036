part of 'loading_bloc.dart';

@immutable
sealed class LoadingState {
  const LoadingState();
}

/// Initial state - no loading
class LoadingStateInitial extends LoadingState {
  const LoadingStateInitial();
}

/// Loading state with progress
class LoadingStateLoading extends LoadingState {
  final String message;
  final LoadingOperationType operationType;
  final double progress; // 0.0 to 1.0

  const LoadingStateLoading({
    required this.message,
    this.operationType = LoadingOperationType.general,
    this.progress = 0.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadingStateLoading &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          operationType == other.operationType &&
          progress == other.progress;

  @override
  int get hashCode =>
      message.hashCode ^ operationType.hashCode ^ progress.hashCode;
}

/// Error during loading
class LoadingStateError extends LoadingState {
  final String message;
  final LoadingOperationType operationType;

  const LoadingStateError({
    required this.message,
    this.operationType = LoadingOperationType.general,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadingStateError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          operationType == other.operationType;

  @override
  int get hashCode => message.hashCode ^ operationType.hashCode;
}
