import 'package:flutter/material.dart';
import 'widgets/greeting_section.dart';
import 'widgets/streak_card_widget.dart';
import 'widgets/daily_goal_card.dart';
import 'widgets/next_action_card.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 24),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFDFDFE), Color(0xFFF4F6FB)],
        ),
      ),
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Section
            const GreetingSection(),
            const SizedBox(height: 24),

            // Streak & Daily Goal Cards
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(child: StreakCardWidget()),
                  const SizedBox(width: 24),
                  const Expanded(child: DailyGoalCard()),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Next Action Section
            const Text(
              'Next Action',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF20242D),
              ),
            ),
            const SizedBox(height: 14),
            const NextActionCard(),
          ],
        ),
      ),
    );
  }
}
