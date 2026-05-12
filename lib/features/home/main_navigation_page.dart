import 'package:flutter/material.dart';
import '../medication/pages/meds_page.dart';
import '../widgets/bottom_navbar.dart';
import 'home_page.dart';
import 'stats_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  void _onBottomNavTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [HomePage(), MedsPage(), StatsPage()],
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentPageIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}
