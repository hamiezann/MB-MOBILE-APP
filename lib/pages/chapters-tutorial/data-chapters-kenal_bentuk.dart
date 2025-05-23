import 'package:math_buddy_v1/models/chapter_model.dart';
import 'package:math_buddy_v1/models/quiz_questions.dart';

final KenalObjekChapter = Chapter(
  title: 'KENAL OBJEK',
  subtopics: [
    Subtopic(
      title: 'WARNA',
      imagePath: 'assets/subtopics/kenal objek- warna.png',
      tutorials: List.generate(
        9,
        (index) => TutorialContent(
          imagePath: 'assets/tutorials/warna/${index + 1}.png',
          audioPath: 'audio/warna/$index.mp3',
          description: descriptionsWarna[index],
        ),
      ),
    ),
    Subtopic(
      title: 'BENTUK',
      imagePath: 'assets/subtopics/kenal objek- bentuk.png',
      tutorials: List.generate(
        4,
        (index) => TutorialContent(
          imagePath: 'assets/tutorials/bentuk/bentuk${index + 1}.png',
          audioPath: 'audio/bentuk/${index + 1}.mp3',
          description: descriptionsBentuk[index],
        ),
      ),
    ),
    Subtopic(
      title: 'SAIZ',
      imagePath: 'assets/subtopics/kenal objek- saiz.png',
      tutorials: List.generate(
        2,
        (index) => TutorialContent(
          imagePath: 'assets/tutorials/saiz/${index + 1}.png',
          audioPath: 'audio/saiz/${index + 1}.mp3',
          description: descriptionsSaiz[index],
        ),
      ),
    ),
  ],
  quizTitle: 'Kenal Objek',
  quizQuestions: kenalObjekQuiz,
  videoUrl: 'assets/video/test_video.mp4',
);

final descriptionsWarna = [
  'WARNA MERAH',
  'WARNA HIJAU',
  'WARNA BIRU',
  'WARNA KUNING',
  'WARNA UNGGU',
  'WARNA HITAM',
  'WARNA OREN',
  'WARNA PUTIH',
  'WARNA COKLAT',
];

final descriptionsBentuk = [
  'BENTUK BULAT',
  'BENTUK SEGI TIGA',
  'BENTUK SEGI EMPAT TEPAT',
  'BENTUK SEGI EMPAT SAMA',
];

final descriptionsSaiz = ['SAIZ KECIL', 'SAIZ BESAR'];
