import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mushaf_reader.dart';
import 'quran_text.dart';

class Bookmark {
  final int surah;
  final String name;
  final int ayah;
  final int page;
  Bookmark(this.surah, this.name, this.ayah, this.page);

  Map<String, dynamic> toJson() =>
      {'s': surah, 'n': name, 'a': ayah, 'p': page};

  factory Bookmark.fromJson(Map<String, dynamic> j) => Bookmark(
        j['s'] as int,
        j['n'] as String,
        j['a'] as int,
        j['p'] as int,
      );
}

Future<List<Bookmark>> loadBookmarks() async {
  final p = await SharedPreferences.getInstance();
  final raw = p.getStringList('bookmarks') ?? [];
  return raw
      .map((e) => Bookmark.fromJson(jsonDecode(e) as Map<String, dynamic>))
      .toList();
}

Future<void> _save(List<Bookmark> l) async {
  final p = await SharedPreferences.getInstance();
  await p.setStringList(
    'bookmarks',
    l.map((b) => jsonEncode(b.toJson())).toList(),
  );
}

Future<bool> toggleBookmark(AyahRef a) async {
  final l = await loadBookmarks();
  final i = l.indexWhere((b) => b.surah == a.surah && b.ayah == a.ayah);
  if (i >= 0) {
    l.removeAt(i);
    await _save(l);
    return false;
  }
  l.insert(0, Bookmark(a.surah, a.surahName, a.ayah, a.page));
  await _save(l);
  return true;
}

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Bookmark>? items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await loadBookmarks();
    if (mounted) setState(() => items = l);
  }

  Future<void> _remove(Bookmark b) async {
    final l = await loadBookmarks();
    l.removeWhere((x) => x.surah == b.surah && x.ayah == b.ayah);
    await _save(l);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (items == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (items!.isEmpty) {
      body = const Center(child: Text('ما عندك نقاط حفظ بعد'));
    } else {
      body = ListView.builder(
        itemCount: items!.length,
        itemBuilder: (context, i) {
          final b = items![i];
          return ListTile(
            title: Text('${b.name}: آية ${b.ayah}'),
            subtitle: Text('صفحة ${b.page}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _remove(b),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MushafReader(startPage: b.page),
              ),
            ),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('نقاط الحفظ')),
      body: body,
    );
  }
}
