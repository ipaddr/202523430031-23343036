import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_initialization.dart';
import 'auth_wrapper.dart';
import 'bloc/auth_bloc.dart';
import 'services/navigation_service.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppInitialization.initialize();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(),
      child: MaterialApp(
        title: 'Aplikasi Saya',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        navigatorKey: navigatorKey,
        onGenerateRoute: AppRouter.generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
