import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class HistoryEntryActions extends StatelessWidget {
  final Map<String, dynamic> entry;
  final String Function(Map<String, dynamic>) getMedicationName;
  final String Function(Map<String, dynamic>) getMedicationSubtitle;
  final String Function(String) formatTime;
  final String Function(String?) statusLabel;
  final Color Function(String?) statusColor;
  final IconData Function(String?) statusIcon;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  const HistoryEntryActions({
    super.key,
    required this.entry,
    required this.getMedicationName,
    required this.getMedicationSubtitle,
    required this.formatTime,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = entry['status']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor(status).withAlpha(77)),
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
              color: statusColor(status).withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                statusIcon(status),
                color: statusColor(status),
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
                  getMedicationName(entry),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${getMedicationSubtitle(entry)} • ${formatTime(entry['scheduled_time']?.toString() ?? '')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel(status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor(status),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit(entry);
              } else if (value == 'delete') {
                onDelete(entry);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Sunting'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
