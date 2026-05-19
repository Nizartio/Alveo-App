import 'package:flutter/material.dart';

import 'services/action.dart';
import 'services/daily_goal.dart';
import 'services/greeting.dart';
import 'services/streak.dart';
import '../../core/theme/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.fromLTRB(36, topPad + 16, 36, bottomPad + 16),
        children: [
          const GreetingCard(),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: StreakCard()),
              SizedBox(width: 16),
              Expanded(child: DailyGoalCard()),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Next Action',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1640),
            ),
          ),
          const SizedBox(height: 12),
          const ActionCard(),
        ],
      ),
    );
  }
}