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

          // Card Medication Reminder
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFFD7E3FF),
                      child: Transform.rotate(
                        angle: -0.5,
                        child: const Icon(Icons.poll, color: Color(0xFF4361EE)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Take Medicine',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '12:00 PM • After Lunch',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B66FF),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Mark as Taken',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.check_circle_outline, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
