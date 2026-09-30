class Dhikr {
  final String text;
  final int count;
  const Dhikr(this.text, this.count);
}

class AdhkarCategory {
  final String id;
  final String title;
  final List<Dhikr> items;
  const AdhkarCategory(this.id, this.title, this.items);
}

const List<AdhkarCategory> adhkarCategories = [
  AdhkarCategory('morning', 'أذكار الصباح والمساء', [
    Dhikr(
      'قُلْ هُوَ اللَّهُ أَحَدٌ * اللَّهُ الصَّمَدُ * لَمْ يَلِدْ وَلَمْ يُولَدْ * وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
      3,
    ),
    Dhikr(
      'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      100,
    ),
    Dhikr(
      'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
      100,
    ),
    Dhikr(
      'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      10,
    ),
  ]),
  AdhkarCategory('sleep', 'أذكار النوم', [
    Dhikr(
      'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      1,
    ),
    Dhikr(
      'سُبْحَانَ اللَّهِ',
      33,
    ),
    Dhikr(
      'الْحَمْدُ لِلَّهِ',
      33,
    ),
    Dhikr(
      'اللَّهُ أَكْبَرُ',
      34,
    ),
  ]),
  AdhkarCategory('prayer', 'أذكار بعد الصلاة', [
    Dhikr(
      'أَسْتَغْفِرُ اللَّهَ',
      3,
    ),
    Dhikr(
      'سُبْحَانَ اللَّهِ',
      33,
    ),
    Dhikr(
      'الْحَمْدُ لِلَّهِ',
      33,
    ),
    Dhikr(
      'اللَّهُ أَكْبَرُ',
      33,
    ),
  ]),
];
