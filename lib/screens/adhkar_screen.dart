import 'package:flutter/material.dart';
import 'cards_viewer.dart';
import 'daily_adhkar.dart';

class DailyAdhkarScreen extends StatefulWidget {
  final bool morning;
  const DailyAdhkarScreen({Key? key, required this.morning})
      : super(key: key);

  @override
  State<DailyAdhkarScreen> createState() => _DailyAdhkarScreenState();
}

class _DailyAdhkarScreenState extends State<DailyAdhkarScreen> {
  late final Future<List<AdhkarItem>> f = loadAdhkar(widget.morning);

  String _src(AdhkarItem a) {
    final parts = <String>[];
    if (a.source.isNotEmpty) parts.add(a.source);
    if (a.fadl.isNotEmpty) parts.add('الفضل: ${a.fadl}');
    return parts.join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdhkarItem>>(
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
          title: widget.morning ? 'أذكار الصباح' : 'أذكار المساء',
          keyOf: (i) => adhkarKey(widget.morning, i),
          items: [
            for (final a in s.data!) CardItem(a.text, a.count, source: _src(a)),
          ],
        );
      },
    );
  }
}
