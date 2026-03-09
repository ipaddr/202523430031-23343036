import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/services/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _userSubscription;

  AuthBloc() : super(const AuthStateInitial()) {
    // Register event handlers
    on<AuthEventRegister>(_onRegister);
    on<AuthEventLogin>(_onLogin);
    on<AuthEventLogout>(_onLogout);
    on<AuthEventSendEmailVerification>(_onSendEmailVerification);
    on<AuthEventCheckEmailVerified>(_onCheckEmailVerified);
    on<AuthEventReloadUser>(_onReloadUser);
    on<AuthEventAuthStateChanged>(_onAuthStateChanged);
    on<AuthEventResetPassword>(_onResetPassword);
    on<AuthEventUpdateDisplayName>(_onUpdateDisplayName);

    // Listen to auth state changes
    _initAuthStateListener();
  }

  void _initAuthStateListener() {
    _userSubscription = _authService.userStateChanges.listen((user) {
      add(AuthEventAuthStateChanged(user));
    });
  }

  /// Handle user registration
  Future<void> _onRegister(
    AuthEventRegister event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthStateLoading());

      final userCredential = await _authService.registerWithEmail(
        event.email,
        event.password,
        event.fullName,
      );

      if (userCredential?.user != null) {
        emit(AuthStateRegisterSuccess(user: userCredential!.user!));
      } else {
        emit(
          const AuthStateError(
            message: 'Pendaftaran gagal',
            code: 'REGISTRATION_FAILED',
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthStateError(message: _getAuthErrorMessage(e.code), code: e.code));
    } catch (e) {
      emit(AuthStateError(message: 'Terjadi kesalahan: ${e.toString()}'));
    }
  }

  /// Handle user login
  Future<void> _onLogin(AuthEventLogin event, Emitter<AuthState> emit) async {
    try {
      emit(const AuthStateLoading());

      final userCredential = await _authService.loginWithEmail(
        event.email,
        event.password,
      );

      if (userCredential?.user != null) {
        final user = userCredential!.user!;
        if (user.emailVerified) {
          emit(AuthStateAuthenticated(user: user));
        } else {
          emit(AuthStateEmailVerificationNeeded(user: user));
        }
      } else {
        emit(
          const AuthStateError(message: 'Login gagal', code: 'LOGIN_FAILED'),
        );
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthStateError(message: _getAuthErrorMessage(e.code), code: e.code));
    } catch (e) {
      emit(AuthStateError(message: 'Terjadi kesalahan: ${e.toString()}'));
    }
  }

  /// Handle user logout
  Future<void> _onLogout(AuthEventLogout event, Emitter<AuthState> emit) async {
    try {
      await _authService.logout();
      emit(const AuthStateUnauthenticated());
    } catch (e) {
      emit(AuthStateError(message: 'Logout gagal: ${e.toString()}'));
    }
  }

  /// Handle sending email verification
  Future<void> _onSendEmailVerification(
    AuthEventSendEmailVerification event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthStateLoading());
      await _authService.sendEmailVerification();
      emit(const AuthStateLoading()); // Keep loading until email is verified
    } catch (e) {
      emit(
        AuthStateError(
          message: 'Gagal mengirim email verifikasi: ${e.toString()}',
        ),
      );
    }
  }

  /// Handle checking if email is verified
  Future<void> _onCheckEmailVerified(
    AuthEventCheckEmailVerified event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthStateLoading());
      final isVerified = await _authService.isEmailVerified();
      final user = _authService.currentUser;

      if (isVerified && user != null) {
        emit(AuthStateAuthenticated(user: user));
      } else if (user != null) {
        emit(AuthStateEmailVerificationNeeded(user: user));
      } else {
        emit(const AuthStateUnauthenticated());
      }
    } catch (e) {
      emit(
        AuthStateError(
          message: 'Gagal memeriksa verifikasi email: ${e.toString()}',
        ),
      );
    }
  }

  /// Handle reloading user data
  Future<void> _onReloadUser(
    AuthEventReloadUser event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.reloadUser();
      final user = _authService.currentUser;

      if (user != null) {
        if (user.emailVerified) {
          emit(AuthStateAuthenticated(user: user));
        } else {
          emit(AuthStateEmailVerificationNeeded(user: user));
        }
      } else {
        emit(const AuthStateUnauthenticated());
      }
    } catch (e) {
      emit(
        AuthStateError(message: 'Gagal memperbarui data user: ${e.toString()}'),
      );
    }
  }

  /// Handle auth state changes from Firebase
  Future<void> _onAuthStateChanged(
    AuthEventAuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;

    if (user == null) {
      emit(const AuthStateUnauthenticated());
    } else if (user.emailVerified) {
      emit(AuthStateAuthenticated(user: user));
    } else {
      emit(AuthStateEmailVerificationNeeded(user: user));
    }
  }

  /// Handle password reset
  Future<void> _onResetPassword(
    AuthEventResetPassword event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthStateLoading());
      await _authService.sendPasswordResetEmail(event.email);
      // Keep authenticated or unauthenticated state depending on current state
    } catch (e) {
      emit(
        AuthStateError(
          message: 'Gagal mengirim email reset password: ${e.toString()}',
        ),
      );
    }
  }

  /// Handle updating display name
  Future<void> _onUpdateDisplayName(
    AuthEventUpdateDisplayName event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthStateLoading());
      await _authService.updateDisplayName(event.displayName);
      final user = _authService.currentUser;

      if (user != null) {
        if (user.emailVerified) {
          emit(AuthStateAuthenticated(user: user));
        } else {
          emit(AuthStateEmailVerificationNeeded(user: user));
        }
      }
    } catch (e) {
      emit(AuthStateError(message: 'Gagal memperbarui nama: ${e.toString()}'));
    }
  }

  /// Convert Firebase auth exception codes to user-friendly messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Pengguna tidak ditemukan';
      case 'wrong-password':
        return 'Password salah';
      case 'invalid-email':
        return 'Email tidak valid';
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'weak-password':
        return 'Password terlalu lemah';
      case 'user-disabled':
        return 'Akun telah dinonaktifkan';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan login. Coba lagi nanti';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan';
      case 'invalid-credential':
        return 'Email atau password salah';
      default:
        return 'Terjadi kesalahan autentikasi';
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
