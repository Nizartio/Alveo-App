import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_colors.dart';
import 'core/supabase_config.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/register_page.dart';
import 'main_navigation_page.dart';
import 'features/medication/pages/medication_plan_page.dart';
import 'features/splash/pages/splash_page.dart';
import 'features/stats/stats_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const AlveoApp());
}

class AlveoApp extends StatelessWidget {
  const AlveoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 72, 68, 102),
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBottom,
      ),
      home: const MainNavigationPage(),
      routes: {
        '/splash': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const MainNavigationPage(),
        '/medication': (_) => const MedicationPlanPage(),
        '/stats': (_) => const StatsPage(),
      },
    );
  }
}
