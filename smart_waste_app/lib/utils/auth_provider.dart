import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();

  User? _user;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _onboardingCompleted = false;

  User? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get onboardingCompleted => _onboardingCompleted;

  /// Safely converts Firestore data (`Map<String, Object?>`) to `Map<String, dynamic>`.
  Map<String, dynamic> _safeMap(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is List) {
      return {}; // Return empty map if it's a list (unexpected format)
    }

    try {
      // Firestore may return Map<String, Object?>
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
    } catch (e) {
      debugPrint('Error converting map: $e');
    }

    return {}; // Return empty map as fallback
  }

  /// Safely parses an int from a Firestore value (could be int or double)
  int _safeInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  // Firebase Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _firebaseAuthService.login(
        email: email,
        password: password,
      );

      _isLoading = false;

      if (result['success'] == true) {
        final userData = _safeMap(result['userData']);
        _user = User(
          id: (result['uid'] ?? userData['uid'] ?? '').toString(),
          name: userData['name']?.toString() ?? 'User',
          email: userData['email']?.toString() ?? email,
          phone: userData['phone']?.toString() ?? '',
          role: userData['role']?.toString() ?? 'user',
          points: _safeInt(userData['points']),
          wasteCollected: _safeInt(userData['wasteCollected']),
          profileImage: userData['profileImage']?.toString(),
        );
        _isLoggedIn = true;
        await NotificationService().initialize();
        notifyListeners();
        return {'success': true};
      }

      notifyListeners();
      return {'success': false, 'message': result['message'] ?? 'Login gagal'};
    } catch (e) {
      debugPrint('Login error: $e');
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // Firebase Register (basic)
  Future<bool> register(
    String name,
    String email,
    String phone,
    String password,
    String confirmPassword,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (password != confirmPassword) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _firebaseAuthService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: 'user',
      );

      _isLoading = false;

      if (result['success'] == true) {
        _user = User(
          id: (result['uid'] ?? '').toString(),
          name: name,
          email: email,
          phone: phone,
          role: 'user',
          points: 0,
          wasteCollected: 0,
        );
        _isLoggedIn = true;
        await NotificationService().initialize();
        notifyListeners();
        return true;
      }

      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Register error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Firebase Register with Email Verification
  Future<Map<String, dynamic>> registerWithEmailVerification(
    String name,
    String email,
    String phone,
    String password,
    String confirmPassword,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (password != confirmPassword) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'Password tidak cocok'};
      }

      final result = await _firebaseAuthService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: 'user',
      );

      _isLoading = false;

      if (result['success'] == true) {
        // Don't auto-login, wait for email verification
        notifyListeners();
        return {
          'success': true,
          'uid': result['uid'],
          'message': 'Verifikasi email telah dikirim',
        };
      }

      notifyListeners();
      return {
        'success': false,
        'message': result['message'] ?? 'Registrasi gagal',
      };
    } catch (e) {
      debugPrint('Register error: $e');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    debugPrint('=== Starting Google Sign-In ===');

    try {
      final result = await _firebaseAuthService.signInWithGoogle();

      _isLoading = false;

      if (result['success'] == true) {
        debugPrint('Google Sign-In successful');
        final userData = _safeMap(result['userData']);
        _user = User(
          id: (result['uid'] ?? userData['uid'] ?? '').toString(),
          name: userData['name']?.toString() ?? 'User',
          email: userData['email']?.toString() ?? '',
          phone: userData['phone']?.toString() ?? '',
          role: userData['role']?.toString() ?? 'user',
          points: _safeInt(userData['points']),
          wasteCollected: _safeInt(userData['wasteCollected']),
          profileImage: userData['profileImage']?.toString(),
        );
        _isLoggedIn = true;
        await NotificationService().initialize();
        notifyListeners();
        debugPrint('User object created: ${_user?.email}');
        return {
          'success': true,
          'requiresEmailVerification':
              result['requiresEmailVerification'] ?? false,
          'message': result['message'],
          'uid': result['uid'],
          'email': userData['email'],
        };
      }

      debugPrint('Google Sign-In failed: ${result['message']}');
      notifyListeners();
      return {
        'success': false,
        'message': result['message'] ?? 'Google sign-in gagal',
      };
    } catch (e) {
      debugPrint('Google sign-in exception: $e');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Firebase Logout
  Future<void> logout() async {
    await _firebaseAuthService.logout();
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  // Add Points
  Future<bool> addPoints(int points) async {
    if (_user == null) return false;

    try {
      final success = await _firebaseAuthService.addPoints(points);

      if (success) {
        _user = User(
          id: _user!.id,
          name: _user!.name,
          email: _user!.email,
          phone: _user!.phone,
          role: _user!.role,
          profileImage: _user!.profileImage,
          points: _user!.points + points,
          wasteCollected: _user!.wasteCollected,
        );
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error adding points: $e');
      return false;
    }
  }

  // Update User Data
  Future<bool> updateUserData(Map<String, dynamic> data) async {
    if (_user == null) return false;

    try {
      final success = await _firebaseAuthService.updateUserData(data);

      if (success) {
        _user = User(
          id: _user!.id,
          name: data['name']?.toString() ?? _user!.name,
          email: _user!.email,
          phone: data['phone']?.toString() ?? _user!.phone,
          role: _user!.role,
          profileImage: data['profileImage']?.toString() ?? _user!.profileImage,
          points: _user!.points,
          wasteCollected: _user!.wasteCollected,
        );
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error updating user data: $e');
      return false;
    }
  }

  // Reset Password
  // Request password reset code
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      final result = await _firebaseAuthService.resetPassword(email: email);
      return result;
    } catch (e) {
      debugPrint('Error resetting password: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Verify password reset code
  Future<Map<String, dynamic>> verifyPasswordResetCode(
    String email,
    String code,
  ) async {
    try {
      final result = await _firebaseAuthService.verifyPasswordResetCode(
        email: email,
        code: code,
      );
      return result;
    } catch (e) {
      debugPrint('Error verifying reset code: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Reset password with code
  Future<Map<String, dynamic>> resetPasswordWithCode(
    String email,
    String newPassword,
  ) async {
    try {
      final result = await _firebaseAuthService.resetPasswordWithCode(
        email: email,
        newPassword: newPassword,
      );
      return result;
    } catch (e) {
      debugPrint('Error resetting password: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Check & restore auth state (used in SplashScreen)
  Future<bool> checkAuthStatus() async {
    try {
      final currentUser = _firebaseAuthService.currentUser;

      if (currentUser == null) {
        _isLoggedIn = false;
        notifyListeners();
        return false;
      }

      final rawData = await _firebaseAuthService.getCurrentUserData();

      if (rawData != null) {
        final userData = _safeMap(rawData);
        _user = User(
          id: currentUser.uid,
          name: userData['name']?.toString() ?? 'User',
          email: userData['email']?.toString() ?? currentUser.email ?? '',
          phone: userData['phone']?.toString() ?? '',
          role: userData['role']?.toString() ?? 'user',
          points: _safeInt(userData['points']),
          wasteCollected: _safeInt(userData['wasteCollected']),
          profileImage: userData['profileImage']?.toString(),
        );
        _isLoggedIn = true;
        await NotificationService().initialize();
        notifyListeners();
        return true;
      }

      _isLoggedIn = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      _isLoggedIn = false;
      notifyListeners();
      return false;
    }
  }

  // Check if onboarding has been completed
  Future<bool> checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      notifyListeners();
      return _onboardingCompleted;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      _onboardingCompleted = false;
      notifyListeners();
      return false;
    }
  }

  // Mark onboarding as completed
  Future<void> setOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      _onboardingCompleted = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting onboarding completed: $e');
    }
  }
}
