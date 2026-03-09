part of 'auth_bloc.dart';

@immutable
sealed class AuthState {
  const AuthState();
}

/// Initial state when app starts
class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

/// Loading state during auth operations
class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

/// User is authenticated and ready to use the app
class AuthStateAuthenticated extends AuthState {
  final User user;

  const AuthStateAuthenticated({required this.user});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthStateAuthenticated &&
          runtimeType == other.runtimeType &&
          user.uid == other.user.uid;

  @override
  int get hashCode => user.uid.hashCode;
}

/// User is not authenticated
class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

/// Email verification is needed
class AuthStateEmailVerificationNeeded extends AuthState {
  final User user;

  const AuthStateEmailVerificationNeeded({required this.user});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthStateEmailVerificationNeeded &&
          runtimeType == other.runtimeType &&
          user.uid == other.user.uid;

  @override
  int get hashCode => user.uid.hashCode;
}

/// Register successful, waiting for email verification
class AuthStateRegisterSuccess extends AuthState {
  final User user;

  const AuthStateRegisterSuccess({required this.user});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthStateRegisterSuccess &&
          runtimeType == other.runtimeType &&
          user.uid == other.user.uid;

  @override
  int get hashCode => user.uid.hashCode;
}

/// Confirmation identity needed
class AuthStateConfirmingIdentity extends AuthState {
  final User user;

  const AuthStateConfirmingIdentity({required this.user});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthStateConfirmingIdentity &&
          runtimeType == other.runtimeType &&
          user.uid == other.user.uid;

  @override
  int get hashCode => user.uid.hashCode;
}

/// Error state
class AuthStateError extends AuthState {
  final String message;
  final String? code;

  const AuthStateError({required this.message, this.code});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthStateError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ (code?.hashCode ?? 0);
}
