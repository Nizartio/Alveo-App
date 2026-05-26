import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'history_entry_tile.dart';

class HistoryDateSection extends StatelessWidget {
  final String dateFormatted;
  final bool allTaken;
  final List<Map<String, dynamic>> entries;
  final String Function(String) formatTime;

  const HistoryDateSection({
    super.key,
    required this.dateFormatted,
    required this.allTaken,
    required this.entries,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Row(
            children: [
              Text(
                dateFormatted,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 12),
              if (allTaken)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Text(
                    'Perfect Day! 🌟',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ...entries.map((entry) {
          final isTaken = entry['status'] == 'taken';
          return HistoryEntryTile(
            medicineName: entry['medicine_name'] ?? 'Medicine',
            dosage: entry['dosage'] ?? '0',
            scheduledTimeText: formatTime(entry['scheduled_time']),
            isTaken: isTaken,
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  }
}
