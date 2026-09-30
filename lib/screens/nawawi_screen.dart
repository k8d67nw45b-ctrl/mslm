import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'nawawi_data.dart';

class NawawiScreen extends StatefulWidget {
  const NawawiScreen({Key? key}) : super(key: key);

  @override
  State<NawawiScreen> createState() => _NawawiScreenState();
}

class _NawawiScreenState extends State<NawawiScreen> {
  String query = '';
  bool onlyFav = false;
  Set<String> favs = {};

  @override
  void initState() {
    super.initState();
    _loadFavs();
  }

  Future<void> _loadFavs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => favs = (prefs.getStringList('nawawi_favs') ?? []).toSet());
  }

  Future<void> _toggle(int n) async {
    final k = n.toString();
    setState(() {
      if (favs.contains(k)) {
        favs.remove(k);
      } else {
        favs.add(k);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('nawawi_favs', favs.toList());
  }

  List<Hadith> get _filtered {
    return nawawiList.where((h) {
      if (onlyFav && !favs.contains(h.number.toString())) return false;
      if (query.isEmpty) return true;
      return h.text.contains(query) ||
          h.narrator.contains(query) ||
          h.benefit.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأربعون النووية'),
        actions: [
          IconButton(
            icon: Icon(onlyFav ? Icons.favorite : Icons.favorite_border),
            onPressed: () => setState(() => onlyFav = !onlyFav),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(kPaddingMedium),
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                hintText: 'ابحث في الأحاديث',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium),
              itemCount: items.length,
              itemBuilder: (context, i) => _card(items[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Hadith h) {
    final isFav = favs.contains(h.number.toString());
    return Card(
      color: kCardBackground,
      margin: const EdgeInsets.only(bottom: kPaddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الحديث ${h.number}',
              style: const TextStyle(
                color: kGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: kPaddingSmall),
            Text(h.text, style: const TextStyle(fontSize: 19, height: 1.8)),
            const SizedBox(height: kPaddingSmall),
            Text('الراوي: ${h.narrator}'),
            const SizedBox(height: kPaddingSmall),
            Text('الفائدة: ${h.benefit}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: kGreen,
                  ),
                  onPressed: () => _toggle(h.number),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: '${h.text}\n(${h.narrator})'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم النسخ')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
