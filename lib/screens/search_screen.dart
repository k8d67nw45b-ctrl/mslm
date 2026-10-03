import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'hisn_detail.dart';
import 'hisn_service.dart';
import 'mushaf_reader.dart';
import 'nawawi_data.dart';
import 'nawawi_service.dart';
import 'quran_text.dart';

final RegExp _marks = RegExp(
  '[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED\u0640]',
);
final RegExp _alefs = RegExp('[\u0623\u0625\u0622\u0671]');

String normAr(String s) {
  return s
      .replaceAll(_marks, '')
      .replaceAll(_alefs, '\u0627')
      .replaceAll('\u0649', '\u064A')
      .replaceAll('\u0629', '\u0647')
      .replaceAll('\u0624', '\u0648')
      .replaceAll('\u0626', '\u064A')
      .trim();
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _c = TextEditingController();
  Timer? _deb;
  bool ready = false;
  List<AyahRef> ayahs = [];
  List<String> qn = [];
  List<HisnSection> hisn = [];
  List<String> hn = [];
  List<Hadith> hadiths = [];
  List<String> dn = [];
  List<AyahRef> rq = [];
  List<HisnSection> rh = [];
  List<Hadith> rd = [];
  String q = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _deb?.cancel();
    _c.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      ayahs = await loadAllAyahs();
      qn = [for (final a in ayahs) normAr(a.text)];
    } catch (_) {}
    try {
      hisn = await loadHisn();
      hn = [for (final s in hisn) normAr('${s.title} ${s.texts.join(' ')}')];
    } catch (_) {}
    try {
      hadiths = await loadNawawi();
      dn = [for (final h in hadiths) normAr(h.text)];
    } catch (_) {}
    if (mounted) setState(() => ready = true);
  }

  void _onChanged(String v) {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 250), () => _search(v));
  }

  void _search(String v) {
    final toks = normAr(v)
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (toks.isEmpty) {
      setState(() {
        q = '';
        rq = [];
        rh = [];
        rd = [];
      });
      return;
    }
    bool hit(String s) => toks.every((t) => s.contains(t));
    final a = <AyahRef>[];
    for (var i = 0; i < qn.length && a.length < 40; i++) {
      if (hit(qn[i])) a.add(ayahs[i]);
    }
    final h = <HisnSection>[];
    for (var i = 0; i < hn.length && h.length < 30; i++) {
      if (hit(hn[i])) h.add(hisn[i]);
    }
    final d = <Hadith>[];
    for (var i = 0; i < dn.length && d.length < 20; i++) {
      if (hit(dn[i])) d.add(hadiths[i]);
    }
    setState(() {
      q = v;
      rq = a;
      rh = h;
      rd = d;
    });
  }

  Widget _head(String t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        t,
        style: const TextStyle(
          color: kGreen,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  void _showHadith(Hadith h) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('الحديث ${h.number}'),
        content: SingleChildScrollView(
          child: SelectableText(
            h.text,
            style: const TextStyle(fontSize: 19, height: 1.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final empty = q.isNotEmpty && rq.isEmpty && rh.isEmpty && rd.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _c,
          autofocus: true,
          onChanged: _onChanged,
          decoration: const InputDecoration(
            hintText: 'ابحث في القرآن والأذكار والأحاديث',
            border: InputBorder.none,
          ),
        ),
      ),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (q.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('اكتب كلمة أو أكثر للبحث (بدون إنترنت)'),
                  ),
                if (empty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('لا توجد نتائج'),
                  ),
                if (rq.isNotEmpty) ...[
                  _head('القرآن الكريم (${rq.length})'),
                  for (final a in rq)
                    ListTile(
                      title: Text(
                        a.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, height: 1.8),
                      ),
                      subtitle: Text('${a.surahName}: ${a.ayah}'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MushafReader(startPage: a.page),
                        ),
                      ),
                    ),
                ],
                if (rh.isNotEmpty) ...[
                  _head('حصن المسلم (${rh.length})'),
                  for (final s in rh)
                    ListTile(
                      title: Text(s.title),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HisnDetail(sec: s),
                        ),
                      ),
                    ),
                ],
                if (rd.isNotEmpty) ...[
                  _head('الأربعون النووية (${rd.length})'),
                  for (final h in rd)
                    ListTile(
                      title: Text('الحديث ${h.number}'),
                      subtitle: Text(
                        h.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _showHadith(h),
                    ),
                ],
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
