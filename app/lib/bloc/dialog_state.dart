part of 'dialog_bloc.dart';

@immutable
sealed class DialogState {
  const DialogState();
}

/// Initial state - no dialog shown
class DialogStateInitial extends DialogState {
  const DialogStateInitial();
}

/// Error dialog state
class DialogStateShowError extends DialogState {
  final String title;
  final String message;
  final String? actionLabel;

  const DialogStateShowError({
    required this.title,
    required this.message,
    this.actionLabel,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DialogStateShowError &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          message == other.message &&
          actionLabel == other.actionLabel;

  @override
  int get hashCode =>
      title.hashCode ^ message.hashCode ^ (actionLabel?.hashCode ?? 0);
}

/// Success dialog state
class DialogStateShowSuccess extends DialogState {
  final String title;
  final String message;
  final String? actionLabel;

  const DialogStateShowSuccess({
    required this.title,
    required this.message,
    this.actionLabel,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DialogStateShowSuccess &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          message == other.message &&
          actionLabel == other.actionLabel;

  @override
  int get hashCode =>
      title.hashCode ^ message.hashCode ^ (actionLabel?.hashCode ?? 0);
}

/// Confirmation dialog state
class DialogStateShowConfirmation extends DialogState {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  const DialogStateShowConfirmation({
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DialogStateShowConfirmation &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          message == other.message &&
          confirmLabel == other.confirmLabel &&
          cancelLabel == other.cancelLabel;

  @override
  int get hashCode =>
      title.hashCode ^
      message.hashCode ^
      confirmLabel.hashCode ^
      cancelLabel.hashCode;
}

/// Snackbar state
class DialogStateShowSnackBar extends DialogState {
  final String message;
  final SnackBarType type;
  final Duration duration;

  const DialogStateShowSnackBar({
    required this.message,
    this.type = SnackBarType.info,
    this.duration = const Duration(seconds: 3),
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DialogStateShowSnackBar &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          type == other.type &&
          duration == other.duration;

  @override
  int get hashCode => message.hashCode ^ type.hashCode ^ duration.hashCode;
}
