import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ProgressSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const ProgressSectionHeader({
    super.key,
    this.title = 'Your Progress',
    this.subtitle = "Keep it up! You're doing amazing this week.",
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textTitleDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSubtle,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
