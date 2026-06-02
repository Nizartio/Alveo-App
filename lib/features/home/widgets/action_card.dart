import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class NextActionCard extends StatelessWidget {
  final String? medicineName;
  final String? scheduleTime;
  final String? intakeRuleLabel;
  final bool isLate;
  final bool isMarking;
  final VoidCallback? onMark;
  final VoidCallback? onNavigateToMeds;

  const NextActionCard({
    super.key,
    this.medicineName,
    this.scheduleTime,
    this.intakeRuleLabel,
    this.isLate = false,
    this.isMarking = false,
    this.onMark,
    this.onNavigateToMeds,
  });

  @override
  Widget build(BuildContext context) {
    final hasMedication = medicineName != null && scheduleTime != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: isLate ? Border.all(color: Colors.orange, width: 2) : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isLate
                    ? Colors.orange.withOpacity(0.15)
                    : AppColors.surfaceBlueTint,
                child: Icon(
                  isLate ? Icons.warning_amber_rounded : Icons.medication_outlined,
                  color: isLate ? Colors.orange : AppColors.brandBlueAlt,
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
                            hasMedication ? medicineName! : 'Belum ada jadwal',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isLate)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Terlambat',
                              style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasMedication
                          ? '$scheduleTime • ${intakeRuleLabel ?? 'Kapan Saja'}'
                          : 'Tidak ada obat yang dijadwalkan hari ini',
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
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: hasMedication ? onMark : onNavigateToMeds,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLate ? Colors.orange : AppColors.primaryDeep,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              child: isMarking
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          hasMedication ? 'Tandai Sudah Diminum' : 'Lihat Jadwal',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_outline, color: Colors.white),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
