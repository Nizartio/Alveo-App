import 'package:flutter/material.dart';
import 'entry_actions.dart';

class HistoryDateSection extends StatelessWidget {
  final String dateFormatted;
  final List<Map<String, dynamic>> entries;
  final bool allTaken;
  final String Function(Map<String, dynamic>) getMedicationName;
  final String Function(Map<String, dynamic>) getMedicationSubtitle;
  final String Function(String) formatTime;
  final String Function(String?) statusLabel;
  final Color Function(String?) statusColor;
  final IconData Function(String?) statusIcon;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;
  final void Function(Map<String, dynamic>)? onStatusToggle;

  const HistoryDateSection({
    super.key,
    required this.dateFormatted,
    required this.entries,
    required this.allTaken,
    required this.getMedicationName,
    required this.getMedicationSubtitle,
    required this.formatTime,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    required this.onEdit,
    required this.onDelete,
    this.onStatusToggle,
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
                  color: Color(0xFF8A8A9F),
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
                    color: Colors.green.withAlpha(25),
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
        ...entries.map(
          (entry) => HistoryEntryActions(
            key: ValueKey(entry['id']?.toString() ?? entry.hashCode.toString()),
            entry: entry,
            getMedicationName: getMedicationName,
            getMedicationSubtitle: getMedicationSubtitle,
            formatTime: formatTime,
            statusLabel: statusLabel,
            statusColor: statusColor,
            statusIcon: statusIcon,
            onEdit: onEdit,
            onDelete: onDelete,
            onStatusToggle: onStatusToggle,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
