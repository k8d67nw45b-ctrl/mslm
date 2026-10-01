import 'package:flutter/material.dart';

const _invert = ColorFilter.matrix(<double>[
  -1, 0, 0, 0, 255,
  0, -1, 0, 0, 255,
  0, 0, -1, 0, 255,
  0, 0, 0, 1, 0,
]);

class MushafPage extends StatefulWidget {
  final int page;
  final bool dark;
  final ValueChanged<bool> onZoom;
  final VoidCallback onTap;
  const MushafPage({
    Key? key,
    required this.page,
    required this.dark,
    required this.onZoom,
    required this.onTap,
  }) : super(key: key);

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  final _c = TransformationController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      'assets/mushaf/p${widget.page}.webp',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (c, e, s) => const Center(
        child: Text('الصفحة غير موجودة داخل التطبيق'),
      ),
    );
    final shown = widget.dark
        ? ColorFiltered(colorFilter: _invert, child: img)
        : img;
    return InteractiveViewer(
      transformationController: _c,
      minScale: 1,
      maxScale: 5,
      onInteractionEnd: (_) {
        widget.onZoom(_c.value.getMaxScaleOnAxis() > 1.05);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: shown,
        ),
      ),
    );
  }
}
