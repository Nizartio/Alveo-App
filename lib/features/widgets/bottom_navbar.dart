import 'package:flutter/material.dart';

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
    final mq = MediaQuery.of(context);
    final navHeight = (mq.size.height * 0.09).clamp(60.0, 80.0);

    return Container(
      height: navHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5CE7).withOpacity(0.18),
            blurRadius: 30,
            spreadRadius: 12,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.medication_rounded,
            label: 'Meds',
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Stats',
            isActive: currentIndex == 2,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF6B5CE7);
    const inactiveColor = Color(0xFF94A3B8);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 72.0;
        final iconSize = (availHeight * 0.45).clamp(16.0, 32.0);
        final gap = (availHeight * 0.06).clamp(4.0, 8.0);
        final fontSize = (availHeight * 0.18).clamp(10.0, 14.0);

        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            constraints: const BoxConstraints(minWidth: 64),
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: availHeight * 0.08,
            ),
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(50),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : inactiveColor,
                  size: iconSize,
                ),
                SizedBox(height: gap),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : inactiveColor,
                    fontSize: fontSize,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
