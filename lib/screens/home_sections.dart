import 'package:flutter/material.dart';
import '../core/constants.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionTitle(this.title, {Key? key, this.trailing})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class Shortcut {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const Shortcut(this.label, this.icon, this.color, this.onTap);
}

class ShortcutRow extends StatelessWidget {
  final List<Shortcut> items;
  const ShortcutRow({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 112,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final s = items[i];
          return InkWell(
            onTap: s.onTap,
            child: SizedBox(
              width: 86,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 33,
                    backgroundColor:
                        dark ? s.color.withOpacity(0.25) : s.color,
                    child: Icon(s.icon, color: kGreen, size: 30),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ContinueCard extends StatelessWidget {
  final int? page;
  final VoidCallback onTap;
  const ContinueCard({Key? key, required this.page, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: kGreen.withOpacity(0.2),
                child: const Icon(Icons.menu_book, color: kGreen, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'متابعة المصحف من حيث توقفت',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(page == null
                        ? 'ابدأ القراءة من الفاتحة'
                        : 'الصفحة $page من 604'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (page ?? 0) / 604,
                      minHeight: 6,
                      color: kGreen,
                      backgroundColor: kGreen.withOpacity(0.2),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: kGreen),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgressCard extends StatelessWidget {
  final double? progress;
  final VoidCallback onTap;
  const ProgressCard({Key? key, required this.progress, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final p = progress ?? 0;
    return Card(
      color: kCardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'إنجاز أذكار اليوم',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${(p * 100).round()}%',
                    style: const TextStyle(
                      color: kGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: p,
                minHeight: 6,
                color: kGreen,
                backgroundColor: kGreen.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
