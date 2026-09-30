import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'adhkar_data.dart';
import 'adhkar_detail.dart';
import 'nawawi_screen.dart';

class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(kPaddingMedium),
      children: [
        Text(
          'حصن المسلم',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: kPaddingMedium),
        for (final c in adhkarCategories)
          Card(
            color: kCardBackground,
            margin: const EdgeInsets.only(bottom: kPaddingMedium),
            child: ListTile(
              title: Text(c.title, style: const TextStyle(fontSize: 18)),
              trailing: const Icon(Icons.chevron_left, color: kGreen),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdhkarDetail(cat: c)),
                );
              },
            ),
          ),
        Card(
          color: kCardBackground,
          margin: const EdgeInsets.only(bottom: kPaddingMedium),
          child: ListTile(
            title: const Text(
              'الأربعون النووية',
              style: TextStyle(fontSize: 18),
            ),
            trailing: const Icon(Icons.chevron_left, color: kGreen),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NawawiScreen()),
              );
            },
          ),
        ),
      ],
    );
  }
}
