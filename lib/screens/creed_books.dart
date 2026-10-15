import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class _Info {
  final String id;
  final String title;
  final String author;
  final String about;
  final String source;
  final int n;
  _Info(this.id, this.title, this.author, this.about, this.source, this.n);
}

Future<List<_Info>> _loadIndex() async {
  try {
    final s = await rootBundle.loadString('assets/data/books_index.json');
    final l = jsonDecode(s) as List;
    return [
      for (final m in l)
        _Info(
          '${m['id']}',
          '${m['title']}',
          '${m['author']}',
          '${m['about']}',
          '${m['source']}',
          (m['n'] as num?)?.toInt() ?? 0,
        ),
    ];
  } catch (_) {
    return <_Info>[];
  }
}

List<String> _parseLines(String s) {
  final m = jsonDecode(s) as Map<String, dynamic>;
  return [for (final e in (m['p'] as List)) e.toString()];
}

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

final RegExp _headRe =
    RegExp(r'^(باب|فصل|القاعدة|الأصل|الشبهة|مقدمة|كتاب)');

bool _isHeading(String l) => l.length <= 70 && _headRe.hasMatch(l.trim());

class CreedBooksScreen extends StatefulWidget {
  const CreedBooksScreen({Key? key}) : super(key: key);

  @override
  State<CreedBooksScreen> createState() => _CreedBooksScreenState();
}

class _CreedBooksScreenState extends State<CreedBooksScreen> {
  List<_Info>? items;

  @override
  void initState() {
    super.initState();
    _loadIndex().then((l) {
      if (mounted) setState(() => items = l);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = items;
    return Scaffold(
      appBar: AppBar(title: const Text('كتب العقيدة')),
      body: l == null
          ? const Center(child: CircularProgressIndicator())
          : l.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'لم تُضف نصوص الكتب في هذه النسخة بعد.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(kPaddingMedium),
                  children: [
                    for (final b in l)
                      Card(
                        color: kCardBackground,
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.all(kPaddingMedium),
                          leading: CircleAvatar(
                            backgroundColor: kGreen.withOpacity(0.18),
                            child: const Icon(Icons.menu_book, color: kGreen),
                          ),
                          title: Text(b.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('${b.author}\n${b.about}'),
                          ),
                          isThreeLine: true,
                          trailing:
                              const Icon(Icons.chevron_left, color: kGreen),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _BookReader(info: b),
                            ),
                          ),
                        ),
                      ),
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'النصوص منقولة من مصادر مفتوحة مع ذكر المصدر داخل '
                        'كل كتاب. قد تحتوي أخطاء نقل، فارجع للنسخ المطبوعة '
                        'الموثوقة عند الاستدلال.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _BookReader extends StatefulWidget {
  final _Info info;
  const _BookReader({Key? key, required this.info}) : super(key: key);

  @override
  State<_BookReader> createState() => _BookReaderState();
}

class _BookReaderState extends State<_BookReader> {
  List<String>? lines;
  bool failed = false;
  double font = 20;
  bool searching = false;
  String query = '';
  final TextEditingController ctl = TextEditingController();
  final ScrollController sc = ScrollController();

  String get _posKey => 'book_pos_${widget.info.id}';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _savePos();
    ctl.dispose();
    sc.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final p = await SharedPreferences.getInstance();
    final f = p.getDouble('book_font') ?? 20;
    try {
      final s = await rootBundle
          .loadString('assets/data/book_${widget.info.id}.json');
      final l = await compute(_parseLines, s);
      if (!mounted) return;
      setState(() {
        lines = l;
        font = f;
      });
      final pos = p.getDouble(_posKey) ?? 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (sc.hasClients && pos > 0) {
          final mx = sc.position.maxScrollExtent;
          sc.jumpTo(pos > mx ? mx : pos);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        failed = true;
        font = f;
      });
    }
  }

  Future<void> _savePos() async {
    if (!sc.hasClients || searching) return;
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_posKey, sc.offset);
  }

  Future<void> _setFont(double v) async {
    final nv = v.clamp(14.0, 34.0).toDouble();
    setState(() => font = nv);
    final p = await SharedPreferences.getInstance();
    await p.setDouble('book_font', nv);
  }

  @override
  Widget build(BuildContext context) {
    final l = lines;
    Widget body;
    if (failed) {
      body = const Center(child: Text('تعذّر فتح هذا الكتاب.'));
    } else if (l == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final q = _norm(query.trim());
      final shown = (searching && q.isNotEmpty)
          ? l.where((x) => _norm(x).contains(q)).toList()
          : l;
      body = Column(
        children: [
          if (searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: ctl,
                autofocus: true,
                onChanged: (v) => setState(() => query = v),
                decoration: const InputDecoration(
                  hintText: 'ابحث داخل الكتاب',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          Expanded(
            child: shown.isEmpty
                ? const Center(child: Text('لا توجد نتائج'))
                : NotificationListener<ScrollEndNotification>(
                    onNotification: (_) {
                      _savePos();
                      return false;
                    },
                    child: ListView.builder(
                      controller: sc,
                      padding: const EdgeInsets.all(kPaddingMedium),
                      itemCount: shown.length + 1,
                      itemBuilder: (_, i) {
                        if (i == shown.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              '${widget.info.author}\n${widget.info.source}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          );
                        }
                        final t = shown[i];
                        if (_isHeading(t)) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 6),
                            child: SelectableText(
                              t,
                              style: TextStyle(
                                fontSize: font + 2,
                                fontWeight: FontWeight.bold,
                                color: kGreen,
                                height: 1.7,
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: SelectableText(
                            t,
                            textAlign: TextAlign.justify,
                            style: TextStyle(fontSize: font, height: 1.9),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.info.title, style: const TextStyle(fontSize: 17)),
        actions: [
          IconButton(
            tooltip: 'تصغير الخط',
            icon: const Icon(Icons.text_decrease),
            onPressed: () => _setFont(font - 2),
          ),
          IconButton(
            tooltip: 'تكبير الخط',
            icon: const Icon(Icons.text_increase),
            onPressed: () => _setFont(font + 2),
          ),
          IconButton(
            tooltip: 'بحث',
            icon: Icon(searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              searching = !searching;
              if (!searching) {
                query = '';
                ctl.clear();
              }
            }),
          ),
        ],
      ),
      body: body,
    );
  }
}
