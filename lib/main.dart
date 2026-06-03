import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_colors.dart';
import 'core/navigation/app_navigator.dart';
import 'core/supabase_config.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/register_page.dart';
import 'features/notifications/pages/medication_notifications_page.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/profile/pages/profile_page.dart';
import 'main_navigation_page.dart';
import 'features/medication/pages/meds_page.dart';
import 'features/medication/pages/medication_plan_page.dart';
import 'features/splash/pages/splash_page.dart'; // Tetap mempertahankan import ini
import 'features/stats/stats_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const StartupGate(),
      routes: {
        '/splash': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final initialIndex =
              args is Map<String, dynamic> ? (args['initialIndex'] as int?) ?? 0 : 0;
          return MainNavigationPage(initialIndex: initialIndex);
        },
        '/profile': (_) => const ProfilePage(),
        '/medication_plan': (_) => const MedicationPlanPage(),
        '/medication': (_) => const MedsPage(),
        '/notifications': (_) => const MedicationNotificationsPage(),
        '/stats': (_) => const StatsPage(),
      },
    );
  }
}

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late final Future<bool> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrapApp();
  }

  Future<bool> _bootstrapApp() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

    try {
      await NotificationService.instance.initialize();
    } catch (e) {
      print('[Bootstrap] Notification init failed: $e');
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await NotificationService.instance.scheduleMedicationReminders();
      } catch (e) {
        print('[Bootstrap] Schedule reminders failed: $e');
      }
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Menggunakan nama Class baru tanpa underscore dari splash_page.dart
          return const StartupSplashScreen();
        }

        if (snapshot.hasError) {
          // Menggunakan nama Class baru tanpa underscore dari splash_page.dart
          return const StartupErrorScreen(
            message: 'Aplikasi gagal dimulai. Coba tutup dan buka lagi.',
          );
        }

        final isLoggedIn = snapshot.data ?? false;
        if (isLoggedIn) {
          return const MainNavigationPage();
        }

        return const SplashPage();
      },
    );
  }
}
