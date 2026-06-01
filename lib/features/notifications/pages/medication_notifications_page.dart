import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../services/notification_service.dart';

class MedicationNotificationsPage extends StatefulWidget {
  const MedicationNotificationsPage({super.key});

  @override
  State<MedicationNotificationsPage> createState() =>
      _MedicationNotificationsPageState();
}

class _MedicationNotificationsPageState
    extends State<MedicationNotificationsPage> {
  final _notificationService = NotificationService.instance;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final daysAgo = switch (_selectedFilter) {
        'today' => 0,       // cutoff = today, only today's
        'yesterday' => 1,   // cutoff = yesterday, shows yesterday + today
        'week' => 7,        // last 7 days
        _ => null,          // all past
      };
      var notifications =
          await _notificationService.fetchNotifications(daysAgo: daysAgo);

      // For 'yesterday', also remove today's notifications
      if (_selectedFilter == 'yesterday') {
        final todayStr = DateTime.now().toIso8601String().split('T')[0];
        notifications = notifications
            .where((n) => (n['date']?.toString() ?? '') != todayStr)
            .toList();
      }

      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
      await _notificationService.refreshUnreadCount();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kesalahan memuat notifikasi: $e')),
      );
    }
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    final id = notification['id']?.toString();
    if (id == null || id.isEmpty) return;
    await _notificationService.markAsSent(id);
    await _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsSent();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua notifikasi ditandai sudah dibaca'),
          backgroundColor: Colors.green,
        ),
      );
    }
    await _loadNotifications();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      if (date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) {
        return 'Hari Ini';
      }
      if (date.year == yesterday.year &&
          date.month == yesterday.month &&
          date.day == yesterday.day) {
        return 'Kemarin';
      }
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(String? timeStr) {
    try {
      final parts = (timeStr ?? '').split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute).format(context);
    } catch (_) {
      return timeStr ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final n in _notifications) {
      final dateLabel = _formatDate(n['date']?.toString() ?? '');
      grouped.putIfAbsent(dateLabel, () => []).add(n);
    }

    final unreadCount =
        _notifications.where((n) => n['sent'] != true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: AppColors.loginShadow,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context),
              child: const Center(
                child: Icon(Icons.arrow_back, color: AppColors.primary),
              ),
            ),
          ),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Tandai Semua Dibaca',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Summary card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.bottomSheetShadow,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  unreadCount > 0
                      ? '$unreadCount notifikasi belum dibaca'
                      : 'Semua notifikasi sudah dibaca',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('all', 'Semua'),
                  const SizedBox(width: 8),
                  _filterChip('today', 'Hari Ini'),
                  const SizedBox(width: 8),
                  _filterChip('yesterday', 'Kemarin'),
                  const SizedBox(width: 8),
                  _filterChip('week', '7 Hari'),
                ],
              ),
            ),
          ),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: _notifications.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Container(
                                margin: const EdgeInsets.all(20),
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(Icons.notifications_off_rounded,
                                        size: 48,
                                        color: AppColors.textSecondary),
                                    SizedBox(height: 12),
                                    Text(
                                      'Belum ada notifikasi',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: grouped.keys.length,
                            itemBuilder: (context, index) {
                              final dateLabel =
                                  grouped.keys.elementAt(index);
                              final entries = grouped[dateLabel]!;
                              return _buildDateSection(dateLabel, entries);
                            },
                          ),
              ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        if (_selectedFilter == value) return;
        setState(() {
          _selectedFilter = value;
          _isLoading = true;
        });
        _loadNotifications();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.mutedDivider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSection(
    String dateLabel,
    List<Map<String, dynamic>> entries,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            dateLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A8A9F),
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...entries.map((n) => _buildNotificationTile(n)),
      ],
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    final isUnread = notification['sent'] != true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnread
              ? AppColors.primary.withOpacity(0.35)
              : Colors.transparent,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.bottomSheetShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _markAsRead(notification),
        borderRadius: BorderRadius.circular(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isUnread
                    ? AppColors.primary.withOpacity(0.12)
                    : AppColors.chipBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isUnread
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                color: isUnread ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['message']?.toString() ??
                              'Pengingat Obat',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification['time']?.toString()),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
