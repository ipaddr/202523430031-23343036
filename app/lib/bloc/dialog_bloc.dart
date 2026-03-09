import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'dialog_event.dart';
part 'dialog_state.dart';

class DialogBloc extends Bloc<DialogEvent, DialogState> {
  DialogBloc() : super(const DialogStateInitial()) {
    on<DialogEventShowError>(_onShowError);
    on<DialogEventShowSuccess>(_onShowSuccess);
    on<DialogEventShowConfirmation>(_onShowConfirmation);
    on<DialogEventShowSnackBar>(_onShowSnackBar);
    on<DialogEventDismiss>(_onDismiss);
  }

  /// Show error dialog
  Future<void> _onShowError(
    DialogEventShowError event,
    Emitter<DialogState> emit,
  ) async {
    emit(
      DialogStateShowError(
        title: event.title,
        message: event.message,
        actionLabel: event.actionLabel,
      ),
    );
  }

  /// Show success dialog
  Future<void> _onShowSuccess(
    DialogEventShowSuccess event,
    Emitter<DialogState> emit,
  ) async {
    emit(
      DialogStateShowSuccess(
        title: event.title,
        message: event.message,
        actionLabel: event.actionLabel,
      ),
    );
  }

  /// Show confirmation dialog
  Future<void> _onShowConfirmation(
    DialogEventShowConfirmation event,
    Emitter<DialogState> emit,
  ) async {
    emit(
      DialogStateShowConfirmation(
        title: event.title,
        message: event.message,
        confirmLabel: event.confirmLabel,
        cancelLabel: event.cancelLabel,
      ),
    );
  }

  /// Show snackbar
  Future<void> _onShowSnackBar(
    DialogEventShowSnackBar event,
    Emitter<DialogState> emit,
  ) async {
    emit(
      DialogStateShowSnackBar(
        message: event.message,
        type: event.type,
        duration: event.duration,
      ),
    );
  }

  /// Dismiss dialog
  Future<void> _onDismiss(
    DialogEventDismiss event,
    Emitter<DialogState> emit,
  ) async {
    emit(const DialogStateInitial());
  }
}
