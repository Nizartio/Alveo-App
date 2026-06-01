import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_colors.dart';
import 'core/navigation/app_navigator.dart';
import 'core/supabase_config.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/register_page.dart';
import 'features/notifications/pages/medication_notifications_page.dart';
import 'features/notifications/services/notification_service.dart';
import 'main_navigation_page.dart';
import 'features/medication/pages/meds_page.dart';
import 'features/medication/pages/medication_plan_page.dart';
import 'features/splash/pages/splash_page.dart';
import 'features/stats/stats_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  await NotificationService.instance.initialize();
  runApp(const AlveoApp());
}

class AlveoApp extends StatelessWidget {
  const AlveoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: AppColors.scaffoldBottom,
      ),
      home: const AuthGate(),
      routes: {
        '/splash': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const MainNavigationPage(),
        '/medication_plan': (_) => const MedicationPlanPage(),
        '/medication': (_) => const MedsPage(),
        '/notifications': (_) => const MedicationNotificationsPage(),
        '/stats': (_) => const StatsPage(),
      },
    );
  }
}
