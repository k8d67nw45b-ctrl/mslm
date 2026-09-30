import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import 'adhkar_data.dart';
import 'adhkar_detail.dart';
import 'home_cards.dart';
import 'nawawi_screen.dart';
import 'prayer_logic.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  PrayerData? data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await loadPrayerData();
      if (mounted) setState(() => data = d);
    } catch (_) {}
  }

  String _nextTime(PrayerData d) {
    final n = d.times.timeForPrayer(d.times.nextPrayer());
    if (n == null) return '';
    return DateFormat('hh:mm a').format(n.toLocal());
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final d = data;
    return ListView(
      padding: const EdgeInsets.all(kPaddingMedium),
      children: [
        Text(
          'السلام عليكم',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: kPaddingMedium),
        HomeCard(
          icon: Icons.access_time,
          title: d == null ? 'الصلاة القادمة' : 'الصلاة القادمة: ${d.next}',
          subtitle: d == null ? 'جاري تحديد الموقع...' : _nextTime(d),
          onTap: _load,
        ),
        HomeCard(
          icon: Icons.favorite,
          title: 'حصن المسلم',
          subtitle: 'أذكار الصباح والمساء والنوم',
          onTap: () => _open(AdhkarDetail(cat: adhkarCategories[0])),
        ),
        HomeCard(
          icon: Icons.menu_book,
          title: 'الأربعون النووية',
          subtitle: 'أحاديث مع البحث والمفضلة',
          onTap: () => _open(const NawawiScreen()),
        ),
      ],
    );
  }
}
