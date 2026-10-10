import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'rf_design.dart';

class HadithBook {
  final String id;
  final String title;
  final String author;
  final String death;
  final String tag;
  final String summary;
  final String about;
  final List<String> points;
  final String tip;
  final bool graded;
  final Color color;
  const HadithBook({
    required this.id,
    required this.title,
    required this.author,
    required this.death,
    required this.tag,
    required this.summary,
    required this.about,
    required this.points,
    required this.tip,
    required this.graded,
    required this.color,
  });
}

const List<HadithBook> kHadithBooks = [
  HadithBook(
    id: 'bukhari',
    title: 'صحيح البخاري',
    author: 'الإمام محمد بن إسماعيل البخاري',
    death: 'ت 256 هـ',
    tag: 'أصحّ كتب الحديث',
    summary:
        'أول كتاب صُنّف في الأحاديث الصحيحة فقط، ويُعدّ أصحّ كتب الحديث عند جمهور العلماء.',
    about:
        'اسمه الكامل «الجامع المسند الصحيح المختصر من أمور رسول الله ﷺ وسننه وأيامه». جمعه الإمام البخاري في نحو ست عشرة سنة، وانتقى أحاديثه مما حفظ بشروط دقيقة في اتصال السند وعدالة الرواة وضبطهم.',
    points: [
      'الأحاديث المسندة المتصلة فيه صحيحة، وتلقّته الأمة بالقبول.',
      'مرتّب على الأبواب الفقهية، وفي عناوين أبوابه فقه دقيق.',
      'يكرّر الحديث في مواضع بأسانيد وألفاظ مختلفة لاستخراج الفوائد.',
      'أول حديث فيه: «إنما الأعمال بالنيات».',
    ],
    tip:
        'يُقرأ مع شرح مثل «فتح الباري» لابن حجر ليتضح معنى الحديث وفقهه.',
    graded: false,
    color: Color(0xFF0B6E4F),
  ),
  HadithBook(
    id: 'muslim',
    title: 'صحيح مسلم',
    author: 'الإمام مسلم بن الحجاج النيسابوري',
    death: 'ت 261 هـ',
    tag: 'ثاني الصحيحين',
    summary:
        'ثاني أصحّ الكتب، يمتاز بحسن ترتيبه وجمع طرق الحديث الواحد في مكان واحد.',
    about:
        'ألّفه الإمام مسلم واشترط فيه الصحة كذلك، ورتّبه ترتيباً فنياً بديعاً يجمع روايات الحديث وطرقه في موضع واحد، فيسهل عليك المقارنة بين الألفاظ. ويُسمّى هو والبخاري «الصحيحين».',
    points: [
      'أحاديثه صحيحة، وتلقّته الأمة بالقبول.',
      'ليس فيه تكرار كثير كما في البخاري.',
      'قدّم له مؤلفه بمقدمة نفيسة في علوم الحديث.',
    ],
    tip: 'من أشهر شروحه: «شرح النووي على صحيح مسلم».',
    graded: false,
    color: Color(0xFF1B5E8C),
  ),
  HadithBook(
    id: 'abudawud',
    title: 'سنن أبي داود',
    author: 'الإمام سليمان بن الأشعث السجستاني',
    death: 'ت 275 هـ',
    tag: 'عمدة في أحاديث الأحكام',
    summary:
        'جمع فيه الأحاديث التي يستدل بها الفقهاء على الأحكام، وفيه الصحيح والحسن والضعيف.',
    about:
        'ألّفه الإمام أبو داود ليكون مرجعاً في أحاديث الأحكام، فتجد فيه الحلال والحرام والعبادات والمعاملات. وقد بيّن في بعض المواضع ما في الحديث من ضعف.',
    points: [
      'يغلب عليه أحاديث الأحكام الفقهية.',
      'فيه الصحيح والحسن والضعيف، فانتبه لدرجة كل حديث.',
      'قال في رسالته لأهل مكة: ما سكتُّ عنه فهو صالح.',
    ],
    tip: 'قبل أن تستدل بحديث منه انظر درجته عند المحدّثين.',
    graded: true,
    color: Color(0xFF8A5A1F),
  ),
  HadithBook(
    id: 'tirmidhi',
    title: 'جامع الترمذي',
    author: 'الإمام محمد بن عيسى الترمذي',
    death: 'ت 279 هـ',
    tag: 'يبيّن درجة كل حديث',
    summary:
        'يبيّن الإمام درجة الحديث ويذكر أقوال الفقهاء وما في الباب من أحاديث أخرى.',
    about:
        'يُسمّى أيضاً «سنن الترمذي». يمتاز بأن مؤلفه يعلّق على الحديث بقوله: صحيح، أو حسن، أو غريب، ويذكر مذاهب الفقهاء في المسألة، فهو كتاب حديث وفقه وعلل معاً.',
    points: [
      'يحكم على كثير من أحاديثه بالصحة أو الحسن أو الغرابة.',
      'يقول «وفي الباب عن…» ليدلّك على أحاديث الباب الأخرى.',
      'يذكر اختلاف الفقهاء ومن عمل بالحديث.',
    ],
    tip: 'اقرأ حكمه على الحديث قبل الاستدلال به.',
    graded: true,
    color: Color(0xFF6A3D9A),
  ),
  HadithBook(
    id: 'nasai',
    title: 'سنن النسائي (المجتبى)',
    author: 'الإمام أحمد بن شعيب النسائي',
    death: 'ت 303 هـ',
    tag: 'قليل الضعف بعد الصحيحين',
    summary:
        'من أقل الكتب الستة ضعفاً بعد الصحيحين، ويمتاز بدقة تعليله لطرق الحديث.',
    about:
        'ألّف النسائي «السنن الكبرى» ثم اختصرها في «المجتبى» وهو المتداول اليوم باسم «سنن النسائي». كان شديداً في اختيار الرواة، ويعتني بالتنبيه على اختلاف الروايات وعلل الأحاديث.',
    points: [
      'من أقل الكتب الأربعة السنن ضعفاً.',
      'ترتيب فقهي واضح على الأبواب.',
      'يعتني ببيان علل الأحاديث واختلاف طرقها.',
    ],
    tip: 'المتداول اليوم هو «المجتبى» وهو السنن الصغرى للنسائي.',
    graded: true,
    color: Color(0xFF2E7D6B),
  ),
  HadithBook(
    id: 'ibnmajah',
    title: 'سنن ابن ماجه',
    author: 'الإمام محمد بن يزيد القزويني (ابن ماجه)',
    death: 'ت 273 هـ',
    tag: 'السادس بين الكتب الستة',
    summary:
        'أضاف على الخمسة أحاديث كثيرة، وفيه أحاديث ضعيفة تحتاج إلى مراجعة درجتها.',
    about:
        'عدّه كثير من العلماء سادس الكتب الستة، وبعضهم جعل السادس «موطأ مالك». فيه أحاديث زائدة على الكتب الخمسة، منها الصحيح والحسن والضعيف، وقليل منها شديد الضعف.',
    points: [
      'مرتب على الأبواب الفقهية، وفي أوله مقدمة في تعظيم السنة وفضل الصحابة.',
      'فيه أحاديث لم ترد في الكتب الخمسة.',
      'يحتاج القارئ إلى الانتباه لدرجة الحديث.',
    ],
    tip: 'لا تعتمد على حديث منه قبل التأكد من درجته.',
    graded: true,
    color: Color(0xFFA23B3B),
  ),
];

