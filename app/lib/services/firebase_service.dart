import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
  Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'fullName': fullName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Terjadi kesalahan: $e';
    }
  }

  // Login with email and password
  Future<UserCredential?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Terjadi kesalahan: $e';
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      throw 'Gagal mengambil data pengguna: $e';
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String fullName,
    String? profileImageUrl,
  }) async {
    try {
      final uid = _auth.currentUser!.uid;
      await _firestore.collection('users').doc(uid).update({
        'fullName': fullName,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Gagal mengupdate profil: $e';
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Gagal logout: $e';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Gagal mengirim reset password: $e';
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      if (_auth.currentUser != null && !_auth.currentUser!.emailVerified) {
        await _auth.currentUser!.sendEmailVerification();
      }
    } catch (e) {
      throw 'Gagal mengirim email verifikasi: $e';
    }
  }

  // Reload user to check email verification status
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      throw 'Gagal memperbarui status pengguna: $e';
    }
  }

  // Check if email is verified
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // === NOTES OPERATIONS ===

  // Create a new note
  Future<String> createNote({
    required String title,
    required String content,
  }) async {
    try {
      final uid = _auth.currentUser!.uid;
      final docRef = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notes')
          .add({
            'title': title,
            'content': content,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      return docRef.id;
    } catch (e) {
      throw 'Gagal membuat catatan: $e';
    }
  }

  // Get all notes for current user
  Stream<List<Map<String, dynamic>>> getUserNotes() {
    try {
      final uid = _auth.currentUser!.uid;
      return _firestore
          .collection('users')
          .doc(uid)
          .collection('notes')
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return {'id': doc.id, ...doc.data()};
            }).toList();
          });
    } catch (e) {
      throw 'Gagal mengambil catatan: $e';
    }
  }

  // Get single note
  Future<Map<String, dynamic>?> getNote(String noteId) async {
    try {
      final uid = _auth.currentUser!.uid;
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notes')
          .doc(noteId)
          .get();
      return doc.data();
    } catch (e) {
      throw 'Gagal mengambil catatan: $e';
    }
  }

  // Update note
  Future<void> updateNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    try {
      final uid = _auth.currentUser!.uid;
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notes')
          .doc(noteId)
          .update({
            'title': title,
            'content': content,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw 'Gagal mengupdate catatan: $e';
    }
  }

  // Delete note
  Future<void> deleteNote(String noteId) async {
    try {
      final uid = _auth.currentUser!.uid;
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notes')
          .doc(noteId)
          .delete();
    } catch (e) {
      throw 'Gagal menghapus catatan: $e';
    }
  }

  // Handle Firebase Auth Exception
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
        return 'Pengguna tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah.';
      case 'user-disabled':
        return 'Akun pengguna telah dinonaktifkan.';
      default:
        return 'Error: ${e.message}';
    }
  }
}
