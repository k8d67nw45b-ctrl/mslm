import 'package:flutter/material.dart';
import '../core/constants.dart';

class HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const HomeCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCardBackground,
      margin: const EdgeInsets.only(bottom: kPaddingMedium),
      child: ListTile(
        contentPadding: const EdgeInsets.all(kPaddingMedium),
        leading: Icon(icon, color: kGreen, size: 36),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left, color: kGreen),
        onTap: onTap,
      ),
    );
  }
}
