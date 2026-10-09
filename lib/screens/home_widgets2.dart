import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'hijri_calendar_screen.dart';
import 'occasions.dart';
import 'prayer_helpers.dart';
import 'prayer_logic.dart';
import 'rf_design.dart';

class RfDateRow extends StatelessWidget {
  final String place;
  final VoidCallback onPlace;
  final VoidCallback onDate;
  const RfDateRow({
    Key? key,
    required this.place,
    required this.onPlace,
    required this.onDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final h = hijriOf(now);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 6),
      child: Row(
        children: [
          InkWell(
            onTap: onDate,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.calendar_month, color: kGreen),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rfHijriLine(h.hDay, h.hMonth, h.hYear),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      rfGregLine(now),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Flexible(
            child: InkWell(
              onTap: onPlace,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: kGreen.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 18, color: kGreen),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        place.isEmpty ? 'تحديد الموقع' : place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RfOccasionBanner extends StatefulWidget {
  final bool active;
  const RfOccasionBanner({Key? key, required this.active}) : super(key: key);

  @override
  State<RfOccasionBanner> createState() => _RfOccasionBannerState();
}

class _RfOccasionBannerState extends State<RfOccasionBanner> {
  List<Occasion> today = [];
  Upcoming? next;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant RfOccasionBanner old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _load();
  }

  void _load() {
    if (!mounted) return;
    final t = occasionsOn(DateTime.now());
    final up = upcomingOccasions();
    Upcoming? n;
    for (final u in up) {
      if (u.inDays > 0) {
        n = u;
        break;
      }
    }
    setState(() {
      today = t;
      next = n;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final mt = isMonThu(now);
    String title;
    String sub;
    var hot = false;
    if (today.isNotEmpty) {
      hot = true;
      title = 'اليوم: ${today.map((o) => o.name).join('، ')}';
      sub = today.first.note;
    } else if (mt) {
      hot = true;
      title =
          'اليوم يوم ${now.weekday == DateTime.monday ? 'الاثنين' : 'الخميس'}';
      sub = 'يستحب صيامه';
    } else if (next != null) {
      title = 'بعد ${next!.inDays} يوم: ${next!.o.name}';
      sub = next!.o.note;
    } else {
      title = 'التقويم الهجري';
      sub = 'المناسبات وأطوار القمر';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: kGreen.withOpacity(hot ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HijriCalendarScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: rfDeep,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left, color: kGreen),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Slot {
  final String name;
  final DateTime time;
  final IconData icon;
  const _Slot(this.name, this.time, this.icon);
}

class RfPrayerGrid extends StatelessWidget {
  final PrayerTimes times;
  final NextInfo next;
  final ValueListenable<Duration> left;
  const RfPrayerGrid({
    Key? key,
    required this.times,
    required this.next,
    required this.left,
  }) : super(key: key);

  Widget _cell(BuildContext context, _Slot s) {
    final hot = next.name == s.name;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: hot ? null : kCardBackground,
        gradient: hot
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF12806A), Color(0xFF0B4F44)],
              )
            : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: (dark || hot)
            ? null
            : const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(s.icon, size: 26, color: hot ? Colors.white : rfGold),
          const SizedBox(height: 4),
          Text(
            s.name,
            style: TextStyle(fontSize: 14, color: hot ? Colors.white : null),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                fmtTime(s.time),
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: hot ? Colors.white : null,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                ampm(s.time),
                style: TextStyle(
                  fontSize: 11,
                  color: hot ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
          ),
          if (hot)
            ValueListenableBuilder<Duration>(
              valueListenable: left,
              builder: (c, l, _) => Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${hms(l)} متبقي',
                  style: const TextStyle(color: Colors.white, fontSize: 10.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _Slot('الفجر', times.fajr, Icons.nightlight_round),
      _Slot('الشروق', times.sunrise, Icons.wb_twilight),
      _Slot('الظهر', times.dhuhr, Icons.wb_sunny),
      _Slot('العصر', times.asr, Icons.light_mode),
      _Slot('المغرب', times.maghrib, Icons.nights_stay),
      _Slot('العشاء', times.isha, Icons.dark_mode),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.8,
        children: [for (final s in items) _cell(context, s)],
      ),
    );
  }
}

class RfShortcuts4 extends StatelessWidget {
  final ValueChanged<int> onTab;
  const RfShortcuts4({Key? key, required this.onTab}) : super(key: key);

  Widget _t(IconData icon, String label, Color bg, int tab) {
    return InkWell(
      onTap: () => onTab(tab),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: kGreen, size: 30),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = kGreen.withOpacity(0.14);
    final b = rfGold.withOpacity(0.18);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _t(Icons.menu_book, 'القرآن', b, 1),
          _t(Icons.favorite_border, 'الأذكار', a, 2),
          _t(Icons.mosque, 'الصلاة', b, 3),
          _t(Icons.explore, 'القبلة', a, 4),
        ],
      ),
    );
  }
}

class RfSvc {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const RfSvc(this.label, this.icon, this.onTap);
}

class RfServiceGrid extends StatelessWidget {
  final List<RfSvc> items;
  const RfServiceGrid({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.88,
        children: [
          for (final s in items)
            Material(
              color: kCardBackground,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: s.onTap,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(s.icon, color: kGreen, size: 26),
                      const SizedBox(height: 6),
                      Text(
                        s.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RfQuranBanner extends StatelessWidget {
  final int? page;
  final VoidCallback onTap;
  const RfQuranBanner({Key? key, required this.page, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 96,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Color(0xFF0B3B36), Color(0xFF17604F)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -6,
                top: -10,
                bottom: -10,
                child: Icon(
                  Icons.auto_stories,
                  size: 110,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'اقرأ القرآن',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            page == null
                                ? 'نور لقلبك .. وراحة لروحك'
                                : 'تابع من صفحة $page',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
