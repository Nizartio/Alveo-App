import 'package:flutter/material.dart';

import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/register_page.dart';
import 'features/medication/pages/medication_plan_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlveoApp());
}

class AlveoApp extends StatelessWidget {
  const AlveoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF5B4BD8);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        scaffoldBackgroundColor: const Color(0xFFF5F7FF),
      ),
      home: const RegisterPage(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/medication': (_) => const MedicationPlanPage(),
      },
    );
  }
}
