import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class NextActionCard extends StatelessWidget {
  final String? medicineName;
  final String? scheduleTime;
  final String? intakeRuleLabel;
  final VoidCallback? onTap;

  const NextActionCard({
    super.key,
    this.medicineName,
    this.scheduleTime,
    this.intakeRuleLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceBlueTint,
                child: Transform.rotate(
                  angle: -0.5,
                  child: const Icon(
                    Icons.medication_outlined,
                    color: AppColors.brandBlueAlt,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicineName ?? 'Belum ada jadwal obat',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      scheduleTime == null
                          ? 'Tidak ada obat yang dijadwalkan hari ini'
                          : '🕛 $scheduleTime • ${intakeRuleLabel ?? 'Kapan Saja'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDeep,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  scheduleTime == null
                      ? 'Lihat Jadwal'
                      : 'Tandai Sudah Diminum',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),

                SizedBox(width: 8),

                Icon(Icons.check_circle_outline, color: AppColors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
