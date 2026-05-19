import 'package:flutter/material.dart';

import 'widgets/action_card.dart';
import 'widgets/goal_card.dart';
import 'widgets/header.dart';
import 'widgets/streak_card.dart';
import '../../core/theme/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final navHeight = (mq.size.height * 0.09).clamp(60.0, 80.0);
    final bottomInset = mq.viewPadding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, navHeight + bottomInset + 28),
        children: [
          const HeaderContent(),
          Row(
            children: const [
              Expanded(child: StreakCard()),
              SizedBox(width: 16),
              Expanded(child: GoalCard()),
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
          const NextActionCard(),
        ],
      ),
    );
  }
}
