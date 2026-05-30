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
                  value: 'logout',
                  child: Row(
                    children: const [
                      Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: Color(0xFFE25555),
                      ),
                      SizedBox(width: 10),
                      Text('Logout'),
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
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: ClipPath(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Image.asset(
                          'lib/assets/profile.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
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
