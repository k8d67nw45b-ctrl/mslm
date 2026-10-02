import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'daily_adhkar_screen.dart';
import 'hisn_screen.dart';
import 'nawawi_screen.dart';
import 'hajj_screen.dart';
import 'ruqyah_screen.dart';

class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({Key? key}) : super(key: key);

  Widget _tile(BuildContext c, String t, IconData i, Widget page) {
    return Card(
      color: kCardBackground,
      margin: const EdgeInsets.only(bottom: kPaddingMedium),
      child: ListTile(
        contentPadding: const EdgeInsets.all(kPaddingMedium),
        leading: Icon(i, color: kGreen, size: 34),
        title: Text(t, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.chevron_left, color: kGreen),
        onTap: () => Navigator.push(
          c,
          MaterialPageRoute(builder: (_) => page),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(kPaddingMedium),
      children: [
        _tile(context, 'أذكار الصباح', Icons.wb_sunny,
            const DailyAdhkarScreen(morning: true)),
        _tile(context, 'أذكار المساء', Icons.nights_stay,
            const DailyAdhkarScreen(morning: false)),
        _tile(context, 'حصن المسلم', Icons.favorite, const HisnScreen()),
        _tile(context, 'الرقية الشرعية', Icons.healing,
            const RuqyahScreen()),
        _tile(context, 'الأربعون النووية', Icons.menu_book,
            const NawawiScreen()),
        _tile(context, 'مساعد الحج والعمرة', Icons.mosque,
            const HajjScreen()),
      ],
    );
  }
}
