import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chords_screen.dart';
import 'metronome_screen.dart';

// Дані рекомендованих пісень для початківців
const _recommendedSongs = [
  {
    'title': 'Knockin\' on Heaven\'s Door',
    'artist': 'Bob Dylan',
    'difficulty': 'Початківець',
    'difficultyColor': 0xFF4CAF50,
    'chords': ['G', 'D', 'Am', 'C'],
    'strumPattern': '↓ ↓↑ ↑↓↑',
    'description':
        'Одна з найпростіших пісень для початківців. Всього 4 акорди, повільний темп — ідеально для першого тижня.',
    'tips': [
      'Почни з повільного темпу — 60 BPM',
      'Зміна G→D найважча — тренуй окремо',
      'Бій: ↓ ↓↑ ↑↓↑ (6/8 відчуття)',
      'Am і C — схожа форма руки',
    ],
    'youtubeId': 'PN0gTuJH9zg',
    'youtubeTitle': 'Урок на YouTube',
  },
  {
    'title': 'Horse With No Name',
    'artist': 'America',
    'difficulty': 'Початківець',
    'difficultyColor': 0xFF4CAF50,
    'chords': ['Em', 'D6'],
    'strumPattern': '↓↑ ↓↑ ↓↑',
    'description':
        'Неймовірно проста пісня — лише 2 акорди, які чергуються! Ідеально для абсолютного початківця.',
    'tips': [
      'Тільки Em та D6 (або Dmaj6)',
      'Рівномірний бій 8-ками',
      'D6: 2-0-0-2-3-2 (можна спростити)',
      'Тренуй переходи 5 хвилин на день',
    ],
    'youtubeId': '5EB6btkgCpk',
    'youtubeTitle': 'Урок на YouTube',
  },
  {
    'title': 'Wonderwall',
    'artist': 'Oasis',
    'difficulty': 'Легкий',
    'difficultyColor': 0xFF8BC34A,
    'chords': ['Em7', 'G', 'Dsus4', 'A7sus4', 'Cadd9'],
    'strumPattern': '↓ ↓ ↑↓↑',
    'description':
        'Класика 90-х. Акорди трохи складніші, але всі залишають мізинець і безіменний на місці — це полегшує зміни.',
    'tips': [
      'Мізинець і безіменний — завжди на 2 і 3 струнах!',
      'Em7: 022033 — легкий стартовий акорд',
      'Cadd9 замість C — звучить краще і простіше',
      'Спробуй повільніше 70 BPM, потім пришвидшуй',
    ],
    'youtubeId': 'o8wM8inaqmo',
    'youtubeTitle': 'Урок від Marty Music',
  },
  {
    'title': 'Stand By Me',
    'artist': 'Ben E. King',
    'difficulty': 'Легкий',
    'difficultyColor': 0xFF8BC34A,
    'chords': ['A', 'F#m', 'D', 'E'],
    'strumPattern': '↓ ↓↑ ↓ ↓↑',
    'description':
        'Вічна класика з простою прогресією. Акорди йдуть послідовно і легко запам\'ятовуються.',
    'tips': [
      'Прогресія I-VI-IV-V — базова в музиці',
      'E-акорд — найлегший для новачків',
      'Tempo ~60-70 BPM для початку',
      'Звернись до барре F#m якщо складно — замість нього Am',
    ],
    'youtubeId': 'WHQRyYLCJIE',
    'youtubeTitle': 'Урок від Marty Music',
  },
];

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('LEARNING CENTER',
            style: TextStyle(
                letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Інструменти ──
          _buildCategoryHeader('Інструменти'),
          _buildLessonCard(
            context,
            'Бібліотека акордів',
            'Усі базові розкладки',
            Icons.grid_view,
            Colors.greenAccent,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChordsScreen())),
          ),
          _buildLessonCard(
            context,
            'Метроном',
            'Тренуй відчуття ритму',
            Icons.timer,
            Colors.redAccent,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MetronomeScreen())),
          ),

          const SizedBox(height: 20),

          // ── Основи ──
          _buildCategoryHeader('Основи'),
          _buildLessonCard(
            context,
            'Як налаштувати гітару',
            'Покрокова інструкція для новачків',
            Icons.tune,
            Colors.blueAccent,
            onTap: () => _showTuningGuide(context),
          ),
          const SizedBox(height: 20),

          // ── Теорія ──
          _buildCategoryHeader('Теорія'),
          _buildLessonCard(
            context,
            'Будова гітари',
            'З чого складається твій інструмент',
            Icons.layers,
            Colors.orangeAccent,
            onTap: () => _showGuitarAnatomy(context),
          ),

          const SizedBox(height: 28),

          // ── Рекомендовані пісні ──
          _buildCategoryHeader('🎸 Рекомендовані для початківців'),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 5, bottom: 16),
            child: Text(
              'Підібрані пісні з детальними інструкціями та відео-уроками',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),

          ...List.generate(
            _recommendedSongs.length,
            (i) => _buildRecommendedSongCard(i, _recommendedSongs[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSongCard(
      int index, Map<String, dynamic> song) {
    final isExpanded = _expandedIndex == index;
    final chords = (song['chords'] as List).cast<String>();
    final tips = (song['tips'] as List).cast<String>();
    final color = Color(song['difficultyColor'] as int);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isExpanded
              ? color.withOpacity(0.4)
              : Colors.white.withOpacity(0.05),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Column(
        children: [
          // ── Header ──
          InkWell(
            onTap: () =>
                setState(() => _expandedIndex = isExpanded ? null : index),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Song icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.music_note, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song['title'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          song['artist'] as String,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                song['difficulty'] as String,
                                style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 2,
                                children: chords.take(4).map((c) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(c,
                                      style: const TextStyle(
                                          color: Colors.white60, fontSize: 10)),
                                )).toList(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Expand icon
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: Colors.white38),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded content ──
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(song, chords, tips, color),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(
    Map<String, dynamic> song,
    List<String> chords,
    List<String> tips,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white10, height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              Text(
                song['description'] as String,
                style:
                    const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),

              // Chords list
              const Text(
                'АКОРДИ',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chords
                    .map((c) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Text(
                            c,
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 16),

              // Strum pattern
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.music_note,
                        color: Colors.white38, size: 16),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('БІЙ / ПЕРЕБІР',
                            style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(
                          song['strumPattern'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tips
              const Text(
                'ПОРАДИ',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...tips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5, right: 10),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 16),

              // YouTube button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0000).withOpacity(0.85),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.play_circle_filled, size: 22),
                  label: const Text('Відео-урок на YouTube',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _openYouTube(song['youtubeId'] as String),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openYouTube(String videoId) async {
    final uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    try {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не вдалося відкрити посилання: $e')));
      }
    }
  }

  void _showTuningGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF151515),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.tune, color: Colors.blueAccent, size: 28),
                ),
                const SizedBox(width: 16),
                const Text('Як налаштувати гітару', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Стандартний стрій (від найтовщої до найтоншої струни):', style: TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 16),
            _buildStringRow('6', 'E', 'Мі', Colors.redAccent),
            _buildStringRow('5', 'A', 'Ля', Colors.orangeAccent),
            _buildStringRow('4', 'D', 'Ре', Colors.yellowAccent),
            _buildStringRow('3', 'G', 'Соль', Colors.greenAccent),
            _buildStringRow('2', 'B', 'Сі', Colors.blueAccent),
            _buildStringRow('1', 'E', 'Мі', Colors.purpleAccent),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Порада: скористайтеся нашим вбудованим тюнером. Грайте по одній струні, і тюнер підкаже, як змінити натяг.', style: TextStyle(color: Colors.blueAccent, fontSize: 13, height: 1.4)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStringRow(String number, String note, String noteName, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF222222),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(number, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: color.withOpacity(0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: Row(
              children: [
                Text(note, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('($noteName)', style: const TextStyle(color: Colors.white38, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGuitarAnatomy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF151515),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.layers, color: Colors.orangeAccent, size: 28),
                ),
                const SizedBox(width: 16),
                const Text('Будова гітари', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            _buildAnatomyItem(Icons.settings, 'Головка грифа', 'Тут знаходяться кілки, якими ви налаштовуєте натяг струн.'),
            _buildAnatomyItem(Icons.linear_scale, 'Гриф та Лади', 'Довга частина гітари з металевими порожками. Затискаючи струни на ладах, ви створюєте ноти та акорди.'),
            _buildAnatomyItem(Icons.crop_portrait, 'Корпус (Дека)', 'Найбільша частина гітари. В акустичних гітарах вона порожниста і працює як резонатор, посилюючи звук.'),
            _buildAnatomyItem(Icons.horizontal_rule, 'Бридж (Підставка)', 'Місце кріплення струн на корпусі гітари.'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAnatomyItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.orangeAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white24,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildLessonCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white10),
        onTap: onTap,
      ),
    );
  }
}