import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAILY GOAL',
                style: TextStyle(color: AppColors.textMutedSoft, fontSize: 16),
              ),
              Icon(
                Icons.check_circle_outline,
                color: AppColors.brandBlueAlt,
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: 28),

          const Text(
            '80%',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          LinearProgressIndicator(
            value: 0.8,
            backgroundColor: AppColors.progressTrack,
            color: AppColors.progressAccent,
            minHeight: 8,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
    );
  }
}
