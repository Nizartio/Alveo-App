import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class HistoryEntryActions extends StatefulWidget {
  final Map<String, dynamic> entry;
  final String Function(Map<String, dynamic>) getMedicationName;
  final String Function(Map<String, dynamic>) getMedicationSubtitle;
  final String Function(String) formatTime;
  final String Function(String?) statusLabel;
  final Color Function(String?) statusColor;
  final IconData Function(String?) statusIcon;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;
  final void Function(Map<String, dynamic>)? onStatusToggle;

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
    this.onStatusToggle,
  });

  @override
  State<HistoryEntryActions> createState() => _HistoryEntryActionsState();
}

class _HistoryEntryActionsState extends State<HistoryEntryActions>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.15), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 2),
    ]).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleStatusTap() {
    if (widget.onStatusToggle == null) return;
    _animController.forward().then((_) {
      _animController.reset();
      widget.onStatusToggle!(widget.entry);
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.entry['status']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.statusColor(status).withAlpha(77)),
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
          AnimatedBuilder(
            animation: _scaleAnim,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _handleStatusTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.statusColor(status).withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      widget.statusIcon(status),
                      color: widget.statusColor(status),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.getMedicationName(widget.entry),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${widget.getMedicationSubtitle(widget.entry)} • ${widget.formatTime(widget.entry['scheduled_time']?.toString() ?? '')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.statusLabel(status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.statusColor(status),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                widget.onEdit(widget.entry);
              } else if (value == 'delete') {
                widget.onDelete(widget.entry);
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
