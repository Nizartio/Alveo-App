import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StreakCard extends StatelessWidget {
  final int streakDays;
  final int personalBest;

  const StreakCard({
    super.key,
    required this.streakDays,
    required this.personalBest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 152, 
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.streakGradient,
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
          CircleAvatar(
            backgroundColor: AppColors.white20,
            child: const Icon(
              Icons.local_fire_department,
              color: AppColors.white,
              size: 24,
            ),
          ),
          
          const Spacer(),

          Text(
            '$streakDays Hari',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'STREAK 🔥',
            style: TextStyle(
              color: AppColors.white70, 
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}