import 'auth_user.dart';

abstract class AuthProvider {
  Future<void> initialize();

  Future<AuthUser> createUser({
    required String email,
    required String password,
  });

  Future<AuthUser> logIn({required String email, required String password});

  Future<void> logOut();

  Future<AuthUser> sendEmailVerification();

  AuthUser? get currentUser;

  bool get isInitialized;
}
