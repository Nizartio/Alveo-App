import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/dashboard_data.dart';
import '../models/reminder_event.dart';
import '../services/notification_service.dart';

class MedicationReminderBar extends StatefulWidget {
  const MedicationReminderBar({super.key});

  @override
  State<MedicationReminderBar> createState() => _MedicationReminderBarState();
}

class _MedicationReminderBarState extends State<MedicationReminderBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _opacityAnim;

  Timer? _dismissTimer;
  ReminderEvent? _currentEvent;
  bool _isMarking = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    NotificationService.instance.currentReminder.addListener(_onReminderChanged);
    _onReminderChanged();
  }

  @override
  void dispose() {
    NotificationService.instance.currentReminder.removeListener(_onReminderChanged);
    _animController.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _onReminderChanged() {
    final event = NotificationService.instance.currentReminder.value;
    if (event != null) {
      setState(() => _currentEvent = event);
      _animController.forward();
      _dismissTimer?.cancel();
      _dismissTimer = Timer(const Duration(seconds: 15), _dismiss);
    } else {
      _animController.reverse().then((_) {
        if (mounted) setState(() => _currentEvent = null);
      });
    }
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    NotificationService.instance.clearReminder();
  }

  Future<void> _markAsTaken() async {
    final event = _currentEvent;
    if (event == null || _isMarking) return;

    setState(() => _isMarking = true);

    try {
      final parts = event.scheduledTime.split(':');
      if (parts.length < 2) return;

      final scheduledTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );

      final now = DateTime.now();
      final schedDt = DateTime(
        now.year,
        now.month,
        now.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );
      final isLate = now.difference(schedDt) > const Duration(hours: 1);
      final status = isLate ? 'late_taken' : 'taken';

      await DashboardData.instance.medicationService.markMedicationAsTaken(
        userMedicationId: event.userMedicationId,
        scheduledTime: scheduledTime,
        status: status,
      );

      await DashboardData.instance.loadAll();
      if (mounted) _dismiss();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencatat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isMarking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentEvent == null && _animController.isDismissed) {
      return const SizedBox.shrink();
    }

    final event = _currentEvent;
    if (event == null) return const SizedBox.shrink();

    final isReminder = event.type == 'reminder';

    return Opacity(
      opacity: _opacityAnim.value,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < -200) {
              _dismiss();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: isReminder
                            ? const LinearGradient(
                                colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
                              )
                            : AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.medication,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            event.medicineName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.dosage,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isReminder
                                  ? const Color(0xFFFFF3E0)
                                  : AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isReminder
                                  ? 'Pengingat ${event.reminderMinutesBefore} menit'
                                  : 'Waktunya minum obat',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isReminder
                                    ? const Color(0xFFE67E22)
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _dismiss,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 72,
                          height: 32,
                          child: ElevatedButton(
                            onPressed: _isMarking ? null : _markAsTaken,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: _isMarking
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Minum',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
