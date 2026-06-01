import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HeaderContent extends StatefulWidget {
  final int streakDays;
  const HeaderContent({super.key, this.streakDays = 0});

  @override
  State<HeaderContent> createState() => _HeaderContentState();
}

class _HeaderContentState extends State<HeaderContent> {
  final _supabase = Supabase.instance.client;
  String _greetingName = '';

  @override
  void initState() {
    super.initState();
    _loadGreetingName();
  }

  Future<void> _loadGreetingName() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await _supabase
          .from('user_profile')
          .select('full_name')
          .eq('user_id', user.id)
          .maybeSingle();

      final fullName = (profile?['full_name'] ??
              user.userMetadata?['full_name'] ??
              user.email)
          ?.toString();

      if (!mounted) return;

      setState(() {
        if (fullName != null && fullName.trim().isNotEmpty) {
          _greetingName = fullName.trim().split(RegExp(r'\s+')).first;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _greetingName = '');
    }
  }

  String _motivationalMessage() {
    if (widget.streakDays >= 7) {
      return 'Keren! ${widget.streakDays} hari berturut-turut minum obat. Terus pertahankan! 🔥';
    }
    if (widget.streakDays >= 3) {
      return 'Kamu sudah ${widget.streakDays} hari streak. Semangat terus! 💪';
    }
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Semangat pagi! Jangan lupa minum obat hari ini. ☀️';
    if (hour < 15) return 'Jangan lupa jadwal obat siang ini. Tetap sehat! 🌤️';
    if (hour < 19) return 'Sore yang tenang. Sudah minum obat belum? 🌅';
    return 'Jangan lupa minum obat sebelum tidur. Istirahat yang cukup! 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _greetingName.isNotEmpty ? 'Hai, $_greetingName 👋' : 'Hai 👋';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 12),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 152, 24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black03,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                _motivationalMessage(),
                style: const TextStyle(
                  color: AppColors.textBody,
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Positioned(
              top: -35,
              right: 18,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color.fromARGB(255, 241, 236, 236),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black12,
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(
                    'lib/assets/alveo-1.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
