import 'package:flutter/material.dart';
import 'moon.dart';
import 'rf_design.dart';

class RfPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final double height;
  final Widget? trailing;
  final RfSky sky;
  const RfPageHeader({
    Key? key,
    required this.title,
    this.subtitle = '',
    this.height = 120,
    this.trailing,
    this.sky = rfNightSky,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();
    return SizedBox(
      height: height + top,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              child: RfScene(sky: sky, age: moonAge(DateTime.now())),
            ),
          ),
          Positioned(
            top: top + 10,
            left: 8,
            right: 8,
            child: Row(
              children: [
                if (canPop)
                  IconButton(
                    icon: const BackButtonIcon(),
                    color: Colors.white,
                    onPressed: () => Navigator.maybePop(context),
                  )
                else
                  const SizedBox(width: 10),
                const Icon(Icons.mosque, color: rfGold, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
