import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'riyad_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  Widget _book(
    BuildContext context, {
    required String title,
    required String author,
    required String about,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Card(
      color: kCardBackground,
      child: ListTile(
        contentPadding: const EdgeInsets.all(kPaddingMedium),
        leading: CircleAvatar(
          backgroundColor: kGreen.withOpacity(0.18),
          child: Icon(icon, color: kGreen),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('$author\n$about'),
        ),
        isThreeLine: true,
        trailing: onTap == null
            ? const Chip(label: Text('قريباً', style: TextStyle(fontSize: 11)))
            : const Icon(Icons.chevron_left, color: kGreen),
        onTap: onTap ??
            () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('هذا الكتاب قريباً')),
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المكتبة')),
      body: ListView(
        padding: const EdgeInsets.all(kPaddingMedium),
        children: [
          _book(
            context,
            title: 'رياض الصالحين',
            author: 'الإمام يحيى بن شرف النووي',
            about: 'أحاديث مبوّبة في الآداب والأخلاق والعبادات، مع بحث ومفضلة.',
            icon: Icons.menu_book,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RiyadScreen()),
            ),
          ),
          _book(
            context,
            title: 'الأذكار',
            author: 'الإمام يحيى بن شرف النووي',
            about: 'أذكار اليوم والليلة والمناسبات.',
            icon: Icons.auto_awesome,
          ),
        ],
      ),
    );
  }
}
