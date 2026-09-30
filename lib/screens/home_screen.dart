import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'home_tab.dart';
import 'quran_screen.dart';
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

  final List<Widget> _screens = const [
    HomeTab(),
    QuranScreen(),
    AdhkarScreen(),
    PrayerScreen(),
    QiblaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: kCardBackground,
        selectedItemColor: kGreen,
        unselectedItemColor: Colors.white54,
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
