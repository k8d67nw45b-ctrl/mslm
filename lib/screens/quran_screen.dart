import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'bookmarks.dart';
import 'mushaf_reader.dart';
import 'mushaf_service.dart';
import 'quran_text.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({Key? key}) : super(key: key);

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  List<SurahItem>? surahs;
  String? error;
  int? last;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => error = null);
    try {
      final s = await loadSurahItems();
      final l = await getLastPage();
      if (!mounted) return;
      setState(() {
        surahs = s;
        last = l;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> _open(int page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MushafReader(startPage: page),
      ),
    );
    final l = await getLastPage();
    if (mounted) setState(() => last = l);
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!),
            const SizedBox(height: kPaddingMedium),
            ElevatedButton(
              onPressed: _load,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    if (surahs == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final list = surahs!;
    final head = <Widget>[
      Card(
        color: kCardBackground,
        margin: const EdgeInsets.only(bottom: kPaddingMedium),
        child: ListTile(
          leading: const Icon(Icons.bookmarks, color: kGreen),
          title: const Text('نقاط الحفظ'),
          trailing: const Icon(Icons.chevron_left, color: kGreen),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookmarksScreen()),
          ),
        ),
      ),
      if (last != null)
        Card(
          color: kGreen,
          margin: const EdgeInsets.only(bottom: kPaddingMedium),
          child: ListTile(
            title: Text('متابعة القراءة: صفحة $last'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _open(last!),
          ),
        ),
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(kPaddingMedium),
      itemCount: head.length + list.length,
      itemBuilder: (context, i) {
        if (i < head.length) return head[i];
        final s = list[i - head.length];
        return Card(
          color: kCardBackground,
          margin: const EdgeInsets.only(bottom: kPaddingSmall),
          child: ListTile(
            leading: Text(
              '${s.number}',
              style: const TextStyle(color: kGreen, fontSize: 18),
            ),
            title: Text(s.name, style: const TextStyle(fontSize: 20)),
            subtitle: Text('${s.ayahs} آية، صفحة ${s.page}'),
            onTap: () => _open(s.page),
          ),
        );
      },
    );
  }
}
