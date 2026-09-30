import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'hajj_data.dart';
import 'hajj_detail.dart';

class HajjScreen extends StatelessWidget {
  const HajjScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مساعد الحج والعمرة')),
      body: ListView(
        padding: const EdgeInsets.all(kPaddingMedium),
        children: [
          for (final k in hajjKinds)
            Card(
              color: kCardBackground,
              margin: const EdgeInsets.only(bottom: kPaddingMedium),
              child: ListTile(
                contentPadding: const EdgeInsets.all(kPaddingMedium),
                leading: const Icon(Icons.mosque, color: kGreen, size: 36),
                title: Text(k.title, style: const TextStyle(fontSize: 20)),
                subtitle: Text('${k.steps.length} مراحل'),
                trailing: const Icon(Icons.chevron_left, color: kGreen),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HajjDetail(kind: k)),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
