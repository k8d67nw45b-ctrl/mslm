import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class AdhkarItem {
  final String text;
  final int count;
  final String fadl;
  final int type;
  const AdhkarItem(this.text, this.count, this.fadl, this.type);
}

List<AdhkarItem>? _cache;

Future<List<AdhkarItem>> _loadAll() async {
  if (_cache != null) return _cache!;
  final raw = await rootBundle.loadString('assets/data/adhkar_ar.json');
  final d = jsonDecode(raw);
  List items;
  if (d is List) {
    items = d;
  } else if (d is Map) {
    final lists = d.values.where((v) => v is List).toList();
    items = lists.isNotEmpty ? lists.first as List : d.values.toList();
  } else {
    throw 'تعذّر قراءة بيانات الأذكار';
  }
  final out = <AdhkarItem>[];
  for (final m in items) {
    if (m is! Map) continue;
    final text = '${m['content'] ?? ''}'.trim();
    if (text.isEmpty) continue;
    final c = int.tryParse('${m['count'] ?? 1}') ?? 1;
    out.add(AdhkarItem(
      text,
      c < 1 ? 1 : c,
      '${m['fadl'] ?? ''}'.trim(),
      int.tryParse('${m['type'] ?? 0}') ?? 0,
    ));
  }
  if (out.isEmpty) throw 'تعذّر قراءة بيانات الأذكار';
  _cache = out;
  return out;
}

Future<List<AdhkarItem>> loadAdhkar(bool morning) async {
  final all = await _loadAll();
  return all
      .where((a) => a.type == 0 || a.type == (morning ? 1 : 2))
      .toList();
}

String adhkarKey(bool morning, int i) {
  final n = DateTime.now();
  final tag = morning ? 'm' : 'e';
  return 'dadhkar_${tag}_${n.year}-${n.month}-${n.day}_$i';
}

Future<double?> todayAdhkarProgress() async {
  try {
    final morning = DateTime.now().hour < 12;
    final list = await loadAdhkar(morning);
    final p = await SharedPreferences.getInstance();
    var total = 0;
    var done = 0;
    for (var i = 0; i < list.length; i++) {
      total += list[i].count;
      final c = p.getInt(adhkarKey(morning, i)) ?? 0;
      done += c > list[i].count ? list[i].count : c;
    }
    return total == 0 ? 0.0 : done / total;
  } catch (_) {
    return null;
  }
}
