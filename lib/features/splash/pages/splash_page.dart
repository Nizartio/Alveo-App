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
    final targetRoute = user == null ? '/login' : '/home';

    if (user != null) {
      await NotificationService.instance.scheduleMedicationReminders();
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(targetRoute);
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
                top: -70,
                left: -60,
                child: _GlowBlob(
                  size: size.width * 0.62,
                  colors: const [AppColors.bubbleSky, AppColors.bubbleMint],
                ),
              ),
              Positioned(
                bottom: -120,
                left: size.width * 0.18,
                child: _GlowBlob(
                  size: size.width * 0.58,
                  colors: const [AppColors.bubbleBlue, AppColors.bubbleBlueAlt],
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    decoration: BoxDecoration(
                      color: AppColors.textLabel,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.black16,
                          blurRadius: 36,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 170,
                          height: 170,
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
                                'lib/assets/maskot-rmv.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
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
                        const SizedBox(height: 32),
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
                            child: const Text(
                              'Mulai Sekarang →',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
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
