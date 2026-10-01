import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class MushafPage extends StatefulWidget {
  final int page;
  final bool dark;
  final ValueChanged<bool> onZoom;
  const MushafPage({
    Key? key,
    required this.page,
    required this.dark,
    required this.onZoom,
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

  String get _url {
    final theme = widget.dark ? 'dark' : 'light';
    return 'https://cdn.jsdelivr.net/gh/SakinaDevGroup/'
        'mushaf-madani-cdn@main/$theme/p${widget.page}.png';
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _c,
      minScale: 1,
      maxScale: 5,
      onInteractionEnd: (_) {
        widget.onZoom(_c.value.getMaxScaleOnAxis() > 1.05);
      },
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: CachedNetworkImage(
          imageUrl: _url,
          fit: BoxFit.contain,
          placeholder: (c, u) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (c, u, e) => const Center(
            child: Text('تعذّر تحميل الصفحة، تأكد من الإنترنت'),
          ),
        ),
      ),
    );
  }
}
