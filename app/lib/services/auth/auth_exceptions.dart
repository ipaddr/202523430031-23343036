class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class NotInitializedException extends AuthException {
  NotInitializedException() : super('Auth service is not initialized');
}

class UserNotFoundAuthException extends AuthException {
  UserNotFoundAuthException() : super('User not found');
}

class WrongPasswordAuthException extends AuthException {
  WrongPasswordAuthException() : super('Wrong password');
}

class InvalidEmailAuthException extends AuthException {
  InvalidEmailAuthException() : super('Invalid email');
}

class WeakPasswordAuthException extends AuthException {
  WeakPasswordAuthException() : super('Weak password');
}

class EmailAlreadyInUseAuthException extends AuthException {
  EmailAlreadyInUseAuthException() : super('Email already in use');
}
