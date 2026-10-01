import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'prayer_helpers.dart';

class PrayerGrid extends StatelessWidget {
  final PrayerTimes times;
  final NextInfo next;
  final Duration left;

  const PrayerGrid({
    Key? key,
    required this.times,
    required this.next,
    required this.left,
  }) : super(key: key);

  Widget _cell(String name, DateTime t, IconData icon) {
    final isNext = name == next.name;
    final fg = isNext ? Colors.white : null;
    return Expanded(
      child: Container(
        height: 112,
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isNext ? const Color(0xFF005C42) : kCardBackground,
          borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: isNext ? kGreen : Colors.grey),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(name, style: TextStyle(fontSize: 14, color: fg)),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: fmtTime(t),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: fg,
                      ),
                    ),
                    TextSpan(
                      text: ' ${ampm(t)}',
                      style: TextStyle(fontSize: 10, color: fg),
                    ),
                  ],
                ),
              ),
            ),
            if (isNext)
              Text(
                hms(left),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFB6F36B),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = times;
    return Column(
      children: [
        Row(
          children: [
            _cell('الفجر', t.fajr, Icons.dark_mode_outlined),
            _cell('الشروق', t.sunrise, Icons.wb_twilight),
            _cell('الظهر', t.dhuhr, Icons.wb_sunny),
          ],
        ),
        Row(
          children: [
            _cell('العصر', t.asr, Icons.wb_sunny_outlined),
            _cell('المغرب', t.maghrib, Icons.wb_twilight),
            _cell('العشاء', t.isha, Icons.nightlight_round),
            _cell('منتصف الليل', midnightOf(t), Icons.bedtime_outlined),
          ],
        ),
      ],
    );
  }
}
