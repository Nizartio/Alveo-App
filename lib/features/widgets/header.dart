import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../notifications/services/notification_service.dart';

class StatsHeader extends StatefulWidget {
  const StatsHeader({super.key});

  @override
  State<StatsHeader> createState() => _StatsHeaderState();
}

class _StatsHeaderState extends State<StatsHeader> {
  final _notificationService = NotificationService.instance;

  User? get _user => Supabase.instance.client.auth.currentUser;

  String? get _displayName {
    final user = _user;
    if (user == null) return null;

    final metadataName = user.userMetadata?['full_name']?.toString();
    if (metadataName != null && metadataName.trim().isNotEmpty) {
      return metadataName.trim();
    }

    final email = user.email?.toString();
    if (email != null && email.trim().isNotEmpty) {
      return email.trim();
    }

    return null;
  }

  String? get _avatarUrl {
    final user = _user;
    if (user == null) return null;

    final metadataAvatar = user.userMetadata?['avatar_url']?.toString();
    if (metadataAvatar != null && metadataAvatar.trim().isNotEmpty) {
      return metadataAvatar.trim();
    }

    final photoUrl = user.userMetadata?['picture']?.toString();
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      return photoUrl.trim();
    }

    return null;
  }

  String get _avatarInitials {
    final name = _displayName;
    if (name == null || name.trim().isEmpty) {
      return 'U';
    }

    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return _firstLetter(parts.first);
    }

    return '${_firstLetter(parts.first)}${_firstLetter(parts.last)}';
  }

  String _firstLetter(String value) {
    if (value.isEmpty) return 'U';
    return String.fromCharCode(value.runes.first).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _refreshBadge();
  }

  Future<void> _refreshBadge() async {
    await _notificationService.refreshUnreadCount();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).pushNamed('/profile');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            PopupMenuButton<String>(
              tooltip: 'Profile',
              onSelected: (value) {
                if (value == 'profile') {
                  _openProfile(context);
                  return;
                }

                if (value == 'logout') {
                  _logout(context);
                }
              },
              offset: const Offset(0, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'profile',
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                        color: Color(0xFF6B5CE7),
                      ),
                      SizedBox(width: 8),
                      Text('Profile'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'logout',
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: Color(0xFFE25555),
                      ),
                      SizedBox(width: 8),
                      Text('Keluar'),
                    ],
                  ),
                ),
              ],
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textPrimary.withOpacity(0.2),
                        width: 1,
                      ),
                      color: AppColors.white,
                    ),
                    child: ClipOval(
                      child: _avatarUrl != null
                          ? Image.network(
                              _avatarUrl!,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _AvatarFallback(
                                  initials: _avatarInitials,
                                );
                              },
                            )
                          : _AvatarFallback(initials: _avatarInitials),
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            const Text(
              'Alveo',
              style: TextStyle(
                color: Color(0xFF6B5CE7),
                fontWeight: FontWeight.w800,
                fontSize: 30,
              ),
            ),

            const Spacer(),

            GestureDetector(
              onTap: () {},
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: _notificationService.unreadCount,
                      builder: (context, unreadCount, _) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFF6B5CE7),
                              size: 30,
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF6B6B),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadCount > 9 ? '9+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initials;

  const _AvatarFallback({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceTint,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.primaryDeep,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
