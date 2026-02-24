import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user auth state stream
  Stream<User?> get userStateChanges => _auth.userChanges();

  /// Register user dengan email dan password
  /// Returns UserCredential jika berhasil, throws FirebaseAuthException jika gagal
  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      // Create user account
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      await userCredential.user?.updateDisplayName(fullName);
      await userCredential.user?.reload();

      // Create user profile di Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'fullName': fullName,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      });

      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Login user dengan email dan password
  /// Returns UserCredential jika berhasil, throws FirebaseAuthException jika gagal
  Future<UserCredential?> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Send verification email ke current user
  Future<void> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Check apakah email sudah diverifikasi
  Future<bool> isEmailVerified() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Reload user data dari Firebase
  Future<void> reloadUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
      }
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Get user profile dari Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile di Firestore
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Parse Firebase Auth error ke Indonesian message
  String parseFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'Email tidak terdaftar. Silakan membuat akun baru.';
      case 'wrong-password':
        return 'Password salah. Silakan coba lagi.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun Anda telah dinonaktifkan. Hubungi support.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan login gagal. Coba lagi nanti.';
      case 'operation-not-allowed':
        return 'Operasi login tidak tersedia saat ini.';
      case 'network-error':
        return 'Koneksi internet tidak stabil. Coba lagi.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Gunakan email lain atau login.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'invalid-credential':
        return 'Email atau password salah. Silakan coba lagi.';
      default:
        return 'Terjadi kesalahan: ${error.message}';
    }
  }
}
