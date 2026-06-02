import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../medication/services/medication_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _medicationService = MedicationService();

  String _displayName = 'Profile';
  String _email = '-';
  String? _avatarUrl;
  bool _isLoading = true;
  bool _isSaving = false;

  // Stats
  int _level = 1;
  int _currentXp = 0;
  int _nextThreshold = 0;
  int _prevThreshold = 0;
  int _streak = 0;
  int _longestStreak = 0;
  int _totalMeds = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      return;
    }

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
      final email = user.email?.toString();
      final avatarUrl =
          user.userMetadata?['avatar_url']?.toString() ??
          user.userMetadata?['picture']?.toString();
      final username =
          (profile?['full_name'] ?? user.userMetadata?['full_name'])
              ?.toString();

      // Fetch level progress and stats
      final levelProgress = await _medicationService.fetchLevelProgress();
      final userStats = await _supabase
          .from('user_profile')
          .select('current_streak, longest_streak, total_meds_taken')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _displayName = (fullName == null || fullName.trim().isEmpty)
            ? 'Profile'
            : fullName.trim();
        _email = (email == null || email.trim().isEmpty) ? '-' : email.trim();
        _avatarUrl = avatarUrl != null && avatarUrl.trim().isNotEmpty
            ? avatarUrl.trim()
            : null;
        _usernameController.text = (username == null || username.trim().isEmpty)
            ? ''
            : username.trim();
        _emailController.text = (email == null || email.trim().isEmpty)
            ? ''
            : email.trim();
        _passwordController.clear();
        _level = (levelProgress['level'] as int?) ?? 1;
        _currentXp = (levelProgress['remainingXp'] as int?) ?? 0;
        _nextThreshold = (levelProgress['nextThreshold'] as int?) ?? 0;
        _prevThreshold = (levelProgress['currentThreshold'] as int?) ?? 0;
        _streak = (userStats?['current_streak'] as int?) ?? 0;
        _longestStreak = (userStats?['longest_streak'] as int?) ?? 0;
        _totalMeds = (userStats?['total_meds_taken'] as int?) ?? 0;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final newName = _usernameController.text.trim();
      final newEmail = _emailController.text.trim();
      final newPassword = _passwordController.text;

      // Update full_name in user_profile
      if (newName.isNotEmpty && newName != _displayName) {
        await _supabase
            .from('user_profile')
            .upsert({
              'user_id': user.id,
              'full_name': newName,
              'updated_at': DateTime.now().toIso8601String(),
            });
      }

      // Update email if changed (Supabase sends confirmation to new email)
      if (newEmail.isNotEmpty && newEmail != _email) {
        await _supabase.auth.updateUser(UserAttributes(email: newEmail));
      }

      // Update password if provided
      if (newPassword.isNotEmpty) {
        if (newPassword.length < 6) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kata sandi minimal 6 karakter'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isSaving = false);
          return;
        }
        await _supabase.auth.updateUser(UserAttributes(password: newPassword));
        _passwordController.clear();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadProfile();
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: ${e.message}'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kesalahan: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String get _initials {
    final parts = _displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return String.fromCharCode(parts.first.runes.first).toUpperCase();
    }

    final first = String.fromCharCode(parts.first.runes.first);
    final last = String.fromCharCode(parts.last.runes.first);
    return '$first$last'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBottom,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.black04,
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: _avatarUrl != null
                                ? Image.network(
                                    _avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _ProfileFallback(
                                        initials: _initials,
                                      );
                                    },
                                  )
                                : _ProfileFallback(initials: _initials),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _displayName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textHeading,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stats card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.streakGradient,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        // Level badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Level $_level',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // XP progress bar
                        if (_nextThreshold > 0) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (_nextThreshold - _prevThreshold) > 0
                                  ? _currentXp / (_nextThreshold - _prevThreshold)
                                  : 0,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              color: Colors.white,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_currentXp / ${_nextThreshold - _prevThreshold} XP',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Streak + stats row
                        Row(
                          children: [
                            _statItem(Icons.local_fire_department, '$_streak', 'Streak'),
                            _statItem(Icons.emoji_events, '$_longestStreak', 'Terbaik'),
                            _statItem(Icons.medication, '$_totalMeds', 'Total'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.mutedDivider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Data Akun',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHeading,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ProfileInputField(
                          label: 'Nama Pengguna',
                          hintText: 'Masukkan nama pengguna',
                          controller: _usernameController,
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 14),
                        _ProfileInputField(
                          label: 'Email',
                          hintText: 'Masukkan email Anda',
                          controller: _emailController,
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        _ProfileInputField(
                          label: 'Kata Sandi',
                          hintText: 'Masukkan kata sandi baru',
                          controller: _passwordController,
                          icon: Icons.lock_outline_rounded,
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Kata sandi tidak ditampilkan. Isi hanya jika ingin mengganti.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(28),
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
                          onTap: _isSaving ? null : _saveProfile,
                          child: Center(
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Simpan Perubahan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Keluar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE25555),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProfileFallback extends StatelessWidget {
  final String initials;

  const _ProfileFallback({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceTint,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.primaryDeep,
          fontWeight: FontWeight.w800,
          fontSize: 26,
        ),
      ),
    );
  }
}

class _ProfileInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _ProfileInputField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: AppColors.scaffoldBottom,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: AppColors.mutedDivider.withOpacity(0.8),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
