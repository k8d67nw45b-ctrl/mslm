import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'ayah_audio.dart';
import 'bookmarks.dart';
import 'quran_text.dart';
import 'share_ayah.dart';
import 'tafsir_screen.dart';

void showPageAyahs(BuildContext context, int page) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (ctx, controller) => _PageAyahs(
        page: page,
        controller: controller,
        outer: context,
      ),
    ),
  );
}

class _PageAyahs extends StatefulWidget {
  final int page;
  final ScrollController controller;
  final BuildContext outer;
  const _PageAyahs({
    Key? key,
    required this.page,
    required this.controller,
    required this.outer,
  }) : super(key: key);

  @override
  State<_PageAyahs> createState() => _PageAyahsState();
}

class _PageAyahsState extends State<_PageAyahs> {
  late final Future<List<AyahRef>> f = ayahsOfPage(widget.page);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AyahRef>>(
      future: f,
      builder: (c, s) {
        if (s.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('${s.error}', textAlign: TextAlign.center),
            ),
          );
        }
        if (!s.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = s.data!;
        return ListView.builder(
          controller: widget.controller,
          padding: const EdgeInsets.all(kPaddingMedium),
          itemCount: list.length + 1,
          itemBuilder: (c, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'آيات الصفحة ${widget.page}: اختر آية',
                  style: Theme.of(c).textTheme.titleLarge,
                ),
              );
            }
            final a = list[i - 1];
            return ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: kGreen,
                child: Text(
                  '${a.ayah}',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              title: Text(
                a.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18),
              ),
              subtitle: Text(a.surahName),
              onTap: () => showAyahActions(widget.outer, a, list, i - 1),
            );
          },
        );
      },
    );
  }
}

Widget _act(IconData i, String t, VoidCallback f) {
  return InkWell(
    onTap: f,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(i, color: kGreen, size: 30),
          const SizedBox(height: 4),
          Text(t, style: const TextStyle(fontSize: 12)),
        ],
      ),
    ),
  );
}

void showAyahActions(
  BuildContext context,
  AyahRef a,
  List<AyahRef> page,
  int index,
) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${a.surahName}: ${a.ayah}',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              a.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _act(Icons.share, 'مشاركة', () {
                  Navigator.pop(ctx);
                  _shareChoice(context, a);
                }),
                _act(Icons.bookmark_add_outlined, 'نقطة حفظ', () async {
                  Navigator.pop(ctx);
                  final on = await toggleBookmark(a);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        on ? 'تمت إضافة نقطة حفظ' : 'أُزيلت نقطة الحفظ',
                      ),
                    ),
                  );
                }),
                _act(Icons.menu_book, 'تفسير', () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TafsirScreen(a: a),
                    ),
                  );
                }),
                _act(Icons.play_circle_outline, 'استماع', () {
                  Navigator.pop(ctx);
                  AyahAudio.playList(page, index);
                }),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

void _shareChoice(BuildContext context, AyahRef a) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.text_fields, color: kGreen),
            title: const Text('مشاركة كنص'),
            onTap: () {
              Navigator.pop(ctx);
              shareAyahText(a);
            },
          ),
          ListTile(
            leading: const Icon(Icons.image, color: kGreen),
            title: const Text('مشاركة كصورة'),
            onTap: () {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                builder: (_) => ShareImageDialog(a: a),
              );
            },
          ),
        ],
      ),
    ),
  );
}
