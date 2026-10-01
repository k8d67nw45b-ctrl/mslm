import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import 'daily_content.dart';

class DailyCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final DailyItem item;
  const DailyCard({
    Key? key,
    required this.label,
    required this.icon,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: kGreen),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: kGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم النسخ')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.text,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, height: 1.9),
            ),
            const SizedBox(height: 8),
            Text(item.source, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
