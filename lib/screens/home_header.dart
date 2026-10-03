import 'package:flutter/material.dart';
import 'app_settings.dart';
import 'package:hijri/hijri_calendar.dart';
import '../core/constants.dart';
import 'prayer_helpers.dart';

const _days = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];
const _months = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];
const _hijri = [
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الآخر',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];

class HomeHeader extends StatelessWidget {
  final NextInfo? next;
  final Duration left;
  final VoidCallback onSearch;
  final VoidCallback onBell;
  final VoidCallback onTheme;
  final VoidCallback onAdhkar;

  const HomeHeader({
    Key? key,
    required this.next,
    required this.left,
    required this.onSearch,
    required this.onBell,
    required this.onTheme,
    required this.onAdhkar,
  }) : super(key: key);

  Widget _btn(IconData i, VoidCallback f) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: f,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kCardBackground.withOpacity(0.85),
          ),
          child: Icon(i, color: kGreen, size: 22),
        ),
      ),
    );
  }

  Widget _dm(String day, String month, Color ink) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ink,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(month, style: const TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  Widget _dateCard(DateTime now, HijriCalendar h, Color ink) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            _days[now.weekday - 1],
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: ink,
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _dm('${h.hDay}', _hijri[h.hMonth - 1], ink),
              ),
              Expanded(
                child: _dm('${now.day}', _months[now.month - 1], ink),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('${h.hYear}', style: const TextStyle(color: Colors.grey)),
              Text('${now.year}', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : const Color(0xFF005C42);
    final now = DateTime.now();
        final h = HijriCalendar.fromDate(
      now.add(Duration(days: AppSettings.hijriOffset.value)),
    );
    final hour = now.hour;
    final greet = hour < 12
        ? 'صباح الخير'
        : hour < 17
            ? 'نهارك سعيد'
            : hour < 21
                ? 'مساء الخير'
                : 'ليلة سعيدة';
    final emoji = hour < 12
        ? '☀️'
        : hour < 17
            ? '🌤️'
            : hour < 21
                ? '🌇'
                : '🌙';
    final btn = hour < 12
        ? 'اقرأ أذكار الصباح'
        : hour < 22
            ? 'اقرأ أذكار المساء'
            : 'اقرأ أذكار النوم';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [const Color(0xFF0B3B2E), kDarkBackground]
              : [const Color(0xFFCFE9D3), kLightBackground],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'الرئيسية',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ink,
                    ),
                  ),
                  const Spacer(),
                  _btn(Icons.search, onSearch),
                  _btn(Icons.notifications_none, onBell),
                  _btn(dark ? Icons.light_mode : Icons.dark_mode, onTheme),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greet, style: TextStyle(fontSize: 26, color: ink)),
                        Text(emoji, style: const TextStyle(fontSize: 34)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: onAdhkar,
                          child: Text(btn),
                        ),
                        const SizedBox(height: 12),
                        if (next != null) _nextPill(left),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _dateCard(now, h, ink),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nextPill(Duration d) {
    final txt = '${d.inHours} س و${d.inMinutes % 60} د';
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        const Icon(Icons.mosque, color: kGreen, size: 22),
        Text('صلاة ${next!.name} بعد:'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFB6F36B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            txt,
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
