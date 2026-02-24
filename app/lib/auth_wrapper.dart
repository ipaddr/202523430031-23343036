import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/register_success_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/confirming_identity_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isShowingLogin = true;
  bool _isShowingRegisterSuccess = false;
  bool _isConfirmingIdentity = false;
  User? _newlyRegisteredUser;
  User? _userToConfirm;

  @override
  Widget build(BuildContext context) {
    // Show register success screen if user just registered
    if (_isShowingRegisterSuccess && _newlyRegisteredUser != null) {
      return RegisterSuccessScreen(user: _newlyRegisteredUser!);
    }

    // Show confirming identity screen if needed
    if (_isConfirmingIdentity && _userToConfirm != null) {
      return ConfirmingIdentityScreen(
        user: _userToConfirm!,
        onIdentityConfirmed: () {
          setState(() {
            _isConfirmingIdentity = false;
          });
        },
        onFailed: () {
          setState(() {
            _isConfirmingIdentity = false;
            _isShowingLogin = true;
          });
        },
      );
    }

    return StreamBuilder<User?>(
      stream: AuthService().userStateChanges,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;

          // Check if email is verified
          if (!user.emailVerified) {
            return EmailVerificationScreen(
              user: user,
              onVerificationSuccess: () {
                // Trigger rebuild by notifying listeners
                setState(() {});
              },
              onLogout: () {
                setState(() {
                  _isShowingLogin = true;
                  _isShowingRegisterSuccess = false;
                });
              },
            );
          }

          // Email is verified, confirm identity before accessing main screen
          if (!_isConfirmingIdentity && _userToConfirm == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _isConfirmingIdentity = true;
                _userToConfirm = user;
              });
            });
          }

          // Show main screen only if identity is confirmed and not confirming
          if (!_isConfirmingIdentity && _userToConfirm != null) {
            return MainScreen(
              user: user,
              onLogout: () {
                setState(() {
                  _isShowingLogin = true;
                  _isShowingRegisterSuccess = false;
                  _isConfirmingIdentity = false;
                  _userToConfirm = null;
                });
              },
            );
          }

          // During confirmation process, return empty scaffold
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is not logged in - show login/register screens
        if (_isShowingLogin) {
          return LoginScreen(
            onSwitchToRegister: () {
              setState(() {
                _isShowingLogin = false;
              });
            },
            onLoginSuccess: () {
              // No need to do anything here, StreamBuilder will handle the state change
              setState(() {
                _isShowingRegisterSuccess = false;
              });
            },
          );
        } else {
          return RegisterScreen(
            onSwitchToLogin: () {
              setState(() {
                _isShowingLogin = true;
              });
            },
            onRegisterSuccess: () {
              // Get current user and show success screen
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                setState(() {
                  _isShowingRegisterSuccess = true;
                  _newlyRegisteredUser = currentUser;
                });
              }
            },
          );
        }
      },
    );
  }
}
