import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'services/firebase_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isShowingLogin = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseService().authStateChanges,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen(
            user: snapshot.data!,
            onLogout: () {
              setState(() {
                _isShowingLogin = true;
              });
            },
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
              // No need to do anything here, StreamBuilder will handle the state change
            },
          );
        }
      },
    );
  }
}
