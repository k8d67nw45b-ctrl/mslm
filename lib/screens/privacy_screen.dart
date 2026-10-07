import 'package:flutter/material.dart';
import '../core/constants.dart';

// ضع بريدك هنا ليظهر بآخر الصفحة، ويكون هو نفسه بالنص المنشور
const String kContactEmail = 'ffaaddss2010@gmail.com';

class _Sec {
  final String title;
  final String body;
  const _Sec(this.title, this.body);
}

const List<_Sec> _ar = [
  _Sec(
    'نظرة عامة',
    'رفيق المسلم تطبيق إسلامي يعمل على جهازك. لا يطلب حساباً، ولا يعرض '
        'إعلانات، ولا يستخدم أدوات تتبّع أو تحليلات.',
  ),
  _Sec(
    'الموقع',
    'نستخدم موقعك (أو المدينة التي تختارها) على جهازك فقط لحساب مواقيت '
        'الصلاة واتجاه القبلة. لا يُرسَل موقعك إلى أي خادم من طرفنا، ولا '
        'نملك خوادم أصلاً.',
  ),
  _Sec(
    'ما يُحفظ على جهازك',
    'تقدّمك بالقراءة، نقاط الحفظ، الإحصائيات، الأهداف، الإعدادات، وما '
        'يشبهها. تبقى على جهازك وتُحذف عند إزالة التطبيق.',
  ),
  _Sec(
    'الاتصال بالإنترنت',
    'معظم المحتوى (المصحف والأذكار والأحاديث) داخل التطبيق. وتُطلب بعض '
        'الخدمات فقط عند استخدامك لها: التفسير (من alquran.cloud ومستودع '
        'tafsir_api عبر شبكة jsDelivr) والاستماع للتلاوة (من everyayah.com). '
        'هذه الجهات تستقبل طلبك وعنوان IP كأي موقع ويب، وتخضع لسياساتها.',
  ),
  _Sec(
    'الإشعارات',
    'تنبيهات الصلاة والأذكار والورد تُجدوَل محلياً على جهازك، ولا نستخدم '
        'خدمات إشعارات خارجية.',
  ),
  _Sec(
    'الأذونات',
    'الموقع (للمواقيت والقبلة)، الإشعارات، المنبّهات الدقيقة (لتنبيه الأذان '
        'في وقته)، التشغيل بعد إعادة تشغيل الجهاز (لاستعادة التنبيهات)، '
        'الاهتزاز، والإنترنت (للتفسير والتلاوة).',
  ),
  _Sec(
    'النسخ الاحتياطي',
    'ميزة اختيارية تنشئ ملفاً تحفظه أنت بنفسك. التطبيق لا يرفع أي بيانات.',
  ),
  _Sec(
    'الأطفال',
    'لا نجمع بيانات شخصية من أي مستخدم، بمن فيهم الأطفال.',
  ),
  _Sec(
    'التغييرات',
    'قد نحدّث هذه السياسة، وتظهر الصيغة الحالية دائماً داخل التطبيق.',
  ),
];

const List<_Sec> _en = [
  _Sec(
    'Overview',
    'Rafiq Al-Muslim is an Islamic app that runs on your device. It needs no '
        'account, shows no ads, and uses no tracking or analytics tools.',
  ),
  _Sec(
    'Location',
    'Your location (or the city you pick) is used on your device only, to '
        'calculate prayer times and the Qibla direction. It is never sent to '
        'any server of ours, and we operate no servers.',
  ),
  _Sec(
    'Data stored on your device',
    'Reading progress, bookmarks, statistics, goals, settings and similar '
        'items stay on your device and are removed when you uninstall the app.',
  ),
  _Sec(
    'Internet access',
    'Most content (the Quran, adhkar, hadith) is built into the app. Some '
        'services are requested only when you use them: tafsir (from '
        'alquran.cloud and the tafsir_api repository via jsDelivr) and '
        'recitation audio (from everyayah.com). Those services receive your '
        'request and IP address like any website and are governed by their '
        'own policies.',
  ),
  _Sec(
    'Notifications',
    'Prayer, adhkar and Quran-wird reminders are scheduled locally on your '
        'device. We use no external push service.',
  ),
  _Sec(
    'Permissions',
    'Location (prayer times and Qibla), notifications, exact alarms (to alert '
        'at the exact prayer time), run after reboot (to restore reminders), '
        'vibration, and internet (tafsir and recitation).',
  ),
  _Sec(
    'Backup',
    'An optional feature that creates a file which you save yourself. The app '
        'does not upload any data.',
  ),
  _Sec(
    'Children',
    'We do not collect personal data from any user, including children.',
  ),
  _Sec(
    'Changes',
    'This policy may be updated. The current version is always available '
        'inside the app.',
  ),
];

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  Widget _list(List<_Sec> items, TextDirection dir, String contact) {
    return Directionality(
      textDirection: dir,
      child: ListView(
        padding: const EdgeInsets.all(kPaddingMedium),
        children: [
          for (final s in items) ...[
            Text(
              s.title,
              style: const TextStyle(
                color: kGreen,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            Text(s.body, style: const TextStyle(height: 1.8, fontSize: 15)),
            const SizedBox(height: 16),
          ],
          if (kContactEmail.isNotEmpty)
            Text(
              '$contact: $kContactEmail',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سياسة الخصوصية'),
          bottom: const TabBar(
            tabs: [Tab(text: 'العربية'), Tab(text: 'English')],
          ),
        ),
        body: TabBarView(
          children: [
            _list(_ar, TextDirection.rtl, 'للتواصل'),
            _list(_en, TextDirection.ltr, 'Contact'),
          ],
        ),
      ),
    );
  }
}
