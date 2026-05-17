import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_colors.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/register_page.dart';
import 'features/home/home_page.dart';
import 'features/medication/pages/medication_plan_page.dart';
import 'features/splash/pages/splash_page.dart';
import 'features/stats/stats_page.dart';

const String supabaseUrl = 'https://yklgtddjazemzmxiunsq.supabase.co';
const String supabaseAnonKey = 'sb_publishable_2C9GSA4i0vdN7O_R4dXSTQ_BXt4Xn8e';

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
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.seed),
        scaffoldBackgroundColor: AppColors.scaffoldBottom,
      ),
      home: const SplashPage(),
      routes: {
        '/splash': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const HomePage(),
        '/medication': (_) => const MedicationPlanPage(),
        '/stats': (_) => const StatsPage(),
      },
    );
  }
}