class _Hadith {
  final String no;
  final String text;
  final String grade;
  final String by;
  String? norm;
  _Hadith(this.no, this.text, this.grade, this.by);
}

List<_Hadith> _parseBook(String raw) {
  final list = jsonDecode(raw) as List<dynamic>;
  final out = <_Hadith>[];
  for (final e in list) {
    final r = e as List<dynamic>;
    final n = r[0];
    String no;
    if (n is num) {
      no = n == n.truncate() ? n.toInt().toString() : n.toString();
    } else {
      no = n.toString();
    }
    out.add(_Hadith(no, r[1].toString(), r[2].toString(), r[3].toString()));
  }
  return out;
}

final RegExp _tashkeel = RegExp('[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]');

String _norm(String s) {
  return s
      .replaceAll(_tashkeel, '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه');
}

String _gradeAr(String g) {
  final s = g.toLowerCase();
  if (s.isEmpty) return '';
  if (s.contains('mawdu') || s.contains('fabricat')) return 'موضوع';
  if (s.contains('daif') || s.contains("da'if") || s.contains('weak')) {
    return 'ضعيف';
  }
  if (s.contains('hasan') && s.contains('sahih')) return 'حسن صحيح';
  if (s.contains('hasan')) return 'حسن';
  if (s.contains('sahih')) return 'صحيح';
  return g;
}

String _byAr(String by) {
  final s = by.toLowerCase();
  if (s.contains('albani')) return 'الألباني';
  if (s.contains('zubair')) return 'زبير علي زئي';
  return by;
}

Color _gradeColor(String ar) {
  if (ar.contains('ضعيف') || ar.contains('موضوع')) {
    return const Color(0xFFD9534F);
  }
  if (ar.contains('حسن')) return const Color(0xFFD99A00);
  if (ar.contains('صحيح')) return kGreen;
  return Colors.grey;
}

