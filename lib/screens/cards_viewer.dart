import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class CardItem {
  final String text;
  final int count;
  final String source;
  const CardItem(this.text, this.count, {this.source = ''});
}

class AdhkarCards extends StatefulWidget {
  final String title;
  final String Function(int) keyOf;
  final List<CardItem> items;
  const AdhkarCards({
    Key? key,
    required this.title,
    required this.keyOf,
    required this.items,
  }) : super(key: key);

  @override
  State<AdhkarCards> createState() => _AdhkarCardsState();
}

class _AdhkarCardsState extends State<AdhkarCards> {
  static const _sizes = [18.0, 21.0, 24.0, 28.0];
  final PageController _pc = PageController();
  late List<int> counts;
  int index = 0;
  bool auto = true;
  int fontIdx = 1;
  bool? darkPref;
  Set<String> favs = {};

  @override
  void initState() {
    super.initState();
    counts = List.filled(widget.items.length, 0);
    _load();
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    final f = p.getInt('cards_font') ?? 1;
    setState(() {
      counts = List.generate(
        widget.items.length,
        (i) => p.getInt(widget.keyOf(i)) ?? 0,
      );
      auto = p.getBool('cards_auto') ?? true;
      fontIdx = (f < 0 || f > 3) ? 1 : f;
      darkPref = p.getBool('cards_dark');
      favs = (p.getStringList('adhkar_favs') ?? []).toSet();
    });
  }

  Future<void> _reloadFavs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => favs = (p.getStringList('adhkar_favs') ?? []).toSet());
  }

  Future<void> _setBool(String k, bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(k, v);
  }

  Future<void> _saveFont() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('cards_font', fontIdx);
  }

  void _next() {
    if (!mounted) return;
    if (index < widget.items.length - 1) {
      _pc.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _tap(int i) async {
    final max = widget.items[i].count;
    if (counts[i] >= max) {
      if (auto) _next();
      return;
    }
    setState(() => counts[i]++);
    final p = await SharedPreferences.getInstance();
    await p.setInt(widget.keyOf(i), counts[i]);
    if (counts[i] >= max) {
      HapticFeedback.mediumImpact();
      if (auto) {
        await Future.delayed(const Duration(milliseconds: 350));
        if (index == i) _next();
      }
    } else {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _fav(String text) async {
    setState(() {
      if (!favs.add(text)) favs.remove(text);
    });
    final p = await SharedPreferences.getInstance();
    await p.setStringList('adhkar_favs', favs.toList());
  }

  void _source(CardItem it) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Text(
              it.source,
              style: const TextStyle(fontSize: 16, height: 1.9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ghost(bool dark) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF223033) : const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(28),
      ),
    );
  }

  Widget _card(int i, bool dark) {
    final it = widget.items[i];
    final c = counts[i];
    final done = c >= it.count;
    final cardColor = dark ? const Color(0xFF1A2325) : const Color(0xFFFAFAFA);
    final ink = dark ? Colors.white : const Color(0xFF263238);
    final accent = dark ? kGreen : const Color(0xFF005C42);
    final pv = (c / it.count).clamp(0.0, 1.0).toDouble();
    final isFav = favs.contains(it.text);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 6),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 26,
            right: 26,
            bottom: 0,
            height: 70,
            child: _ghost(dark),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            height: 70,
            child: _ghost(dark),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Material(
              color: cardColor,
              elevation: 6,
              borderRadius: BorderRadius.circular(32),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _tap(i),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB6F36B),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(
                          '${i + 1}/${widget.items.length}',
                          style: const TextStyle(
                            color: Color(0xFF005C42),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Text(
                              it.text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: _sizes[fontIdx],
                                height: 1.9,
                                color: ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: accent, width: 1.5),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          done ? 'تم ✓' : '$c من ${it.count} مرات',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pv,
                          minHeight: 6,
                          color: kGreen,
                          backgroundColor: kGreen.withOpacity(0.25),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (it.source.isNotEmpty)
                            ActionChip(
                              avatar: Icon(
                                Icons.verified,
                                size: 18,
                                color: accent,
                              ),
                              label: const Text('المصدر'),
                              onPressed: () => _source(it),
                            ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.share_outlined, color: accent),
                            onPressed: () => Share.share(it.text),
                          ),
                          IconButton(
                            icon: Icon(
                              isFav ? Icons.bookmark : Icons.bookmark_border,
                              color: accent,
                            ),
                            onPressed: () => _fav(it.text),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _top(Color ink) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: [
                    Icon(Icons.chevron_right, color: ink, size: 34),
                    Text('رجوع', style: TextStyle(color: ink, fontSize: 18)),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.bookmarks_outlined, color: ink),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                ).then((_) => _reloadFavs()),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              widget.title,
              style: TextStyle(
                color: ink,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottom(bool dark, Color ink) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              dark ? Icons.light_mode : Icons.dark_mode,
              color: ink,
              size: 28,
            ),
            onPressed: () {
              setState(() => darkPref = !dark);
              _setBool('cards_dark', !dark);
            },
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              setState(() => auto = !auto);
              _setBool('cards_auto', auto);
            },
            child: Row(
              children: [
                Icon(
                  auto ? Icons.check_box : Icons.check_box_outline_blank,
                  color: ink,
                ),
                const SizedBox(width: 6),
                Text(
                  'الانتقال التلقائي',
                  style: TextStyle(color: ink, fontSize: 16),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() => fontIdx = (fontIdx + 1) % _sizes.length);
              _saveFont();
            },
            child: Text(
              'AA',
              style: TextStyle(
                color: ink,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = darkPref ?? (Theme.of(context).brightness == Brightness.dark);
    final ink = dark ? Colors.white : const Color(0xFF005C42);
    final n = widget.items.length;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const [Color(0xFF0B2A23), Color(0xFF0F1419)]
                : const [Color(0xFFDCEBEA), Color(0xFFF2D9A8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _top(ink),
              Expanded(
                child: n == 0
                    ? const Center(child: Text('لا توجد أذكار'))
                    : PageView.builder(
                        scrollDirection: Axis.vertical,
                        controller: _pc,
                        itemCount: n,
                        onPageChanged: (i) => index = i,
                        itemBuilder: (c, i) => _card(i, dark),
                      ),
              ),
              _bottom(dark, ink),
            ],
          ),
        ),
      ),
    );
  }
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<String>? items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => items = p.getStringList('adhkar_favs') ?? []);
    }
  }

  Future<void> _remove(String t) async {
    final p = await SharedPreferences.getInstance();
    final l = p.getStringList('adhkar_favs') ?? [];
    l.remove(t);
    await p.setStringList('adhkar_favs', l);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (items == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (items!.isEmpty) {
      body = const Center(child: Text('لا توجد أذكار محفوظة'));
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.all(kPaddingMedium),
        itemCount: items!.length,
        itemBuilder: (context, i) {
          final t = items![i];
          return Card(
            color: kCardBackground,
            margin: const EdgeInsets.only(bottom: kPaddingMedium),
            child: Padding(
              padding: const EdgeInsets.all(kPaddingMedium),
              child: Column(
                children: [
                  Text(t, style: const TextStyle(fontSize: 19, height: 1.9)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: t));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم النسخ')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _remove(t),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('الأذكار المحفوظة')),
      body: body,
    );
  }
}
