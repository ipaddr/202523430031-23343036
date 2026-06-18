import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase_options.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  static const String _adminAuthAppName = 'admin_user_creation';
  static const Set<String> _allowedRoles = {'user', 'petugas', 'admin'};

  late final firebase_auth.FirebaseAuth _firebaseAuth;
  late final FirebaseFirestore _firestore;
  late final GoogleSignIn _googleSignIn;
  late final Future<void> _googleSignInInitialization;

  factory FirebaseAuthService() {
    return _instance;
  }

  FirebaseAuthService._internal() {
    _firebaseAuth = firebase_auth.FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;

    // Initialize GoogleSignIn with serverClientId from Firebase
    // Web Client ID untuk project: smartwaste-61572
    // Dapatkan dari: Firebase Console > Project Settings > Service Accounts > OAuth 2.0 Client IDs
    // Format: xxxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com

    _googleSignIn = GoogleSignIn.instance;

    // Request the same scopes the old API used by default.
    // The new package requires explicit initialization before sign-in.
    _googleSignInInitialization = _googleSignIn.initialize(
      serverClientId:
          '687933984929-uq8scv3je04m3u99cp6tfch8p6dbd8pg.apps.googleusercontent.com',
    );
  }

  String _normalizeRole(String role) {
    final normalized = role.trim().toLowerCase();
    if (_allowedRoles.contains(normalized)) {
      return normalized;
    }
    return 'user';
  }

  Future<FirebaseApp> _getAdminCreationApp() async {
    try {
      return Firebase.app(_adminAuthAppName);
    } catch (_) {
      return Firebase.initializeApp(
        name: _adminAuthAppName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  // Register with email and password + send verification email
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'user',
  }) async {
    try {
      // Create user with Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;
      if (uid == null) throw Exception('Failed to get user ID');

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      final Map<String, dynamic> userData = {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'status': 'Aktif',
        'points': 0,
        'wasteCollected': 0,
        'profileImage': null,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (role == 'petugas') {
        userData.addAll({
          'assignedRequests': 0,
          'completedRequests': 0,
          'total_tasks': 0,
          'completed_tasks': 0,
          'average_rating': 0.0,
          'total_ratings': 0,
        });
      }

      // Save user data to Firestore with emailVerified flag
      await _firestore.collection('users').doc(uid).set(userData);

      return {
        'success': true,
        'message': 'Akun dibuat. Silakan verifikasi email Anda',
        'uid': uid,
        'requiresEmailVerification': true,
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
        'error': e.code,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Create a new user from the admin panel without affecting the primary session.
  Future<Map<String, dynamic>> createUserByAdmin({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    bool sendVerificationEmail = true,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim();
    final normalizedPhone = phone.trim();
    final normalizedRole = _normalizeRole(role);

    if (normalizedName.isEmpty ||
        normalizedEmail.isEmpty ||
        normalizedPhone.isEmpty ||
        password.isEmpty) {
      return {
        'success': false,
        'message': 'Nama, email, telepon, dan password wajib diisi',
      };
    }

    try {
      final adminUser = currentUser;
      if (adminUser == null) {
        return {
          'success': false,
          'message': 'Silakan login sebagai admin terlebih dahulu',
          'error': 'NOT_AUTHENTICATED',
        };
      }

      final adminDoc = await _firestore
          .collection('users')
          .doc(adminUser.uid)
          .get();
      final adminRole = (adminDoc.data()?['role'] ?? '')
          .toString()
          .toLowerCase();
      if (adminRole != 'admin') {
        return {
          'success': false,
          'message': 'Hanya admin yang dapat menambahkan pengguna',
          'error': 'FORBIDDEN',
        };
      }

      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Email sudah terdaftar di sistem',
          'error': 'EMAIL_ALREADY_EXISTS',
        };
      }

      final secondaryApp = await _getAdminCreationApp();
      final secondaryAuth = firebase_auth.FirebaseAuth.instanceFor(
        app: secondaryApp,
      );

      firebase_auth.UserCredential? createdCredential;

      try {
        createdCredential = await secondaryAuth.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );

        final createdUser = createdCredential.user;
        if (createdUser == null) {
          throw Exception('Failed to create auth user');
        }

        final uid = createdUser.uid;

        final Map<String, dynamic> userData = {
          'uid': uid,
          'name': normalizedName,
          'email': normalizedEmail,
          'phone': normalizedPhone,
          'role': normalizedRole,
          'status': 'Aktif',
          'points': 0,
          'wasteCollected': 0,
          'profileImage': null,
          'emailVerified': false,
          'createdBy': adminUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (normalizedRole == 'petugas') {
          userData.addAll({
            'assignedRequests': 0,
            'completedRequests': 0,
            'total_tasks': 0,
            'completed_tasks': 0,
            'average_rating': 0.0,
            'total_ratings': 0,
          });
        }

        await _firestore.collection('users').doc(uid).set(userData);

        bool verificationEmailSent = false;
        if (sendVerificationEmail) {
          try {
            await createdUser.sendEmailVerification();
            verificationEmailSent = true;
          } catch (e) {
            debugPrint('Error sending admin-created verification email: $e');
          }
        }

        return {
          'success': true,
          'message': 'Pengguna berhasil ditambahkan',
          'uid': uid,
          'role': normalizedRole,
          'verificationEmailSent': verificationEmailSent,
        };
      } catch (e) {
        final createdUser = createdCredential?.user;
        if (createdUser != null) {
          try {
            await createdUser.delete();
          } catch (deleteError) {
            debugPrint('Error rolling back created auth user: $deleteError');
          }
        }
        rethrow;
      } finally {
        try {
          await secondaryAuth.signOut();
        } catch (e) {
          debugPrint('Error signing out secondary auth: $e');
        }
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
        'error': e.code,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<bool> updateUserStatus({
    required String userId,
    required String status,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating user status: $e');
      return false;
    }
  }

  Future<bool> updateUserRole({
    required String userId,
    required String role,
  }) async {
    try {
      final normalizedRole = _normalizeRole(role);
      final Map<String, dynamic> updateData = {
        'role': normalizedRole,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (normalizedRole == 'petugas') {
        updateData.addAll({
          'assignedRequests': 0,
          'completedRequests': 0,
          'total_tasks': 0,
          'completed_tasks': 0,
          'average_rating': 0.0,
          'total_ratings': 0,
        });
      }

      await _firestore.collection('users').doc(userId).update(updateData);
      return true;
    } catch (e) {
      debugPrint('Error updating user role: $e');
      return false;
    }
  }

  // Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return false;

      await user.sendEmailVerification();
      return true;
    } catch (e) {
      debugPrint('Error sending email verification: $e');
      return false;
    }
  }

  // Check email verified
  Future<bool> checkEmailVerified() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return false;

      // Refresh to get latest verification status
      await user.reload();
      return user.emailVerified;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
    }
  }

  // Update email verified status in Firestore
  Future<bool> updateEmailVerifiedStatus() async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return false;

      final isVerified = await checkEmailVerified();

      await _firestore.collection('users').doc(uid).update({
        'emailVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error updating email verified status: $e');
      return false;
    }
  }

  // Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;
      if (uid == null) throw Exception('Failed to get user ID');

      // Get user data from Firestore
      final userDocRef = _firestore.collection('users').doc(uid);
      var userDoc = await userDocRef.get();

      // If Firestore document doesn't exist (user created in Auth only), create a minimal record
      if (!userDoc.exists) {
        debugPrint(
          'Firestore user doc not found for uid=$uid. Creating default document.',
        );

        final defaultData = {
          'uid': uid,
          'name': userCredential.user?.displayName ?? 'User',
          'email': userCredential.user?.email ?? email,
          'phone': '',
          'role': 'user',
          'status': 'Aktif',
          'points': 0,
          'wasteCollected': 0,
          'profileImage': userCredential.user?.photoURL,
          'emailVerified': userCredential.user?.emailVerified ?? false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await userDocRef.set(defaultData);
        // re-read the document
        userDoc = await userDocRef.get();
      }

      final userData = userDoc.data();
      if (userData == null) {
        throw Exception('User data is empty');
      }

      return {
        'success': true,
        'message': 'Login berhasil',
        'uid': uid,
        'userData': userData,
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
        'error': e.code,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Reset password
  // Send the standard Firebase Auth password reset email link.
  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    try {
      final normalizedEmail = email.trim();
      await _firebaseAuth.sendPasswordResetEmail(email: normalizedEmail);

      return {
        'success': true,
        'message': 'Link reset password telah dikirim ke email Anda',
        'email': normalizedEmail,
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
        'error': e.code,
      };
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'error': 'RESET_EMAIL_ERROR',
      };
    }
  }

  // Verify password reset code
  Future<Map<String, dynamic>> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    return {
      'success': false,
      'message':
          'Reset password sekarang menggunakan link email. Silakan cek inbox Anda.',
    };
  }

  // Reset password after code verification
  Future<Map<String, dynamic>> resetPasswordWithCode({
    required String email,
    required String newPassword,
  }) async {
    return {
      'success': false,
      'message':
          'Reset password sekarang menggunakan link email. Silakan cek inbox Anda.',
    };
  }

  // Get current user
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  // Get current user data from Firestore
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return null;

      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return null;

      final data = userDoc.data();
      return data;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Update user data
  Future<bool> updateUserData(Map<String, dynamic> data) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error updating user data: $e');
      return false;
    }
  }

  // Add points to user
  Future<bool> addPoints(int points) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(uid).update({
        'points': FieldValue.increment(points),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error adding points: $e');
      return false;
    }
  }

  // Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign-In...');

      await _googleSignInInitialization;

      final googleUser = await _googleSignIn.authenticate();

      debugPrint('Google user: ${googleUser.email}');

      final googleAuth = googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      debugPrint('Signing in with Google credential...');
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user == null) throw Exception('Failed to create user');

      debugPrint('User signed in: ${user.uid}');

      // Check if user already exists in Firestore
      debugPrint('Checking if user exists in Firestore...');
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        debugPrint('New user detected. Saving to Firestore...');
        // New user - save to Firestore
        try {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName ?? 'User',
            'email': user.email ?? '',
            'phone': '',
            'role': 'user',
            'status': 'Aktif',
            'points': 0,
            'wasteCollected': 0,
            'profileImage': user.photoURL,
            'emailVerified': user.emailVerified,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('User data saved to Firestore successfully');
        } catch (e) {
          debugPrint('Error saving user to Firestore: $e');
          rethrow;
        }

        // Send email verification if not verified
        if (!user.emailVerified) {
          debugPrint('Sending email verification...');
          try {
            await user.sendEmailVerification();
            debugPrint('Email verification sent');
          } catch (e) {
            debugPrint('Error sending email verification: $e');
          }
        }
      } else {
        debugPrint('Existing user found in Firestore');
      }

      // Get user data from Firestore
      debugPrint('Retrieving user data from Firestore...');
      final userDocData = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDocData.data();
      if (userData == null) {
        throw Exception('Failed to get user data from Firestore');
      }

      debugPrint('User data retrieved successfully');

      return {
        'success': true,
        'message': 'Login dengan Google berhasil',
        'uid': user.uid,
        'userData': userData,
        'requiresEmailVerification': !user.emailVerified,
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
        'error': e.code,
      };
    } catch (e) {
      debugPrint('=== Google Sign-In ERROR ===');
      debugPrint('Error Type: ${e.runtimeType}');
      debugPrint('Error Message: $e');
      debugPrint('Error String: ${e.toString()}');

      // Parse error message
      String errorMsg = 'Terjadi kesalahan dengan Google Sign-In';
      String errorCode = 'UNKNOWN';

      final errorString = e.toString().toLowerCase();

      // Check for specific error patterns
      if (errorString.contains('sign_in_cancelled') ||
          errorString.contains('cancelled')) {
        errorMsg = 'Google Sign-In dibatalkan';
        errorCode = 'CANCELLED';
      } else if (errorString.contains('permission-denied') ||
          errorString.contains('permission_denied')) {
        errorMsg =
            'Tidak ada izin untuk menyimpan data ke Firestore. Periksa security rules di Firebase Console.';
        errorCode = 'PERMISSION_DENIED';
      } else if (errorString.contains('developer_error') ||
          errorString.contains('developer error') ||
          errorString.contains('code 10')) {
        errorMsg =
            'Konfigurasi Google Sign-In tidak sesuai:\n1. Pastikan Web Client ID sudah benar\n2. Registrasi SHA-1 fingerprint di Firebase\n3. Restart aplikasi';
        errorCode = 'DEVELOPER_ERROR';
      } else if (errorString.contains('network') ||
          errorString.contains('connection')) {
        errorMsg = 'Koneksi internet tidak stabil. Silakan coba lagi.';
        errorCode = 'NETWORK_ERROR';
      } else if (errorString.contains('operation_in_progress') ||
          errorString.contains('in progress')) {
        errorMsg = 'Google Sign-In sedang berlangsung. Tunggu sebentar...';
        errorCode = 'IN_PROGRESS';
      } else if (errorString.contains('sign_in_required')) {
        errorMsg = 'Silakan sign in dengan Google terlebih dahulu';
        errorCode = 'SIGN_IN_REQUIRED';
      } else if (errorString.contains('network_error')) {
        errorMsg = 'Error jaringan. Periksa koneksi internet Anda.';
        errorCode = 'NETWORK_ERROR';
      } else if (errorString.contains('internal_error')) {
        errorMsg = 'Error internal Google. Coba lagi dalam beberapa saat.';
        errorCode = 'INTERNAL_ERROR';
      } else {
        // Fallback: include actual error for debugging
        errorMsg = 'Error: ${e.toString().split('\n').first}';
        errorCode = 'OTHER';
      }

      debugPrint('Parsed Error Code: $errorCode');
      debugPrint('=== END ERROR ===');

      return {
        'success': false,
        'message': errorMsg,
        'error': errorCode,
        'details': e.toString(),
      };
    }
  }

  // Logout (also sign out from Google)
  Future<void> logout() async {
    await _googleSignInInitialization;
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  // Helper method to get error message
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email tidak terdaftar';
      case 'wrong-password':
        return 'Password salah';
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'weak-password':
        return 'Password terlalu lemah';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan';
      default:
        return 'Error: $code';
    }
  }
}
