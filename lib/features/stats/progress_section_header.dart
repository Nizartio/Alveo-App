import 'package:flutter/material.dart';

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
            color: Color(0xFF1A1640),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF9E9AB8),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}