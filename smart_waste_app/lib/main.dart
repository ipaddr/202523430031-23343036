import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'utils/auth_provider.dart';
import 'utils/theme_provider.dart';
import 'services/camera_provider.dart';
import 'services/notification_service.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/email_verification_code_screen.dart';
import 'screens/user/home_screen.dart';
import 'screens/petugas/petugas_home_screen_new.dart';
import 'screens/petugas/petugas_task_list_screen.dart';
import 'screens/petugas/petugas_task_detail_screen.dart';
import 'screens/petugas/petugas_navigation_screen.dart';
import 'screens/petugas/petugas_arrival_screen.dart';
import 'screens/petugas/petugas_pickup_process_screen.dart';
import 'screens/petugas/petugas_input_hasil_screen.dart';
import 'screens/petugas/petugas_history_screen.dart';
import 'screens/petugas/petugas_statistics_screen.dart';
import 'screens/petugas/petugas_notification_screen.dart';
import 'screens/petugas/petugas_profile_screen.dart';
import 'screens/admin/admin_home_screen_new.dart';
import 'screens/admin/admin_request_detail_screen_new.dart' as detail_new;
import 'screens/admin/admin_request_list_screen_new.dart';
import 'screens/admin/admin_schedule_screen.dart';
import 'screens/admin/admin_reports_screen.dart';
import 'screens/admin/admin_activity_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_officers_management_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Smart Waste',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const SplashScreen(),
            onGenerateRoute: _generateRoute,
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/forgot_password': (context) => const ForgotPasswordScreen(),
              '/user_home': (context) => const UserHomeScreen(),
              '/petugas_home': (context) => const PetugasHomeScreenNew(),
              '/task_list': (context) => const PetugasTaskListScreen(),
              '/pickup_process': (context) =>
                  const PetugasPickupProcessScreen(),
              '/task_history': (context) => const PetugasHistoryScreen(),
              '/statistics': (context) => const PetugasStatisticsScreen(),
              '/notifications': (context) => const PetugasNotificationScreen(),
              '/profile': (context) => const PetugasProfileScreen(),
              '/admin_home': (context) => const AdminHomeScreenNew(),
              '/request_detail': (context) =>
                  detail_new.AdminRequestDetailScreen(),
              '/admin_requests': (context) => const AdminRequestListScreen(),
              '/admin_users': (context) => const AdminUsersScreen(),
              '/admin_officers': (context) =>
                  const AdminOfficersManagementScreen(),
              '/admin_schedule': (context) => const AdminScheduleScreen(),
              '/admin_reports': (context) => const AdminReportsScreen(),
              '/admin_activity': (context) => const AdminActivityScreen(),
            },
          );
        },
      ),
    );
  }

  static Route<dynamic> _generateRoute(RouteSettings settings) {
    if (settings.name == '/arrival') {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) =>
            PetugasArrivalScreen(taskId: args?['taskId'] ?? ''),
      );
    }

    if (settings.name == '/input_hasil') {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) =>
            PetugasInputHasilScreen(taskId: args?['taskId'] ?? ''),
      );
    }

    if (settings.name == '/email_verification') {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => EmailVerificationCodeScreen(
          email: args?['email'] ?? '',
          uid: args?['uid'] ?? '',
        ),
      );
    }

    if (settings.name == '/email_verification_code') {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => EmailVerificationCodeScreen(
          email: args?['email'] ?? '',
          uid: args?['uid'] ?? '',
        ),
      );
    }

    if (settings.name == '/navigation') {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => PetugasNavigationScreen(
          lat: args?['lat'],
          lng: args?['lng'],
          address: args?['address'],
          type: args?['type'],
        ),
      );
    }

    if (settings.name == '/task_detail') {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => PetugasTaskDetailScreen(task: args),
      );
    }
    return MaterialPageRoute(builder: (context) => const SplashScreen());
  }
}
