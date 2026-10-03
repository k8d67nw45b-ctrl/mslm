import 'package:flutter/material.dart';

class MushafPage extends StatefulWidget {
  final int page;
  final int theme;
  final ValueChanged<bool> onZoom;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const MushafPage({
    Key? key,
    required this.page,
    required this.theme,
    required this.onZoom,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  State<MushafPage> createState() => MushafPageState();
}

class MushafPageState extends State<MushafPage> {
  final _c = TransformationController();

  void zoomBy(double factor) {
    final size = context.size;
    if (size == null) return;
    final cur = _c.value.getMaxScaleOnAxis();
    final next = (cur * factor).clamp(1.0, 5.0).toDouble();
    if (next <= 1.2) {
      _c.value = Matrix4.identity();
      widget.onZoom(false);
      return;
    }
    final k = next / cur;
    final cx = size.width / 2;
    final cy = size.height / 2;
    _c.value = Matrix4.translationValues(cx, cy, 0)
        .multiplied(Matrix4.diagonal3Values(k, k, 1))
        .multiplied(Matrix4.translationValues(-cx, -cy, 0))
        .multiplied(_c.value);
    widget.onZoom(true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color? tint;
    BlendMode? blend;
    switch (widget.theme) {
      case 2:
        tint = const Color(0xFFF1E4C8);
        blend = BlendMode.multiply;
        break;
      case 3:
        tint = const Color(0xFFE6E6E6);
        blend = BlendMode.difference;
        break;
      case 4:
        tint = Colors.white;
        blend = BlendMode.difference;
        break;
    }
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
        onLongPress: widget.onLongPress,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Image.asset(
            'assets/mushaf/p${widget.page}.webp',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            color: tint,
            colorBlendMode: blend,
            errorBuilder: (c, e, s) => const Center(
              child: Text('الصفحة غير موجودة داخل التطبيق'),
            ),
          ),
        ),
      ),
    );
  }
}
