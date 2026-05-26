import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HeaderContent extends StatefulWidget {
  const HeaderContent({super.key});

  @override
  State<HeaderContent> createState() => _HeaderContentState();
}

class _HeaderContentState extends State<HeaderContent> {
  final _supabase = Supabase.instance.client;
  String _greetingName = 'there';

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

      final fullName =
          (profile?['full_name'] ??
                  user.userMetadata?['full_name'] ??
                  user.email)
              ?.toString();

      if (!mounted) return;

      setState(() {
        if (fullName == null || fullName.trim().isEmpty) {
          _greetingName = 'there';
        } else {
          _greetingName = fullName.trim().split(RegExp(r'\s+')).first;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _greetingName = 'there';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hai, $_greetingName 👋',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 20),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 140, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Text(
                'Kamu hebat hari ini! Tarik napas dalam-dalam dan teruslah berusaha.',
                style: TextStyle(
                  color: Color(0xFF6B6B6B),
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Positioned(
              top: -35,
              right: 18,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE6E6E6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
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
