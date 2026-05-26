import 'package:flutter/material.dart';

class GoalCard extends StatelessWidget {
  final double progress;

  const GoalCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                'TUJUAN HARIAN',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              Icon(
                Icons.check_circle_outline,
                color: Color(0xFF4361EE),
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: 28),

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