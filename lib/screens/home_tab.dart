import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/theme_controller.dart';
import 'daily_adhkar_screen.dart';
import 'daily_content.dart';
import 'growth_screen.dart';
import 'hajj_screen.dart';
import 'hijri_calendar_screen.dart';
import 'hisn_screen.dart';
import 'home_cards2.dart';
import 'home_daily_card.dart';
import 'home_extras.dart';
import 'home_hero2.dart';
import 'home_sections.dart';
import 'home_stats_card.dart';
import 'home_widgets2.dart';
import 'khatma_screen.dart';
import 'location_service.dart';
import 'mushaf_reader.dart';
import 'mushaf_service.dart';
import 'nawawi_screen.dart';
import 'notification_service.dart';
import 'notifications_screen.dart';
import 'prayer_logic.dart';
import 'prayer_tracker_screen.dart';
import 'ramadan_screen.dart';
import 'rf_design.dart';
import 'ruqyah_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'stats_service.dart';
import 'tasbih_screen.dart';
import 'zakat_screen.dart';

class HomeTab extends StatefulWidget {
  final bool active;
  final ValueChanged<int>? onSwitchTab;
  const HomeTab({Key? key, this.active = true, this.onSwitchTab})
      : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  PrayerData? data;
  String? error;
  NextInfo? next;
  final ValueNotifier<Duration> leftN =
      ValueNotifier<Duration>(Duration.zero);
  DailyItem? verse;
  DailyItem? hadith;
  DailyItem? dua;
  int? lastPage;
  Goals goals = const Goals(5, 100);
  DayStats? today;
  int streak = 0;
  int tick = 0;
  String place = '';
  bool notifOff = true;
  int _day = DateTime.now().day;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadPrayer();
    _loadDaily();
    _loadMisc();
    _scheduleNotifs();
    WidgetsBinding.instance.addPostFrameCallback((_) => _askNotifs());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant HomeTab old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _tick();
      _loadMisc();
      _scheduleNotifs();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    leftN.dispose();
    super.dispose();
  }

  Future<void> _askNotifs() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool('n_asked') ?? false) return;
    await p.setBool('n_asked', true);
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تفعيل التنبيهات؟'),
        content: const Text(
          'تنبيه عند دخول وقت كل صلاة بصوت أذان المدينة، وتذكير بأذكار '
          'الصباح والمساء. تقدر تعدّلها بأي وقت من أيقونة الجرس.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('لاحقاً'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تفعيل'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final granted = await enableDefaultNotifications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'تم تفعيل التنبيهات'
                : 'اسمح بالإشعارات من إعدادات الجوال',
          ),
        ),
      );
      _loadMisc();
    } catch (_) {}
  }

  Future<void> _scheduleNotifs() async {
    try {
      await rescheduleAll();
    } catch (_) {}
  }

  Future<void> _loadPrayer() async {
    try {
      final d = await loadPrayerData();
      final p = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        data = d;
        error = null;
        place = p.getString('loc_name') ?? '';
        _day = DateTime.now().day;
      });
      _tick();
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    }
  }

  void _tick() {
    final d = data;
    if (d == null || !mounted || !widget.active) return;
    final now = DateTime.now();
    if (now.day != _day) {
      _day = now.day;
      _loadPrayer();
      return;
    }
    final n = nextOf(d.times);
    if (next == null || next!.name != n.name) {
      setState(() => next = n);
    }
    leftN.value = n.time.difference(now);
  }

  Future<void> _loadDaily() async {
    final v = await verseOfDay();
    if (mounted) setState(() => verse = v);
    final h = await hadithOfDay();
    if (mounted) setState(() => hadith = h);
    final d = await duaOfDay();
    if (mounted) setState(() => dua = d);
  }

  Future<void> _loadMisc() async {
    final l = await getLastPage();
    final g = await loadGoals();
    final t = await loadToday();
    final s = await loadStreak();
    final p = await SharedPreferences.getInstance();
    final off = !((p.getBool('n_prayers') ?? false) ||
        (p.getBool('n_morning') ?? false) ||
        (p.getBool('n_evening') ?? false));
    if (!mounted) return;
    setState(() {
      lastPage = l;
      goals = g;
      today = t;
      streak = s;
      notifOff = off;
      tick++;
    });
  }

  Future<void> _go(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    _loadMisc();
  }

  Future<void> _pickCity() async {
    final ok = await showCityPicker(context);
    if (!ok) return;
    await _loadPrayer();
    try {
      await rescheduleAll(force: true);
    } catch (_) {}
  }

  List<RfSvc> _services() {
    return [
      RfSvc('متابعة الصلوات', Icons.fact_check,
          () => _go(const PrayerTrackerScreen())),
      RfSvc('رمضان', Icons.nightlight_round, () => _go(const RamadanScreen())),
      RfSvc('زكاة المال', Icons.calculate, () => _go(const ZakatScreen())),
      RfSvc('التقويم الهجري', Icons.calendar_month,
          () => _go(const HijriCalendarScreen())),
      RfSvc('الختمة', Icons.auto_awesome, () => _go(const KhatmaScreen())),
      RfSvc('الإحصائيات', Icons.insights, () => _go(const StatsScreen())),
      RfSvc('شجرة التزامك', Icons.park, () => _go(const GrowthScreen())),
      RfSvc('المسبحة', Icons.touch_app, () => _go(const TasbihScreen())),
      RfSvc('أذكار الصباح', Icons.wb_sunny,
          () => _go(const DailyAdhkarScreen(morning: true))),
      RfSvc('أذكار المساء', Icons.nights_stay,
          () => _go(const DailyAdhkarScreen(morning: false))),
      RfSvc('حصن المسلم', Icons.favorite, () => _go(const HisnScreen())),
      RfSvc('الرقية الشرعية', Icons.healing, () => _go(const RuqyahScreen())),
      RfSvc('الأربعون النووية', Icons.menu_book,
          () => _go(const NawawiScreen())),
      RfSvc('الحج والعمرة', Icons.mosque, () => _go(const HajjScreen())),
      RfSvc('المصحف', Icons.auto_stories,
          () => _go(MushafReader(startPage: lastPage ?? 1))),
      RfSvc('الإعدادات', Icons.settings, () async {
        await _go(const SettingsScreen());
        _loadPrayer();
      }),
    ];
  }

  Widget _prayers() {
    final d = data;
    final n = next;
    if (d != null && n != null) {
      return RfPrayerGrid(times: d.times, next: n, left: leftN);
    }
    if (error != null) {
      return Card(
        color: kCardBackground,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ListTile(
          title: Text(error!),
          trailing: TextButton(
            onPressed: () {
              setState(() => error = null);
              _loadPrayer();
            },
            child: const Text('إعادة'),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kGreen,
      onRefresh: () async {
        await _loadPrayer();
        await _loadMisc();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          RfHomeHero(
            data: data,
            next: next,
            left: leftN,
            active: widget.active,
            bellDot: notifOff,
            onSearch: () => _go(const SearchScreen()),
            onBell: () => _go(const NotificationsScreen()),
            onTheme: ThemeController.toggle,
            onSettings: () async {
              await _go(const SettingsScreen());
              _loadPrayer();
            },
          ),
          RamadanHomeCard(
            active: widget.active,
            tick: tick,
            onTap: () => _go(const RamadanScreen()),
          ),
          RfDateRow(
            place: place,
            onPlace: _pickCity,
            onDate: () => _go(const HijriCalendarScreen()),
          ),
          RfOccasionBanner(active: widget.active),
          RfSection(
            'أوقات الصلاة',
            icon: Icons.mosque,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.location_on_outlined, size: 16),
                SizedBox(width: 4),
                Text('حسب موقعك', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          _prayers(),
          RfShortcuts4(
            onTab: (i) {
              final f = widget.onSwitchTab;
              if (f != null) f(i);
            },
          ),
          RfQuranBanner(
            page: lastPage,
            onTap: () => _go(MushafReader(startPage: lastPage ?? 1)),
          ),
          PrayerDotsCard(
            active: widget.active,
            tick: tick,
            onTap: () => _go(const PrayerTrackerScreen()),
          ),
          const RfSection('خدماتك', icon: Icons.apps),
          RfServiceGrid(items: _services()),
          const SizedBox(height: 8),
          ContinueCard(
            page: lastPage,
            onTap: () => _go(MushafReader(startPage: lastPage ?? 1)),
          ),
          StatsCard(
            today: today,
            goals: goals,
            streak: streak,
            onTap: () => _go(const StatsScreen()),
          ),
          TreeCard(
            active: widget.active,
            onTap: () => _go(const GrowthScreen()),
          ),
          if (verse != null)
            DailyCard(label: 'آية اليوم', icon: Icons.menu_book, item: verse!),
          if (hadith != null)
            DailyCard(
              label: 'حديث اليوم',
              icon: Icons.format_quote,
              item: hadith!,
            ),
          if (dua != null)
            DailyCard(label: 'دعاء اليوم', icon: Icons.front_hand, item: dua!),
        ],
      ),
    );
  }
}
