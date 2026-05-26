import 'package:flutter/material.dart';

import '../widgets/bottom_navbar.dart';
import '../../features/home/home_page.dart';
import '../../features/medication/pages/meds_page.dart';
import '../../features/stats/stats_page.dart';
import '../widgets/header.dart';
import '../../core/theme/app_colors.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final headerSpace = mq.padding.top + 92.0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldNeutral,
      body: Stack(
        children: [
          Positioned.fill(
            top: headerSpace,
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              children: const [HomePage(), MedsPage(), StatsPage()],
            ),
          ),
          const Positioned(left: 0, right: 0, top: 0, child: StatsHeader()),
          Builder(
            builder: (ctx) {
              final mq = MediaQuery.of(ctx);
              final bottomPad = mq.viewPadding.bottom + 12;
              return Positioned(
                left: 20,
                right: 20,
                bottom: bottomPad,
                child: BottomNavbar(currentIndex: _currentIndex, onTap: _onTap),
              );
            },
          ),
        ],
      ),
    );
  }
}
