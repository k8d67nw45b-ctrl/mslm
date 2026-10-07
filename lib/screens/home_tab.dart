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
import 'hisn_detail.dart';
import 'hisn_screen.dart';
import 'hisn_service.dart';
import 'home_cards2.dart';
import 'home_daily_card.dart';
import 'home_extras.dart';
import 'home_prayers.dart';
import 'home_sections.dart';
import 'home_stats_card.dart';
import 'khatma_screen.dart';
import 'mushaf_reader.dart';
import 'mushaf_service.dart';
import 'nawawi_screen.dart';
import 'notification_service.dart';
import 'notifications_screen.dart';
import 'prayer_helpers.dart';
import 'prayer_logic.dart';
import 'prayer_tracker_screen.dart';
import 'qibla_screen.dart';
import 'ramadan_screen.dart';
import 'ruqyah_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'sky_hero.dart';
import 'stats_screen.dart';
import 'stats_service.dart';
import 'tasbih_screen.dart';
import 'zakat_screen.dart';

class HomeTab extends StatefulWidget {
  final bool active;
  const HomeTab({Key? key, this.active = true}) : super(key: key);

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
      if (!mounted) return;
      setState(() {
        data = d;
        error = null;
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
    if (!mounted) return;
    setState(() {
      lastPage = l;
      goals = g;
      today = t;
      streak = s;
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

  Future<void> _openSleep() async {
    try {
      final all = await loadHisn();
      final s = all.firstWhere((e) => e.title.contains('أذكار النوم'));
      if (!mounted) return;
      await _go(HisnDetail(sec: s));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح أذكار النوم')),
      );
    }
  }

  void _openNow() {
    final h = DateTime.now().hour;
    if (h < 12) {
      _go(const DailyAdhkarScreen(morning: true));
    } else if (h < 22) {
      _go(const DailyAdhkarScreen(morning: false));
    } else {
      _openSleep();
    }
  }

  List<Shortcut> _shortcuts() {
    return [
      Shortcut('متابعة الصلوات', Icons.fact_check, const Color(0xFFDCEBE3),
          () => _go(const PrayerTrackerScreen())),
      Shortcut('رمضان', Icons.nightlight_round, const Color(0xFFDDDCEB),
          () => _go(const RamadanScreen())),
      Shortcut('زكاة المال', Icons.calculate, const Color(0xFFEBE6DC),
          () => _go(const ZakatScreen())),
      Shortcut('التقويم الهجري', Icons.calendar_month, const Color(0xFFE0EBDC),
          () => _go(const HijriCalendarScreen())),
      Shortcut('شجرة التزامك', Icons.park, const Color(0xFFDCEBE3),
          () => _go(const GrowthScreen())),
      Shortcut('الختمة', Icons.auto_awesome, const Color(0xFFEBE6DC),
          () => _go(const KhatmaScreen())),
      Shortcut('الإعدادات', Icons.settings, const Color(0xFFE0E6EB), () async {
        await _go(const SettingsScreen());
        _loadPrayer();
      }),
      Shortcut('الإحصائيات', Icons.insights, const Color(0xFFDCEBE3),
          () => _go(const StatsScreen())),
      Shortcut('أذكار المساء', Icons.nights_stay, const Color(0xFFDDDCEB),
          () => _go(const DailyAdhkarScreen(morning: false))),
      Shortcut('أذكار الصباح', Icons.wb_sunny, const Color(0xFFF1DDD8),
          () => _go(const DailyAdhkarScreen(morning: true))),
      Shortcut('المسبحة', Icons.touch_app, const Color(0xFFE8E8DC),
          () => _go(const TasbihScreen())),
      Shortcut(
        'اتجاه القبلة',
        Icons.explore,
        const Color(0xFFEBDDEB),
        () => _go(
          Scaffold(
            appBar: AppBar(title: const Text('اتجاه القبلة')),
            body: const QiblaScreen(),
          ),
        ),
      ),
      Shortcut('الرقية الشرعية', Icons.healing, const Color(0xFFE6DCEB),
          () => _go(const RuqyahScreen())),
      Shortcut('حصن المسلم', Icons.favorite, const Color(0xFFDCEBE3),
          () => _go(const HisnScreen())),
      Shortcut('الأربعون النووية', Icons.menu_book, const Color(0xFFE3EBDC),
          () => _go(const NawawiScreen())),
      Shortcut('الحج والعمرة', Icons.mosque, const Color(0xFFDCE6EB),
          () => _go(const HajjScreen())),
      Shortcut('المصحف', Icons.auto_stories, const Color(0xFFEBE6DC),
          () => _go(MushafReader(startPage: lastPage ?? 1))),
    ];
  }

  Widget _prayers() {
    final d = data;
    final n = next;
    if (d != null && n != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ValueListenableBuilder<Duration>(
          valueListenable: leftN,
          builder: (context, left, _) =>
              PrayerGrid(times: d.times, next: n, left: left),
        ),
      );
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
          SkyHero(
            data: data,
            next: next,
            left: leftN,
            active: widget.active,
            onSearch: () => _go(const SearchScreen()),
            onBell: () => _go(const NotificationsScreen()),
            onTheme: ThemeController.toggle,
            onAdhkar: _openNow,
          ),
          RamadanHomeCard(
            active: widget.active,
            tick: tick,
            onTap: () => _go(const RamadanScreen()),
          ),
          OccasionCard(active: widget.active),
          SectionTitle(
            'أوقات الصلاة',
            trailing: Row(
              children: const [
                Icon(Icons.location_on_outlined, size: 18),
                SizedBox(width: 4),
                Text('حسب موقعك'),
              ],
            ),
          ),
          _prayers(),
          PrayerDotsCard(
            active: widget.active,
            tick: tick,
            onTap: () => _go(const PrayerTrackerScreen()),
          ),
          const SectionTitle('تطبيقاتك اليومية'),
          ShortcutRow(items: _shortcuts()),
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
