import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class HistoryEntryTile extends StatelessWidget {
  final String medicineName;
  final String dosage;
  final String scheduledTimeText;
  final bool isTaken;

  const HistoryEntryTile({
    super.key,
    required this.medicineName,
    required this.dosage,
    required this.scheduledTimeText,
    required this.isTaken,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTaken
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.bottomSheetShadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTaken
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                isTaken ? Icons.check_circle : Icons.close_rounded,
                color: isTaken ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicineName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$dosage • $scheduledTimeText',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isTaken)
            const Text(
              'Taken',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            )
          else
            const Text(
              'Missed',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );
  }
}