String _latinDigits(String s) {
  return s.replaceAllMapped(
    RegExp('[\u0660-\u0669]'),
    (m) => '${m[0]!.codeUnitAt(0) - 0x0660}',
  );
}

class _BackBtn extends StatelessWidget {
  const _BackBtn({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => Navigator.maybePop(context),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.14),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class HadithBooksScreen extends StatelessWidget {
  const HadithBooksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const RfHeader(
            title: 'الكتب الستة',
            subtitle: 'أشهر دواوين السنة النبوية',
            trailing: _BackBtn(),
          ),
          RfCard(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: kGreen, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'ما هي الكتب الستة؟',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'هي ستة كتب جمع فيها العلماء أشهر ما رُوي عن النبي ﷺ: صحيح البخاري وصحيح مسلم (ويُسمّيان الصحيحين)، ثم سنن أبي داود، وجامع الترمذي، وسنن النسائي، وسنن ابن ماجه.\n\nالصحيحان أحاديثهما صحيحة. أما السنن الأربعة ففيها الصحيح والحسن والضعيف، فانتبه لدرجة الحديث عند قراءتها.',
                  style: TextStyle(fontSize: 14.5, height: 1.8),
                ),
              ],
            ),
          ),
          const RfSection('اختر الكتاب', icon: Icons.menu_book_rounded),
          for (var i = 0; i < kHadithBooks.length; i++)
            _BookCard(book: kHadithBooks[i], index: i),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final HadithBook book;
  final int index;
  const _BookCard({Key? key, required this.book, required this.index})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hint = Theme.of(context).hintColor;
    return RfCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => HadithBookScreen(book: book),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: book.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${book.author} · ${book.death}',
                  style: TextStyle(fontSize: 12, color: hint),
                ),
                const SizedBox(height: 8),
                Text(
                  book.summary,
                  style: const TextStyle(fontSize: 13.5, height: 1.6),
                ),
                const SizedBox(height: 10),
                _Tag(book.tag, book.color),
              ],
            ),
          ),
          Icon(Icons.chevron_left, color: hint),
        ],
      ),
    );
  }
}

class HadithBookScreen extends StatefulWidget {
  final HadithBook book;
  const HadithBookScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<HadithBookScreen> createState() => _HadithBookScreenState();
}

class _HadithBookScreenState extends State<HadithBookScreen> {
  List<_Hadith>? _all;
  List<_Hadith> _shown = const [];
  bool _failed = false;
  String _query = '';
  bool _onlyFav = false;
  Set<String> _favs = <String>{};
  Timer? _deb;

  String get _favKey => 'hadith_fav_${widget.book.id}';

  @override
  void initState() {
    super.initState();
    _load();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() => _favs = (p.getStringList(_favKey) ?? <String>[]).toSet());
    });
  }

  @override
  void dispose() {
    _deb?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle
          .loadString('assets/data/hadith_${widget.book.id}.json');
      final list = await compute(_parseBook, raw);
      if (!mounted) return;
      setState(() {
        _all = list;
        _shown = list;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _apply() {
    final all = _all;
    if (all == null) return;
    Iterable<_Hadith> it = all;
    if (_onlyFav) it = it.where((h) => _favs.contains(h.no));
    final q = _latinDigits(_query);
    if (q.isNotEmpty) {
      if (RegExp(r'^\d+$').hasMatch(q)) {
        it = it.where((h) => h.no == q);
      } else {
        final nq = _norm(q);
        it = it.where((h) {
          h.norm ??= _norm(h.text);
          return h.norm!.contains(nq);
        });
      }
    }
    setState(() => _shown = it.toList());
  }

  void _onQuery(String v) {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 300), () {
      _query = v.trim();
      _apply();
    });
  }

  Future<void> _toggleFav(_Hadith h) async {
    if (_favs.contains(h.no)) {
      _favs.remove(h.no);
    } else {
      _favs.add(h.no);
    }
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_favKey, _favs.toList());
    } catch (_) {}
    if (_onlyFav) {
      _apply();
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.book;
    final hint = Theme.of(context).hintColor;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: RfHeader(
              title: b.title,
              subtitle: b.author,
              trailing: const _BackBtn(),
            ),
          ),
          SliverToBoxAdapter(child: _AboutCard(book: b, count: _all?.length)),
          if (b.graded) const SliverToBoxAdapter(child: _GradeGuide()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: TextField(
                onChanged: _onQuery,
                decoration: InputDecoration(
                  hintText: 'ابحث بنص الحديث أو برقمه',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'المحفوظة فقط',
                    icon: Icon(
                      _onlyFav ? Icons.bookmark : Icons.bookmark_border,
                      color: _onlyFav ? rfGold : hint,
                    ),
                    onPressed: () {
                      _onlyFav = !_onlyFav;
                      _apply();
                    },
                  ),
                  filled: true,
                  fillColor: kCardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          if (_failed)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'تعذّر تحميل الكتاب. حدّث التطبيق وحاول مرة أخرى.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else if (_all == null)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_shown.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    _onlyFav && _query.isEmpty
                        ? 'ما عندك أحاديث محفوظة بعد'
                        : 'لا توجد نتائج',
                    style: TextStyle(color: hint),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final h = _shown[i];
                  return _HadithCard(
                    key: ValueKey('${b.id}_${h.no}_$i'),
                    h: h,
                    bookTitle: b.title,
                    fav: _favs.contains(h.no),
                    onFav: () => _toggleFav(h),
                  );
                },
                childCount: _shown.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final HadithBook book;
  final int? count;
  const _AboutCard({Key? key, required this.book, required this.count})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hint = Theme.of(context).hintColor;
    return RfCard(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories, color: kGreen, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'عن الكتاب',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              _Tag(book.death, book.color),
            ],
          ),
          if (count != null) ...[
            const SizedBox(height: 8),
            Text('عدد الأحاديث في هذه النسخة: $count',
                style: TextStyle(fontSize: 12.5, color: hint)),
          ],
          const SizedBox(height: 10),
          Text(book.about, style: const TextStyle(fontSize: 14.5, height: 1.8)),
          const SizedBox(height: 12),
          const Text(
            'ما يميّزه',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          for (final p in book.points)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(Icons.check_circle, color: kGreen, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(p, style: const TextStyle(fontSize: 14, height: 1.7)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: rfGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: rfGold, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(book.tip, style: const TextStyle(fontSize: 13.5, height: 1.7)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'مصدر النص: مشروع hadith-api المفتوح.',
            style: TextStyle(fontSize: 11.5, color: hint),
          ),
        ],
      ),
    );
  }
}

