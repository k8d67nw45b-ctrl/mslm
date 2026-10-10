import 'splash_overlay.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'home_tab.dart';
import 'quran_home.dart';
import 'adhkar_screen.dart';
import 'prayer_screen.dart';
import 'qibla_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Widget _tab(int i) {
    switch (i) {
      case 1:
        return const QuranHome();
      case 2:
        return const AdhkarScreen();
      case 3:
        return const PrayerScreen();
      default:
        return const QiblaScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SplashGate(
  child: PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => _selectedIndex = 0);
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: _selectedIndex != 0,
              child: HomeTab(
                active: _selectedIndex == 0,
                onSwitchTab: (i) => setState(() => _selectedIndex = i),
              ),
            ),
            if (_selectedIndex != 0)
              KeyedSubtree(
                key: ValueKey(_selectedIndex),
                child: _tab(_selectedIndex),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: kCardBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              indicatorColor: kGreen.withOpacity(0.22),
              onDestinationSelected: (i) =>
                  setState(() => _selectedIndex = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'الرئيسية',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'القرآن',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border),
                  selectedIcon: Icon(Icons.favorite),
                  label: 'الأذكار',
                ),
                NavigationDestination(
                  icon: Icon(Icons.access_time),
                  selectedIcon: Icon(Icons.access_time_filled),
                  label: 'الصلاة',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: 'القبلة',
                ),
              ],
            ),
          ),
        ),
      ),
      ));
  }
}
