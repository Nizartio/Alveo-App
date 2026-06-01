import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../notifications/services/notification_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _supabase = Supabase.instance.client;
  bool _hasCheckedAuth = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveAuthState();
    });
  }

  Future<void> _resolveAuthState() async {
    if (_hasCheckedAuth || !mounted) return;
    _hasCheckedAuth = true;

    final user = _supabase.auth.currentUser;

    if (user != null) {
      await NotificationService.instance.scheduleMedicationReminders();

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

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
                child: _GlowBlob(
                  size: size.width * 0.6,
                  colors: const [AppColors.bubbleSky, AppColors.bubbleMint],
                ),
              ),
              Positioned(
                bottom: -120,
                left: size.width * 0.2,
                child: _GlowBlob(
                  size: size.width * 0.6,
                  colors: const [AppColors.bubbleBlue, AppColors.bubbleBlueAlt],
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(36),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 225, 231, 240).withOpacity(0.8),
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
                        const SizedBox(height: 12),
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [AppColors.white, AppColors.white90],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: ClipOval(
                              child: Image.asset(
                                'lib/assets/app_icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Selamat Datang di Alveo',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Perjalananmu menuju pernapasan yang lebih baik dimulai di sini.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                height: 1.4,
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed('/register');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Mulai Sekarang',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_circle_right_outlined,
                                  color: AppColors.white,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed('/login');
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.textMutedSoft),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              backgroundColor: AppColors.surfaceMutedAlt,
                            ),
                            child: const Text(
                              'Saya sudah memiliki akun',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textNavy,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
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

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      await NotificationService.instance.scheduleMedicationReminders();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/splash');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}