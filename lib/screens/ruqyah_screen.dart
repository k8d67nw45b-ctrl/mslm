import 'package:flutter/material.dart';
import 'cards_viewer.dart';
import 'quran_text.dart';

class RuqyahScreen extends StatefulWidget {
  const RuqyahScreen({Key? key}) : super(key: key);

  @override
  State<RuqyahScreen> createState() => _RuqyahScreenState();
}

class _RuqyahScreenState extends State<RuqyahScreen> {
  late final Future<List<CardItem>> f = _build();

  Future<List<CardItem>> _build() async {
    final all = await loadAllAyahs();
    CardItem make(int s, int from, int to, int count) {
      final part = all
          .where((a) => a.surah == s && a.ayah >= from && a.ayah <= to)
          .toList();
      final text = part.map((a) => '${a.text} ﴿${a.ayah}﴾').join(' ');
      final name = part.isEmpty ? '' : part.first.surahName;
      final range = from == to ? 'الآية $from' : 'الآيات $from-$to';
      return CardItem(text, count, source: 'القرآن الكريم: $name، $range');
    }

    return [
      make(1, 1, 7, 1),
      make(2, 255, 255, 1),
      make(2, 285, 286, 1),
      make(112, 1, 4, 3),
      make(113, 1, 5, 3),
      make(114, 1, 6, 3),
    ];
  }

  String _key(int i) {
    final n = DateTime.now();
    return 'ruqyah_${n.year}-${n.month}-${n.day}_$i';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CardItem>>(
      future: f,
      builder: (c, s) {
        if (s.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('${s.error}')),
          );
        }
        if (!s.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return AdhkarCards(
          title: 'الرقية الشرعية',
          keyOf: _key,
          items: s.data!,
        );
      },
    );
  }
}
