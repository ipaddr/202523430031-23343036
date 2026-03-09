part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {
  const AuthEvent();
}

class AuthEventRegister extends AuthEvent {
  final String email;
  final String password;
  final String fullName;

  const AuthEventRegister({
    required this.email,
    required this.password,
    required this.fullName,
  });
}

class AuthEventLogin extends AuthEvent {
  final String email;
  final String password;

  const AuthEventLogin({required this.email, required this.password});
}

class AuthEventLogout extends AuthEvent {
  const AuthEventLogout();
}

class AuthEventSendEmailVerification extends AuthEvent {
  const AuthEventSendEmailVerification();
}

class AuthEventCheckEmailVerified extends AuthEvent {
  const AuthEventCheckEmailVerified();
}

class AuthEventReloadUser extends AuthEvent {
  const AuthEventReloadUser();
}

class AuthEventAuthStateChanged extends AuthEvent {
  final User? user;

  const AuthEventAuthStateChanged(this.user);
}

class AuthEventResetPassword extends AuthEvent {
  final String email;

  const AuthEventResetPassword({required this.email});
}

class AuthEventUpdateDisplayName extends AuthEvent {
  final String displayName;

  const AuthEventUpdateDisplayName({required this.displayName});
}
