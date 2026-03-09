import 'dart:async';
import 'dart:io';
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

      // Validate input
      final validationError = _validateRegistrationInput(
        event.email,
        event.password,
        event.fullName,
      );
      if (validationError != null) {
        emit(
          AuthStateError(message: validationError, code: 'VALIDATION_ERROR'),
        );
        return;
      }

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
            message: 'Pendaftaran gagal. Silakan coba lagi',
            code: 'REGISTRATION_FAILED',
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      final errorMessage = _getAuthErrorMessage(e.code, e.message);
      emit(AuthStateError(message: errorMessage, code: e.code));
    } on SocketException {
      emit(
        const AuthStateError(
          message:
              'Tidak ada koneksi internet. Periksa koneksi Anda dan coba lagi',
          code: 'NETWORK_ERROR',
        ),
      );
    } on TimeoutException {
      emit(
        const AuthStateError(
          message: 'Permintaan timeout. Silakan periksa koneksi internet Anda',
          code: 'TIMEOUT_ERROR',
        ),
      );
    } catch (e) {
      emit(
        AuthStateError(
          message: 'Terjadi kesalahan tidak terduga: ${e.toString()}',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  /// Validate registration input
  String? _validateRegistrationInput(
    String email,
    String password,
    String fullName,
  ) {
    if (fullName.trim().isEmpty) {
      return 'Nama lengkap tidak boleh kosong';
    }
    if (fullName.length < 3) {
      return 'Nama lengkap minimal harus 3 karakter';
    }
    if (email.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!_isValidEmail(email)) {
      return 'Format email tidak valid';
    }
    if (password.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (password.length < 6) {
      return 'Password minimal harus 6 karakter';
    }
    if (!_isPasswordStrong(password)) {
      return 'Password harus mengandung huruf besar, huruf kecil, dan angka';
    }
    return null;
  }

  /// Check if password is strong
  bool _isPasswordStrong(String password) {
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    return hasUppercase && hasLowercase && hasNumber;
  }

  /// Handle user login
  Future<void> _onLogin(AuthEventLogin event, Emitter<AuthState> emit) async {
    try {
      emit(const AuthStateLoading());

      // Validate input
      final validationError = _validateLoginInput(event.email, event.password);
      if (validationError != null) {
        emit(
          AuthStateError(message: validationError, code: 'VALIDATION_ERROR'),
        );
        return;
      }

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
          const AuthStateError(
            message: 'Login gagal. Silakan coba lagi',
            code: 'LOGIN_FAILED',
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      final errorMessage = _getAuthErrorMessage(e.code, e.message);
      emit(AuthStateError(message: errorMessage, code: e.code));
    } on SocketException {
      emit(
        AuthStateError(
          message:
              'Tidak ada koneksi internet. Periksa koneksi Anda dan coba lagi',
          code: 'NETWORK_ERROR',
        ),
      );
    } on TimeoutException {
      emit(
        AuthStateError(
          message: 'Permintaan timeout. Silakan periksa koneksi internet Anda',
          code: 'TIMEOUT_ERROR',
        ),
      );
    } catch (e) {
      emit(
        AuthStateError(
          message: 'Terjadi kesalahan tidak terduga: ${e.toString()}',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  /// Validate login input
  String? _validateLoginInput(String email, String password) {
    if (email.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!_isValidEmail(email)) {
      return 'Format email tidak valid';
    }
    if (password.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (password.length < 6) {
      return 'Password minimal harus 6 karakter';
    }
    return null;
  }

  /// Check if email format is valid
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Handle user logout
  Future<void> _onLogout(AuthEventLogout event, Emitter<AuthState> emit) async {
    try {
      await _authService.logout();
      emit(const AuthStateUnauthenticated());
    } on SocketException {
      emit(
        const AuthStateError(
          message: 'Logout gagal: Tidak ada koneksi internet',
          code: 'NETWORK_ERROR',
        ),
      );
    } catch (e) {
      emit(
        AuthStateError(
          message: 'Logout gagal: ${e.toString()}',
          code: 'LOGOUT_ERROR',
        ),
      );
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
    } on SocketException {
      emit(
        const AuthStateError(
          message: 'Gagal mengirim email: Tidak ada koneksi internet',
          code: 'NETWORK_ERROR',
        ),
      );
    } on TimeoutException {
      emit(
        const AuthStateError(
          message: 'Permintaan timeout. Silakan coba lagi',
          code: 'TIMEOUT_ERROR',
        ),
      );
    } catch (e) {
      emit(
        AuthStateError(
          message:
              'Gagal mengirim email verifikasi. Silakan coba lagi: ${e.toString()}',
          code: 'VERIFICATION_EMAIL_FAILED',
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
    } on SocketException {
      emit(
        const AuthStateError(
          message: 'Gagal memeriksa verifikasi: Tidak ada koneksi internet',
          code: 'NETWORK_ERROR',
        ),
      );
    } on TimeoutException {
      emit(
        const AuthStateError(
          message: 'Permintaan timeout. Silakan coba lagi',
          code: 'TIMEOUT_ERROR',
        ),
      );
    } catch (e) {
      emit(
        AuthStateError(
          message:
              'Gagal memeriksa verifikasi email. Silakan coba lagi: ${e.toString()}',
          code: 'CHECK_VERIFICATION_FAILED',
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
    } on SocketException {
      emit(
        const AuthStateError(
          message: 'Gagal memperbarui data: Tidak ada koneksi internet',
          code: 'NETWORK_ERROR',
        ),
      );
    } catch (e) {
      emit(
        AuthStateError(
          message: 'Gagal memperbarui data user: ${e.toString()}',
          code: 'RELOAD_USER_FAILED',
        ),
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

      if (!_isValidEmail(event.email)) {
        emit(
          const AuthStateError(
            message: 'Format email tidak valid',
            code: 'INVALID_EMAIL',
          ),
        );
        return;
      }

      await _authService.sendPasswordResetEmail(event.email);
      // Emit success message - keep authenticated state if already logged in
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        if (currentUser.emailVerified) {
          emit(AuthStateAuthenticated(user: currentUser));
        } else {
          emit(AuthStateEmailVerificationNeeded(user: currentUser));
        }
      } else {
        emit(const AuthStateUnauthenticated());
      }
    } on FirebaseAuthException catch (e) {
      final errorMessage = _getAuthErrorMessage(e.code, e.message);
      emit(AuthStateError(message: errorMessage, code: e.code));
    } on SocketException {
      emit(
        const AuthStateError(
          message: 'Gagal mengirim email reset: Tidak ada koneksi internet',
          code: 'NETWORK_ERROR',
        ),
      );
    } catch (e) {
      emit(
        AuthStateError(
          message: 'Gagal mengirim email reset password: ${e.toString()}',
          code: 'RESET_PASSWORD_FAILED',
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

      if (event.displayName.trim().isEmpty) {
        emit(
          const AuthStateError(
            message: 'Nama tidak boleh kosong',
            code: 'VALIDATION_ERROR',
          ),
        );
        return;
      }

      if (event.displayName.length < 3) {
        emit(
          const AuthStateError(
            message: 'Nama minimal harus 3 karakter',
            code: 'VALIDATION_ERROR',
          ),
        );
        return;
      }

      await _authService.updateDisplayName(event.displayName);
      final user = _authService.currentUser;

      if (user != null) {
        if (user.emailVerified) {
          emit(AuthStateAuthenticated(user: user));
        } else {
          emit(AuthStateEmailVerificationNeeded(user: user));
        }
      }
    } on SocketException {
      emit(
        const AuthStateError(
          message: 'Gagal memperbarui nama: Tidak ada koneksi internet',
          code: 'NETWORK_ERROR',
        ),
      );
    } catch (e) {
      emit(
        AuthStateError(
          message: 'Gagal memperbarui nama: ${e.toString()}',
          code: 'UPDATE_NAME_FAILED',
        ),
      );
    }
  }

  /// Convert Firebase auth exception codes to user-friendly messages with recovery hints
  String _getAuthErrorMessage(String code, [String? originalMessage]) {
    switch (code) {
      case 'user-not-found':
        return 'Email tidak terdaftar. Silakan daftar terlebih dahulu atau periksa kembali email Anda';
      case 'wrong-password':
        return 'Password tidak sesuai. Jika Anda lupa password, gunakan fitur reset password';
      case 'invalid-email':
        return 'Format email tidak valid. Pastikan email Anda benar';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan gunakan email lain atau login ke akun Anda';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan kombinasi huruf, angka, dan simbol';
      case 'user-disabled':
        return 'Akun Anda telah dinonaktifkan. Hubungi support untuk informasi lebih lanjut';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan login gagal. Silakan coba lagi dalam beberapa menit atau reset password';
      case 'operation-not-allowed':
        return 'Operasi ini tidak diizinkan. Hubungi administrator';
      case 'invalid-credential':
        return 'Email atau password salah. Periksa kembali dan coba lagi';
      case 'network-request-failed':
        return 'Kesalahan jaringan. Periksa koneksi internet Anda dan coba lagi';
      case 'NETWORK_ERROR':
        return 'Tidak ada koneksi internet. Periksa koneksi Anda dan coba lagi';
      case 'TIMEOUT_ERROR':
        return 'Permintaan timeout. Silakan periksa koneksi internet Anda';
      case 'VALIDATION_ERROR':
        return 'Masukan tidak valid. Periksa email dan password Anda';
      default:
        return originalMessage ??
            'Terjadi kesalahan autentikasi. Silakan coba lagi';
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
