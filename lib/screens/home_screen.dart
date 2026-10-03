import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme_controller.dart';
import 'home_tab.dart';
import 'quran_screen.dart';
import 'adhkar_screen.dart';
import 'prayer_screen.dart';
import 'qibla_screen.dart';

const _titles = ['الرئيسية', 'القرآن', 'الأذكار', 'الصلاة', 'القبلة'];

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
        return const QuranScreen();
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
    final dark = ThemeController.mode.value == ThemeMode.dark;
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => _selectedIndex = 0);
      },
      child: Scaffold(
        appBar: _selectedIndex == 0
            ? null
            : AppBar(
                title: Text(_titles[_selectedIndex]),
                actions: [
                  IconButton(
                    icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
                    onPressed: ThemeController.toggle,
                  ),
                ],
              ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: _selectedIndex != 0,
              child: HomeTab(active: _selectedIndex == 0),
            ),
            if (_selectedIndex != 0)
              KeyedSubtree(
                key: ValueKey(_selectedIndex),
                child: _tab(_selectedIndex),
              ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          backgroundColor: kCardBackground,
          indicatorColor: kGreen.withOpacity(0.25),
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
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
    );
  }
}
