import 'package:flutter/material.dart';

class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 10),
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
                style: TextStyle(
                  color: Color(0xFF8A90A0),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 0.4,
                ),
              ),
              Icon(
                Icons.check_circle_outline,
                color: Color(0xFF4A67F5),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '80%',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20242D),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.8,
              backgroundColor: const Color(0xFFE9EDF5),
              color: const Color(0xFF39B8A3),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
