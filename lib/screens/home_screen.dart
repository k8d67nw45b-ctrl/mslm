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
    return Scaffold(
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: kCardBackground,
        selectedItemColor: kGreen,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'القرآن'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'الأذكار'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'الصلاة'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'القبلة'),
        ],
      ),
    );
  }
}
