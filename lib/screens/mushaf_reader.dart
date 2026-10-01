import 'package:flutter/material.dart';
import 'mushaf_page.dart';
import 'mushaf_service.dart';

class MushafReader extends StatefulWidget {
  final int startPage;
  const MushafReader({Key? key, required this.startPage})
      : super(key: key);

  @override
  State<MushafReader> createState() => _MushafReaderState();
}

class _MushafReaderState extends State<MushafReader> {
  late final PageController _pc;
  late int page;
  bool zoomed = false;

  @override
  void initState() {
    super.initState();
    page = widget.startPage;
    _pc = PageController(initialPage: page - 1);
    saveLastPage(page);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text('صفحة $page')),
      body: PageView.builder(
        controller: _pc,
        itemCount: 604,
        physics: zoomed
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        onPageChanged: (i) {
          setState(() {
            page = i + 1;
            zoomed = false;
          });
          saveLastPage(i + 1);
        },
        itemBuilder: (context, i) => MushafPage(
          key: ValueKey(i),
          page: i + 1,
          dark: dark,
          onZoom: (z) => setState(() => zoomed = z),
        ),
      ),
    );
  }
}
