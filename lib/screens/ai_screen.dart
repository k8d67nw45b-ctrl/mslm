import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';

// ضع هنا رابط الـ Worker بعد نشره، مثال:
// https://rafiq-ai.اسمك.workers.dev
const String kAiUrl = '';

class _Msg {
  final bool user;
  final String text;
  _Msg(this.user, this.text);
}

const _modes = ['general', 'fiqh', 'tadabbur'];
const _modeNames = ['عام', 'فقه مبسط', 'تدبر القرآن'];
const _samples = [
  [
    'ما الفرق بين السنة والفرض؟',
    'كيف أحافظ على الخشوع بالصلاة؟',
  ],
  [
    'هل يجوز الجمع بين الصلاتين بالسفر؟',
    'ما حكم الصيام لمن يسافر برمضان؟',
  ],
  [
    'ما معنى الاستعاذة قبل القراءة؟',
    'تأمل بقوله تعالى: ألا بذكر الله تطمئن القلوب',
  ],
];

Future<String> _ask(List<_Msg> history, String mode) async {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);
  try {
    final req = await client.postUrl(Uri.parse(kAiUrl));
    req.headers.contentType = ContentType.json;
    final tail =
        history.length > 10 ? history.sublist(history.length - 10) : history;
    final body = jsonEncode({
      'mode': mode,
      'messages': [
        for (final m in tail)
          {'role': m.user ? 'user' : 'assistant', 'content': m.text},
      ],
    });
    req.add(utf8.encode(body));
    final res = await req.close().timeout(const Duration(seconds: 60));
    final txt = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) throw Exception('status ${res.statusCode}');
    final j = jsonDecode(txt);
    return (j['reply'] ?? '').toString();
  } finally {
    client.close();
  }
}

class AiScreen extends StatefulWidget {
  const AiScreen({Key? key}) : super(key: key);

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final List<_Msg> msgs = [];
  final TextEditingController ctl = TextEditingController();
  final ScrollController sc = ScrollController();
  bool busy = false;
  int mode = 0;

  @override
  void dispose() {
    ctl.dispose();
    sc.dispose();
    super.dispose();
  }

  void _down() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (sc.hasClients) {
        sc.animateTo(
          sc.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final t = (preset ?? ctl.text).trim();
    if (t.isEmpty || busy || kAiUrl.isEmpty) return;
    ctl.clear();
    setState(() {
      msgs.add(_Msg(true, t));
      busy = true;
    });
    _down();
    String reply;
    try {
      reply = await _ask(msgs, _modes[mode]);
      if (reply.trim().isEmpty) reply = 'تعذّر الرد، حاول مرة أخرى.';
    } catch (_) {
      reply = 'تعذّر الاتصال. تأكد من الإنترنت وحاول مرة أخرى.';
    }
    if (!mounted) return;
    setState(() {
      msgs.add(_Msg(false, reply));
      busy = false;
    });
    _down();
  }

  Widget _bubble(_Msg m) {
    final u = m.user;
    return Align(
      alignment: u ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: m.text));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم النسخ')),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.86,
          ),
          decoration: BoxDecoration(
            color: u ? kGreen : kCardBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: SelectableText(
            m.text,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: u ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final off = kAiUrl.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('المساعد الذكي'),
        actions: [
          IconButton(
            tooltip: 'محادثة جديدة',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: busy ? null : () => setState(msgs.clear),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: kGreen.withOpacity(0.12),
            padding: const EdgeInsets.all(10),
            child: const Text(
              'مساعد آلي للتوضيح العام وليس مفتياً، وقد يُخطئ. تحقق من '
              'المصادر، وارجع لأهل العلم والجهة الرسمية بالمسائل المهمة.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < _modeNames.length; i++)
                  ChoiceChip(
                    label: Text(_modeNames[i]),
                    selected: mode == i,
                    onSelected: (_) => setState(() => mode = i),
                  ),
              ],
            ),
          ),
          Expanded(
            child: off
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'المساعد غير مفعّل بعد في هذه النسخة.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : msgs.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const Text('جرّب سؤالاً مثل:',
                              style: TextStyle(color: Colors.grey)),
                          for (final s in _samples[mode])
                            Card(
                              color: kCardBackground,
                              child: ListTile(
                                title: Text(s),
                                trailing: const Icon(Icons.send, size: 18),
                                onTap: () => _send(s),
                              ),
                            ),
                        ],
                      )
                    : ListView(
                        controller: sc,
                        padding: const EdgeInsets.all(12),
                        children: [
                          for (final m in msgs) _bubble(m),
                          if (busy)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctl,
                      enabled: !off,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 600,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'اكتب سؤالك...',
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: kGreen,
                    onPressed: (busy || off) ? null : () => _send(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
