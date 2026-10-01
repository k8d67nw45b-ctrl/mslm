import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import 'location_service.dart';
import 'prayer_logic.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({Key? key}) : super(key: key);

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  PrayerData? data;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      error = null;
      data = null;
    });
    try {
      final d = await loadPrayerData();
      setState(() => data = d);
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Future<void> _pick() async {
    final ok = await showCityPicker(context);
    if (ok) _load();
  }

  String _fmt(DateTime t) => DateFormat('hh:mm a').format(t.toLocal());

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kPaddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: kPaddingMedium),
              ElevatedButton(
                onPressed: _pick,
                child: const Text('اختيار المدينة'),
              ),
              TextButton(
                onPressed: _load,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return _list(data!);
  }

  Widget _list(PrayerData d) {
    final t = d.times;
    final rows = <MapEntry<String, DateTime>>[
      MapEntry('الفجر', t.fajr),
      MapEntry('الشروق', t.sunrise),
      MapEntry('الظهر', t.dhuhr),
      MapEntry('العصر', t.asr),
      MapEntry('المغرب', t.maghrib),
      MapEntry('العشاء', t.isha),
    ];
    return ListView(
      padding: const EdgeInsets.all(kPaddingMedium),
      children: [
        Text(
          'الصلاة القادمة: ${d.next}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        TextButton.icon(
          onPressed: _pick,
          icon: const Icon(Icons.location_on, color: kGreen),
          label: Text('الموقع: ${d.place} (تغيير)'),
        ),
        const SizedBox(height: kPaddingSmall),
        for (final r in rows) _row(r, r.key == d.next),
      ],
    );
  }

  Widget _row(MapEntry<String, DateTime> r, bool isNext) {
    return Card(
      color: isNext ? kGreen : kCardBackground,
      margin: const EdgeInsets.only(bottom: kPaddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(r.key, style: const TextStyle(fontSize: 18)),
            Text(
              _fmt(r.value),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
