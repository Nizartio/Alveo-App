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
import 'features/splash/pages/splash_page.dart';
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 72, 68, 102),
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBottom,
      ),
      home: const StartupGate(),
      routes: {
        '/splash': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const MainNavigationPage(),
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
    await NotificationService.instance.initialize();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await NotificationService.instance.scheduleMedicationReminders();
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
          return const _StartupSplashScreen();
        }

        if (snapshot.hasError) {
          return const _StartupErrorScreen(
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

class _StartupSplashScreen extends StatelessWidget {
  const _StartupSplashScreen();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.splashBackgroundGradient,
          ),
          child: Stack(
            children: [
              Positioned(
                top: -60,
                left: -60,
                child: Container(
                  width: size.width * 0.6,
                  height: size.width * 0.6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [AppColors.bubbleSky, AppColors.bubbleMint],
                    ),
                  ),
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 30,
                  ),
                  margin: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      225,
                      231,
                      240,
                    ).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.black16,
                        blurRadius: 36,
                        offset: Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 132,
                        height: 132,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [AppColors.white, AppColors.white90],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: ClipOval(
                            child: Image.asset(
                              'lib/assets/app_icon-rmv.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Memuat Alveo...',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Menyiapkan data akun dan notifikasi.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              height: 1.4,
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 22),
                      const SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
