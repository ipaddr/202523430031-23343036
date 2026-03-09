import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'loading_event.dart';
part 'loading_state.dart';

class LoadingBloc extends Bloc<LoadingEvent, LoadingState> {
  LoadingBloc() : super(const LoadingStateInitial()) {
    on<LoadingEventStart>(_onStart);
    on<LoadingEventUpdate>(_onUpdate);
    on<LoadingEventComplete>(_onComplete);
    on<LoadingEventError>(_onError);
  }

  /// Start loading operation
  Future<void> _onStart(
    LoadingEventStart event,
    Emitter<LoadingState> emit,
  ) async {
    emit(
      LoadingStateLoading(
        message: event.message,
        operationType: event.operationType,
        progress: 0.0,
      ),
    );
  }

  /// Update loading progress
  Future<void> _onUpdate(
    LoadingEventUpdate event,
    Emitter<LoadingState> emit,
  ) async {
    emit(
      LoadingStateLoading(
        message: event.message,
        operationType: event.operationType,
        progress: event.progress,
      ),
    );
  }

  /// Complete loading operation
  Future<void> _onComplete(
    LoadingEventComplete event,
    Emitter<LoadingState> emit,
  ) async {
    emit(const LoadingStateInitial());
  }

  /// Error during loading
  Future<void> _onError(
    LoadingEventError event,
    Emitter<LoadingState> emit,
  ) async {
    emit(
      LoadingStateError(
        message: event.message,
        operationType: event.operationType,
      ),
    );
  }
}
