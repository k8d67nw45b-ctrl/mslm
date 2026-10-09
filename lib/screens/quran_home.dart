import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/theme_controller.dart';
import 'khatma_screen.dart';
import 'mushaf_reader.dart';
import 'mushaf_service.dart';
import 'quran_screen.dart';
import 'rf_design.dart';
import 'rf_page.dart';

const List<int> _surahPage = [
  1, 2, 50, 77, 106, 128, 151, 177, 187, 208,
  221, 235, 249, 255, 262, 267, 282, 293, 305, 312,
  322, 332, 342, 350, 359, 367, 377, 385, 396, 404,
  411, 415, 418, 428, 434, 440, 446, 453, 458, 467,
  477, 483, 489, 496, 499, 502, 507, 511, 515, 518,
  520, 523, 526, 528, 531, 534, 537, 542, 545, 549,
  551, 553, 554, 556, 558, 560, 562, 564, 566, 568,
  570, 572, 574, 575, 577, 578, 580, 582, 583, 585,
  586, 587, 587, 589, 590, 591, 591, 592, 593, 594,
  595, 595, 596, 596, 597, 597, 598, 598, 599, 599,
  600, 600, 601, 601, 601, 602, 602, 602, 603, 603,
  603, 604, 604, 604,
];

int _pageOf(int surah) {
  if (surah >= 1 && surah <= _surahPage.length) return _surahPage[surah - 1];
  return 1;
}

int _juzPage(int juz) => juz <= 1 ? 1 : 20 * (juz - 1) + 2;

const List<List<int>> _verseRefs = [
  [2, 286],
  [3, 8],
  [14, 7],
  [18, 10],
  [20, 114],
  [23, 118],
  [25, 74],
  [59, 22],
];

class _Surah {
  final int n;
  final String name;
  final int count;
  final String type;
  final String norm;
  const _Surah(this.n, this.name, this.count, this.type, this.norm);
}

String _norm(String s) {
  var t = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');
  t = t
      .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي');
  return t.trim();
}

List<dynamic>? _raw;
List<_Surah>? _surahs;

Future<void> _ensureLoaded() async {
  if (_surahs != null) return;
  final txt = await rootBundle.loadString('assets/data/quran_uthmani.json');
  final m = jsonDecode(txt) as Map<String, dynamic>;
  final list = (m['data'] as Map<String, dynamic>)['surahs'] as List<dynamic>;
  final out = <_Surah>[];
  for (final s in list) {
    final sm = s as Map<String, dynamic>;
    final n = (sm['number'] as num).toInt();
    var name = (sm['name'] ?? '').toString();
    name = name
        .replaceFirst(RegExp(r'^\s*سُورَةُ\s*'), '')
        .replaceFirst(RegExp(r'^\s*سورة\s*'), '');
    final ayahs = sm['ayahs'] as List<dynamic>;
    final type = (sm['revelationType'] ?? '').toString() == 'Medinan'
        ? 'مدنية'
        : 'مكية';
    out.add(_Surah(n, name, ayahs.length, type, _norm(name)));
  }
  _raw = list;
  _surahs = out;
}

class QuranHome extends StatefulWidget {
  const QuranHome({Key? key}) : super(key: key);

  @override
  State<QuranHome> createState() => _QuranHomeState();
}

