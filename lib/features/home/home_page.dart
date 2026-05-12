import 'package:flutter/material.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/header.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: AssetImage('lib/assets/maskot-rmv.png'),
          ),
        ),
        title: const Text(
          'Alveo',
          style: TextStyle(
            color: Color(0xFF7B66FF),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF7B66FF),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hai, Leo 👋',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Card Motivasi
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Kamu hebat hari ini!\nTarik napas dalam-dalam dan teruslah berusaha.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                  Image.asset(
                    'lib/assets/maskot-rmv.png',
                    width: 80,
                  ), // Sesuaikan path asset Anda
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Row untuk Streak dan Daily Goal
            Row(
              children: [
                // Card Streak
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B66FF), Color(0xFFA594FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          // ignore: deprecated_member_use
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(
                            Icons.local_fire_department,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          '7 Day',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'STREAK 🔥',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // Card Daily Goal
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
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
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Icon(
                              Icons.check_circle_outline,
                              color: Color(0xFF4361EE),
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          '80%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: 0.8,
                          backgroundColor: Colors.grey[200],
                          color: Colors.teal,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            const Text(
              'Next Action',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

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
                          child: const Icon(
                            Icons.poll,
                            color: Color(0xFF4361EE),
                          ),
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
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
      ),
    );
  }
}
