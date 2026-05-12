import 'package:flutter/material.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: StylishBottomBar(
          option: BubbleBarOptions(
            bubbleFillStyle: BubbleFillStyle.fill,
            opacity: 0.3,
            barStyle: BubbleBarStyle.vertical,
          ),
          currentIndex: currentIndex,
          onTap: onTap,
          items: [
            BottomBarItem(
              icon: const Icon(Icons.home_rounded),
              selectedIcon: const Icon(Icons.home_rounded),
              title: const Text('Home'),
              selectedColor: const Color(0xFF6B5CE7),
            ),
            BottomBarItem(
              icon: const Icon(Icons.medication_liquid_rounded),
              selectedIcon: const Icon(Icons.medication_liquid_rounded),
              title: const Text('Meds'),
              selectedColor: const Color(0xFF6B5CE7),
            ),
            BottomBarItem(
              icon: const Icon(Icons.bar_chart_rounded),
              selectedIcon: const Icon(Icons.bar_chart_rounded),
              title: const Text('Stats'),
              selectedColor: const Color(0xFF6B5CE7),
            ),
          ],
        ),
      ),
    );
  }
}

