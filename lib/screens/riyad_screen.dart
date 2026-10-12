import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../core/constants.dart';

const String _favKey = 'riyad_fav';

class _H {
  final int num;
  final int ch;
  final String text;
  final String norm;
  _H(this.num, this.ch, this.text, this.norm);
}

class _Book {
  final List<int> order;
  final Map<int, String> titles;
  final Map<int, List<_H>> byChapter;
  final List<_H> all;
  _Book(this.order, this.titles, this.byChapter, this.all);
}

Map<String, dynamic> _parse(String s) =>
    jsonDecode(s) as Map<String, dynamic>;

String _norm(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    if ((r >= 0x064B && r <= 0x0652) || r == 0x0670 || r == 0x0640) continue;
    switch (r) {
      case 0x0623:
      case 0x0625:
      case 0x0622:
        b.writeCharCode(0x0627);
        break;
      case 0x0649:
        b.writeCharCode(0x064A);
        break;
      case 0x0629:
        b.writeCharCode(0x0647);
        break;
      default:
        b.writeCharCode(r);
    }
  }
  return b.toString();
}

int _asInt(dynamic v) {
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

Future<_Book> _loadBook() async {
  final s = await rootBundle.loadString('assets/data/riyad.json');
  final m = await compute(_parse, s);
  final titles = <int, String>{};
  final order = <int>[];
  for (final c in (m['c'] as List? ?? [])) {
    final l = c as List;
    final id = _asInt(l[0]);
    titles[id] = (l[1] ?? '').toString();
    order.add(id);
  }
  final all = <_H>[];
  final by = <int, List<_H>>{};
  for (final h in (m['h'] as List)) {
    final l = h as List;
    final t = (l[2] ?? '').toString();
    final item = _H(_asInt(l[0]), _asInt(l[1]), t, _norm(t));
    all.add(item);
    by.putIfAbsent(item.ch, () => []).add(item);
    if (!titles.containsKey(item.ch)) {
      titles[item.ch] = 'الباب ${item.ch}';
      order.add(item.ch);
    }
  }
  return _Book(order, titles, by, all);
}

Future<Set<String>> _loadFavs() async {
  final p = await SharedPreferences.getInstance();
  return (p.getStringList(_favKey) ?? <String>[]).toSet();
}

Future<void> _saveFavs(Set<String> f) async {
  final p = await SharedPreferences.getInstance();
  await p.setStringList(_favKey, f.toList());
}

class _HadithCard extends StatelessWidget {
  final _H h;
  final bool fav;
  final VoidCallback onFav;
  const _HadithCard({
    Key? key,
    required this.h,
    required this.fav,
    required this.onFav,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCardBackground,
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('حديث ${h.num}',
                      style: const TextStyle(fontSize: 12)),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'نسخ',
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                        text: '${h.text}\n\n— رياض الصالحين، حديث رقم ${h.num}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم النسخ')),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'المفضلة',
                  icon: Icon(
                    fav ? Icons.bookmark : Icons.bookmark_border,
                    color: fav ? kGreen : null,
                    size: 22,
                  ),
                  onPressed: onFav,
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              h.text,
              style: const TextStyle(fontSize: 17, height: 1.9),
            ),
          ],
        ),
      ),
    );
  }
}

class RiyadScreen extends StatefulWidget {
  const RiyadScreen({Key? key}) : super(key: key);

  @override
  State<RiyadScreen> createState() => _RiyadScreenState();
}

class _RiyadScreenState extends State<RiyadScreen> {
  _Book? book;
  bool failed = false;
  Set<String> favs = {};
  String query = '';
  bool onlyFav = false;
  final TextEditingController ctl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final f = await _loadFavs();
    try {
      final b = await _loadBook();
      if (!mounted) return;
      setState(() {
        book = b;
        favs = f;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        failed = true;
        favs = f;
      });
    }
  }

  Future<void> _toggle(int n) async {
    final k = '$n';
    setState(() {
      if (!favs.remove(k)) favs.add(k);
    });
    await _saveFavs(favs);
  }

  List<_H> _results(_Book b) {
    final q = _norm(query.trim());
    Iterable<_H> src = b.all;
    if (onlyFav) src = src.where((h) => favs.contains('${h.num}'));
    if (q.isEmpty) return src.toList();
    final asNum = int.tryParse(q);
    if (asNum != null) return src.where((h) => h.num == asNum).toList();
    return src.where((h) => h.norm.contains(q)).take(150).toList();
  }

  @override
  Widget build(BuildContext context) {
    final b = book;
    Widget body;
    if (failed) {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'هذا الكتاب غير متوفر في هذه النسخة.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (b == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final searching = query.trim().isNotEmpty || onlyFav;
      final res = searching ? _results(b) : const <_H>[];
      body = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: ctl,
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: 'ابحث بنص الحديث أو برقمه',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ctl.clear();
                          setState(() => query = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: searching
                ? (res.isEmpty
                    ? const Center(child: Text('لا توجد نتائج'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(kPaddingMedium),
                        itemCount: res.length,
                        itemBuilder: (_, i) => _HadithCard(
                          h: res[i],
                          fav: favs.contains('${res[i].num}'),
                          onFav: () => _toggle(res[i].num),
                        ),
                      ))
                : ListView.builder(
                    padding: const EdgeInsets.all(kPaddingMedium),
                    itemCount: b.order.length + 1,
                    itemBuilder: (_, i) {
                      if (i == b.order.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'رياض الصالحين للإمام النووي. نسخة تجريبية، '
                            'والنص من مشروع hadith-json المفتوح.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        );
                      }
                      final id = b.order[i];
                      final n = (b.byChapter[id] ?? const <_H>[]).length;
                      return Card(
                        color: kCardBackground,
                        child: ListTile(
                          title: Text(b.titles[id] ?? 'الباب $id'),
                          subtitle: Text('$n حديث'),
                          trailing:
                              const Icon(Icons.chevron_left, color: kGreen),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _ChapterScreen(
                                  title: b.titles[id] ?? 'الباب $id',
                                  items: b.byChapter[id] ?? const <_H>[],
                                ),
                              ),
                            );
                            final f = await _loadFavs();
                            if (mounted) setState(() => favs = f);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('رياض الصالحين'),
        actions: [
          IconButton(
            tooltip: 'المفضلة',
            icon: Icon(onlyFav ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () => setState(() => onlyFav = !onlyFav),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _ChapterScreen extends StatefulWidget {
  final String title;
  final List<_H> items;
  const _ChapterScreen({Key? key, required this.title, required this.items})
      : super(key: key);

  @override
  State<_ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<_ChapterScreen> {
  Set<String> favs = {};

  @override
  void initState() {
    super.initState();
    _loadFavs().then((f) {
      if (mounted) setState(() => favs = f);
    });
  }

  Future<void> _toggle(int n) async {
    final k = '$n';
    setState(() {
      if (!favs.remove(k)) favs.add(k);
    });
    await _saveFavs(favs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title, style: const TextStyle(fontSize: 16))),
      body: widget.items.isEmpty
          ? const Center(child: Text('لا توجد أحاديث'))
          : ListView.builder(
              padding: const EdgeInsets.all(kPaddingMedium),
              itemCount: widget.items.length,
              itemBuilder: (_, i) => _HadithCard(
                h: widget.items[i],
                fav: favs.contains('${widget.items[i].num}'),
                onFav: () => _toggle(widget.items[i].num),
              ),
            ),
    );
  }
}