class _QuranHomeState extends State<QuranHome> {
  List<_Surah> surahs = [];
  String verseText = '';
  String verseRef = '';
  int verseSurah = 1;
  int? lastPage;
  bool khActive = false;
  int khRead = 0;
  bool loading = true;
  String query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _ensureLoaded();
    } catch (_) {}
    int? lp;
    try {
      lp = await getLastPage();
    } catch (_) {}
    var active = false;
    var read = 0;
    try {
      final p = await SharedPreferences.getInstance();
      active = p.getBool('kh_active') ?? false;
      final l = p.getStringList('kh_read');
      read = l?.length ?? 0;
    } catch (_) {}
    var vt = '';
    var vr = '';
    var vs = 1;
    try {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day)
          .difference(DateTime(2024, 1, 1))
          .inDays;
      final r = _verseRefs[day % _verseRefs.length];
      final raw = _raw;
      if (raw != null) {
        final sm = raw[r[0] - 1] as Map<String, dynamic>;
        for (final a in (sm['ayahs'] as List<dynamic>)) {
          final am = a as Map<String, dynamic>;
          if (am['numberInSurah'] == r[1]) {
            vt = am['text'].toString();
            var nm = (sm['name'] ?? '').toString();
            nm = nm
                .replaceFirst(RegExp(r'^\s*سُورَةُ\s*'), '')
                .replaceFirst(RegExp(r'^\s*سورة\s*'), '');
            vr = '$nm - ${r[1]}';
            vs = r[0];
            break;
          }
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      surahs = _surahs ?? [];
      lastPage = lp;
      khActive = active;
      khRead = read;
      verseText = vt;
      verseRef = vr;
      verseSurah = vs;
      loading = false;
    });
  }

  Future<void> _go(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (mounted) _load();
  }

  void _open(int page) => _go(MushafReader(startPage: page));

  Widget _verseCard() {
    if (verseText.isEmpty) return const SizedBox.shrink();
    return RfCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: kGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'آية اليوم',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            verseText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22,
              height: 2.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            verseRef,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () => Share.share('$verseText\n\n($verseRef)'),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('مشاركة'),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: '$verseText\n\n($verseRef)'),
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم النسخ')),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('نسخ'),
              ),
              TextButton.icon(
                onPressed: () => _open(_pageOf(verseSurah)),
                icon: const Icon(Icons.menu_book, size: 18),
                label: const Text('فتح السورة'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _continueCard() {
    final p = lastPage;
    final raw = p == null ? 0.0 : p / 604;
    final prog = raw < 0 ? 0.0 : (raw > 1 ? 1.0 : raw);
    return RfCard(
      onTap: () => _open(p ?? 1),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_stories, color: kGreen, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مواصلة القراءة',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  p == null
                      ? 'ابدأ من أول المصحف'
                      : 'آخر صفحة قرأتها: $p من 604',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: prog,
                    minHeight: 6,
                    color: kGreen,
                    backgroundColor: kGreen.withOpacity(0.18),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_left, color: kGreen),
        ],
      ),
    );
  }

  Widget _khatmaCard() {
    final raw = khRead / 604;
    final prog = raw < 0 ? 0.0 : (raw > 1 ? 1.0 : raw);
    return RfCard(
      onTap: () => _go(const KhatmaScreen()),
      gradient: const LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [Color(0xFF0B3B36), Color(0xFF17604F)],
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  khActive ? 'ختمتي' : 'ابدأ ختمة جديدة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  khActive
                      ? 'قرأت $khRead صفحة من 604'
                      : 'حدد مدتها ويحسب لك وردك اليومي',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (khActive) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: prog,
                      minHeight: 6,
                      color: rfLime,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_left, color: Colors.white),
        ],
      ),
    );
  }

  Widget _juzGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          for (var j = 1; j <= 30; j++)
            Material(
              color: kCardBackground,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _open(_juzPage(j)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$j',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kGreen,
                      ),
                    ),
                    const Text('جزء', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        onChanged: (v) => setState(() => query = v),
        decoration: InputDecoration(
          hintText: 'ابحث باسم السورة أو رقمها',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: kCardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  List<Widget> _rows() {
    final q = _norm(query);
    final out = <Widget>[];
    for (final s in surahs) {
      if (q.isNotEmpty && !s.norm.contains(q) && '${s.n}' != q) continue;
      out.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Material(
            color: kCardBackground,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _open(_pageOf(s.n)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: kGreen.withOpacity(0.15),
                      child: Text(
                        '${s.n}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: kGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: const TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${s.type} • ${s.count} آية',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'ص ${_pageOf(s.n)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (out.isEmpty && !loading) {
      out.add(
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('لا توجد نتائج')),
        ),
      );
    }
    return out;
  }

  Widget _indexTile() {
    return RfCard(
      onTap: () => _go(
        Scaffold(
          appBar: AppBar(title: const Text('الفهرس ونقاط الحفظ')),
          body: const QuranScreen(),
        ),
      ),
      child: Row(
        children: const [
          Icon(Icons.bookmarks_outlined, color: kGreen),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'الفهرس الكامل ونقاط الحفظ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Icon(Icons.chevron_left, color: kGreen),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        RfPageHeader(
          title: 'القرآن الكريم',
          subtitle: 'نور لقلبك .. وراحة لروحك',
          trailing: IconButton(
            icon: const Icon(Icons.brightness_6, color: Colors.white),
            onPressed: ThemeController.toggle,
          ),
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _verseCard(),
          _continueCard(),
          _khatmaCard(),
          const RfSection('أجزاء القرآن', icon: Icons.layers),
          _juzGrid(),
          const RfSection('السور', icon: Icons.menu_book),
          _search(),
          ..._rows(),
          const SizedBox(height: 8),
          _indexTile(),
        ],
      ],
    );
  }
}