class _GradeGuide extends StatelessWidget {
  const _GradeGuide({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.balance, color: kGreen, size: 22),
              SizedBox(width: 8),
              Text(
                'ميزان الحديث',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row(kGreen, 'صحيح', 'ثبت بسند متصل عن رواة عدول ضابطين.'),
          _row(const Color(0xFFD99A00), 'حسن',
              'مقبول، لكنه أقل ضبطاً من الصحيح.'),
          _row(const Color(0xFFD9534F), 'ضعيف', 'لا يُحتج به في الأحكام.'),
          const SizedBox(height: 4),
          const Text(
            'تظهر الدرجة فوق الحديث إن وُجدت في المصدر، مع اسم من حكم عليه.',
            style: TextStyle(fontSize: 12.5, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _row(Color c, String t, String d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Tag(t, c),
          const SizedBox(width: 10),
          Expanded(child: Text(d, style: const TextStyle(fontSize: 14, height: 1.6))),
        ],
      ),
    );
  }
}

class _HadithCard extends StatefulWidget {
  final _Hadith h;
  final String bookTitle;
  final bool fav;
  final VoidCallback onFav;
  const _HadithCard({
    Key? key,
    required this.h,
    required this.bookTitle,
    required this.fav,
    required this.onFav,
  }) : super(key: key);

  @override
  State<_HadithCard> createState() => _HadithCardState();
}

class _HadithCardState extends State<_HadithCard> {
  bool _open = false;

  void _copy() {
    final h = widget.h;
    Clipboard.setData(
      ClipboardData(
        text: '${h.text}\n\n— ${widget.bookTitle}، حديث رقم ${h.no}',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الحديث'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.h;
    final g = _gradeAr(h.grade);
    final long = h.text.length > 320;
    final collapsed = long && !_open;
    final hint = Theme.of(context).hintColor;
    return RfCard(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  h.no,
                  style: const TextStyle(
                    color: kGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (g.isNotEmpty) ...[
                const SizedBox(width: 8),
                _Tag(
                  h.by.isEmpty ? g : '$g · ${_byAr(h.by)}',
                  _gradeColor(g),
                ),
              ],
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'نسخ',
                icon: Icon(Icons.copy_rounded, size: 20, color: hint),
                onPressed: _copy,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'حفظ',
                icon: Icon(
                  widget.fav ? Icons.bookmark : Icons.bookmark_border,
                  color: widget.fav ? rfGold : hint,
                ),
                onPressed: widget.onFav,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 4, left: 8),
            child: Text(
              h.text,
              maxLines: collapsed ? 7 : null,
              overflow: collapsed ? TextOverflow.ellipsis : TextOverflow.visible,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 19,
                height: 1.9,
              ),
            ),
          ),
          if (long)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => setState(() => _open = !_open),
                child: Text(_open ? 'عرض أقل' : 'عرض المزيد'),
              ),
            ),
        ],
      ),
    );
  }
}
