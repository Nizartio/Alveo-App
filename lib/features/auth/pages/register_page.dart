import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.appBackgroundGradient,
          ),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                left: -24,
                child: _SoftBlob(
                  size: size.width * 0.4,
                  colors: const [
                    AppColors.bubbleMuted,
                    AppColors.bubbleMutedAlt,
                  ],
                ),
              ),
              Positioned(
                bottom: -40,
                right: -40,
                child: _SoftBlob(
                  size: size.width * 0.40,
                  colors: const [AppColors.bubbleCool, AppColors.bubbleCoolAlt],
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height - 100),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const _MascotCircle(),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 36,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.black12,
                              blurRadius: 28,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Mari kita jaga kesehatan paru-paru kita bersama-sama',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontSize: 24,
                                      height: 1.25,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.seed,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Buat akun Alveo Anda untuk memulai.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      height: 1.25,
                                      color: AppColors.textBody,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              const _FieldLabel(text: 'Nama Lengkap'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _fullNameController,
                                hintText: 'Alveo Leo',
                                icon: Icons.person_outline_rounded,
                                textCapitalization: TextCapitalization.words,
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'Nama lengkap wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              const _FieldLabel(text: 'Email'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _emailController,
                                hintText: 'your@email.com',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  final text = (value ?? '').trim();
                                  if (text.isEmpty) {
                                    return 'Email wajib diisi';
                                  }
                                  if (!text.contains('@')) {
                                    return 'Email tidak valid';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              const _FieldLabel(text: 'Kata Sandi'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _passwordController,
                                hintText: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                obscureText: true,
                                validator: (value) {
                                  if ((value ?? '').isEmpty) {
                                    return 'Kata sandi wajib diisi';
                                  }
                                  if ((value ?? '').length < 6) {
                                    return 'Minimal 6 karakter';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 56,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    gradient: AppColors.primaryGradient,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppColors.loginShadow,
                                        blurRadius: 24,
                                        offset: Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(28),
                                      onTap: () async {
                                        if (!(_formKey.currentState
                                                ?.validate() ??
                                            false)) {
                                          return;
                                        }

                                        if (!mounted) return;
                                        setState(() {});
                                        final name = _fullNameController.text
                                            .trim();
                                        final email = _emailController.text
                                            .trim();
                                        final password =
                                            _passwordController.text;

                                        try {
                                          final res = await Supabase
                                              .instance
                                              .client
                                              .auth
                                              .signUp(
                                                email: email,
                                                password: password,
                                                data: {'full_name': name},
                                              );

                                          if (!mounted) return;

                                          // signUp can succeed even when email confirmation is required.
                                          // In that case, session is null and the user should log in after confirming.
                                          final session = res.session;
                                          final user = res.user;

                                          if (session != null && user != null) {
                                            Navigator.of(
                                              context,
                                            ).pushReplacementNamed(
                                              '/medication_plan',
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Akun berhasil dibuat. Silakan lanjut isi basic requirement di medication.',
                                                ),
                                              ),
                                            );
                                            Navigator.of(
                                              context,
                                            ).pushReplacementNamed('/login');
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Buat Akun',
                                              style: TextStyle(
                                                color: AppColors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
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
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Sudah memiliki akun? ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(
                                        context,
                                      ).pushReplacementNamed('/login');
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: AppColors.seed,
                                    ),
                                    child: const Text(
                                      'Masuk',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textLabel,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textNavy,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surfaceSoft,
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.textMutedSoft,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(icon, color: AppColors.iconMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primaryLight,
            width: 1.25,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.25),
        ),
      ),
    );
  }
}

class _MascotCircle extends StatelessWidget {
  const _MascotCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        boxShadow: const [
          BoxShadow(
            color: AppColors.softShadow,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          // gradient: AppColors.mascotInnerGradient,
        ),
        child: Center(
          child: ClipOval(
            child: Image.asset(
              'lib/assets/app_icon.png',
              fit: BoxFit.cover,
              width: 120,
              height: 120,
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({required this.size, required this.colors});

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
