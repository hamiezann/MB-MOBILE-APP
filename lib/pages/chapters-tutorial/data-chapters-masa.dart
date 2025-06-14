import 'package:math_buddy_v1/models/chapter_model.dart';
import 'package:math_buddy_v1/models/quiz_questions.dart';

final MasaChapter = Chapter(
  id: '2',
  imagePath: '',
  title: 'MASA',
  subtopics: [
    Subtopic(
      title: 'WAKTU',
      imagePath: 'assets/subtopics/waktu.png',
      tutorials: List.generate(
        5,
        (index) => TutorialContent(
          imagePath: 'assets/tutorials/waktu/${index + 1}.png',
          audioPath: 'audio/dummy/test.mp3',
          description: descriptionsWaktu[index],
        ),
      ),
    ),
    Subtopic(
      title: 'HARI',
      imagePath: 'assets/subtopics/hari.png',
      tutorials: List.generate(
        7,
        (index) => TutorialContent(
          imagePath: 'assets/tutorials/hari/${index + 1}.png',
          audioPath: 'audio/dummy/test.mp3',
          description: descriptionsHari[index],
        ),
      ),
    ),
  ],
  quizTitle: 'Masa',
  quizQuestions: masaQuiz,
  videoUrl: 'assets/video/test_video.mp4',
);

final descriptionsWaktu = ['PAGI', 'PETANG', 'TENGAHARI', 'SIANG', 'MALAM'];
final descriptionsHari = [
  'AHAD',
  'ISNIN',
  'SELASA',
  'RABU',
  'KHAMIS',
  ' JUMAAT',
  'SABTU',
];
