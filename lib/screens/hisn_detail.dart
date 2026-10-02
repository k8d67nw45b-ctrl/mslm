import 'package:flutter/material.dart';
import 'cards_viewer.dart';
import 'hisn_service.dart';

class HisnDetail extends StatelessWidget {
  final HisnSection sec;
  const HisnDetail({Key? key, required this.sec}) : super(key: key);

  String _key(int i) {
    final n = DateTime.now();
    return 'hisn_${n.year}-${n.month}-${n.day}_${sec.title}_$i';
  }

  @override
  Widget build(BuildContext context) {
    final src = sec.notes.join('\n\n');
    return AdhkarCards(
      title: sec.title,
      keyOf: _key,
      items: [
        for (final t in sec.texts) CardItem(t, countOf(t), source: src),
      ],
    );
  }
}
