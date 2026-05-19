import 'package:flutter/material.dart';

import '../widgets/bottom_navbar.dart';
import '../widgets/header.dart';

import 'widgets/header.dart';
import 'widgets/streak_card.dart';
import 'widgets/goal_card.dart';
import 'widgets/action_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(36, 136, 36, 136),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeaderContent(),

                const SizedBox(height: 20),

                Row(
                  children: const [
                    Expanded(child: StreakCard()),

                    SizedBox(width: 20),

                    Expanded(child: GoalCard()),
                  ],
                ),

                const SizedBox(height: 20),

                const Text('Next Action', style: TextStyle(fontSize: 24)),

                const SizedBox(height: 12),

                const NextActionCard(),
              ],
            ),
          ),

          const StatsHeader(),

          BottomNavbar(
            currentIndex: _currentNavIndex,
            onTap: (index) {
              setState(() => _currentNavIndex = index);

              if (index == 0) {
                Navigator.pushReplacementNamed(context, '/home');
              } else if (index == 1) {
                Navigator.pushReplacementNamed(context, '/medication');
              } else if (index == 2) {
                Navigator.pushReplacementNamed(context, '/stats');
              }
            },
          ),
        ],
      ),
    );
  }
}
