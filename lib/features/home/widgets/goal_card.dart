import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class GoalCard extends StatelessWidget {
  final double progress;

  const GoalCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 152,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.black04,
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'GOAL HARIAN',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    height: 1.2, 
                  ),
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.check_circle_outline,
                color: AppColors.brandBlueAlt,
                size: 20,
              ),
            ],
          ),

          const Spacer(), 

          Text(
            '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          LinearProgressIndicator(
            value: progress.clamp(0, 1),
            backgroundColor: Colors.grey[200],
            color: Colors.teal,
            minHeight: 8,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
    );
  }
}