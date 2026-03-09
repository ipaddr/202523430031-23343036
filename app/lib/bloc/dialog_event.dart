part of 'dialog_bloc.dart';

@immutable
sealed class DialogEvent {
  const DialogEvent();
}

/// Show error dialog
class DialogEventShowError extends DialogEvent {
  final String title;
  final String message;
  final String? actionLabel;

  const DialogEventShowError({
    required this.title,
    required this.message,
    this.actionLabel,
  });
}

/// Show success dialog
class DialogEventShowSuccess extends DialogEvent {
  final String title;
  final String message;
  final String? actionLabel;

  const DialogEventShowSuccess({
    required this.title,
    required this.message,
    this.actionLabel,
  });
}

/// Show confirmation dialog
class DialogEventShowConfirmation extends DialogEvent {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  const DialogEventShowConfirmation({
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
  });
}

/// Show snackbar
class DialogEventShowSnackBar extends DialogEvent {
  final String message;
  final SnackBarType type;
  final Duration duration;

  const DialogEventShowSnackBar({
    required this.message,
    this.type = SnackBarType.info,
    this.duration = const Duration(seconds: 3),
  });
}

/// Dismiss dialog
class DialogEventDismiss extends DialogEvent {
  const DialogEventDismiss();
}

/// Snackbar types
enum SnackBarType { info, success, error, warning }
