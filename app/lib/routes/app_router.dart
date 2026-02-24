import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes/app_routes.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/email_verification_screen.dart';
import '../screens/main_screen.dart';
import '../screens/add_note_screen.dart';
import '../services/navigation_service.dart';

/// App Router untuk manage semua routes
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => LoginScreen(
            onSwitchToRegister: () {
              NavigationService().pushReplacementNamed(AppRoutes.register);
            },
            onLoginSuccess: () {
              // Auto handled by AuthWrapper
            },
          ),
          settings: settings,
        );

      case AppRoutes.register:
        return MaterialPageRoute(
          builder: (_) => RegisterScreen(
            onSwitchToLogin: () {
              NavigationService().pushReplacementNamed(AppRoutes.login);
            },
            onRegisterSuccess: () {
              // Auto handled by AuthWrapper
            },
          ),
          settings: settings,
        );

      case AppRoutes.emailVerification:
        final user = settings.arguments as User;
        return MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            user: user,
            onVerificationSuccess: () {
              NavigationService().pushReplacementNamed(AppRoutes.mainScreen);
            },
            onLogout: () {
              NavigationService().pushReplacementNamed(AppRoutes.login);
            },
          ),
          settings: settings,
        );

      case AppRoutes.mainScreen:
        final user = settings.arguments as User;
        return MaterialPageRoute(
          builder: (_) => MainScreen(
            user: user,
            onLogout: () {
              NavigationService().pushReplacementNamed(AppRoutes.login);
            },
          ),
          settings: settings,
        );

      case AppRoutes.addNote:
        final args = settings.arguments as Map<String, dynamic>?;
        final user = args?['user'] as User?;
        if (user == null) {
          return _errorRoute('User not provided');
        }
        return MaterialPageRoute(
          builder: (_) => AddNoteScreen(
            user: user,
            noteId: args?['noteId'] as String?,
            initialTitle: args?['title'] as String? ?? '',
            initialContent: args?['content'] as String? ?? '',
          ),
          settings: settings,
        );

      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(message)),
      ),
    );
  }
}
