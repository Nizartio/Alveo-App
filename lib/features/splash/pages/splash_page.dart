import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF6F3FF), Color(0xFFF9FBFF)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -70,
                left: -60,
                child: _GlowBlob(
                  size: size.width * 0.62,
                  colors: const [Color(0xFFB39DFF), Color(0xFF78F1D9)],
                ),
              ),
              Positioned(
                bottom: -120,
                left: size.width * 0.18,
                child: _GlowBlob(
                  size: size.width * 0.58,
                  colors: const [Color(0xFF8FB8FF), Color(0xFFD9EEFF)],
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
                      color: const Color(0xFFFDFDFF),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x16000000),
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
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFFFFFFF),
                                const Color(0xFFECE9FF).withValues(alpha: 0.9),
                              ],
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
                                color: const Color(0xFF6A57E6),
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Perjalananmu menuju pernapasan yang lebih baik dimulai di sini.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                height: 1.4,
                                color: const Color(0xFF6B7280),
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
                              backgroundColor: const Color(0xFF7B66FF),
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
                                color: Colors.white,
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
                              side: const BorderSide(color: Color(0xFFD6D9E6)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              backgroundColor: const Color(0xFFE3E6EF),
                            ),
                            child: const Text(
                              'Saya sudah memiliki akun',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2F3440),
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
