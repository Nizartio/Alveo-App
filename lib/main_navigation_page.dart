import 'package:flutter/material.dart';

import 'core/dashboard_data.dart';
import 'features/widgets/bottom_navbar.dart';
import 'features/home/home_page.dart';
import 'features/medication/pages/meds_page.dart';
import 'features/stats/stats_page.dart';
import 'features/widgets/header.dart';

const double _kFloatH = 16;
const double _kFloatV = 16;

class MainNavigationPage extends StatefulWidget {
  final int initialIndex;

  const MainNavigationPage({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late final PageController _pageController;
  int _currentIndex = 0;
  late final DashboardData _data;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 2);
    _pageController = PageController(initialPage: _currentIndex);
    _data = DashboardData.instance;
    _data.loadAll();
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

    final statusBarH = mq.viewPadding.top;

    final bottomInset = mq.viewPadding.bottom;

    const headerContentH = 60;
    final headerTotalH = statusBarH + _kFloatH + headerContentH + _kFloatH;

    const navbarH = 80;

    final bottomClearance = bottomInset + _kFloatH + navbarH + _kFloatH;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery(
              data: mq.copyWith(
                padding: mq.padding.copyWith(
                  top: headerTotalH,
                  bottom: bottomClearance,
                ),
                viewPadding: mq.viewPadding.copyWith(
                  top: headerTotalH,
                  bottom: bottomClearance,
                ),
              ),
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                children: [
                  HomePage(data: _data),
                  MedsPage(data: _data),
                  StatsPage(data: _data),
                ],
              ),
            ),
          ),

          Positioned(
            top: statusBarH + _kFloatH,
            left: _kFloatV,
            right: _kFloatV,
            child: const StatsHeader(),
          ),

          Positioned(
            left: _kFloatV,
            right: _kFloatV,
            bottom: bottomInset + _kFloatH,
            child: BottomNavbar(
              currentIndex: _currentIndex,
              onTap: _onTap,
            ),
          ),
        ],
      ),
    );
  }
}