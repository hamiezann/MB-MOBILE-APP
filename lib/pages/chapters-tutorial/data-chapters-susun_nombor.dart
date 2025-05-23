import 'package:math_buddy_v1/models/chapter_model.dart';
import 'package:math_buddy_v1/models/quiz_questions.dart';

final SusunNomborChapter = Chapter(
  title: 'SUSUN NOMBOR',
  subtopics: [
    Subtopic(
      title: 'KENAL NOMBOR',
      imagePath: 'assets/subtopics/susun nombor-kenal nombor.png',
      tutorials: List.generate(
        10,
        (index) => TutorialContent(
          imagePath:
              'assets/tutorials/kenal nombor/Kenal nombor -${index + 1}.png',
          audioPath: 'audio/dummy/test.mp3',
          description: descriptionsKenalNombor[index],
        ),
      ),
    ),
    Subtopic(
      title: 'SUSUN NOMBOR',
      imagePath: 'assets/subtopics/susun nombor-susun nombor.png',
      tutorials: List.generate(
        4,
        (index) => TutorialContent(
          imagePath:
              'assets/tutorials/susun nombor/susun nombor- menaik(${index + 1}).png',
          audioPath: 'audio/dummy/test.mp3',
          description: descriptionsSusunNombor[index],
        ),
      ),
    ),
    // Subtopic(
    //   title: 'SAIZ',
    //   imagePath: 'assets/subtopics/kenal objek- saiz.png',
    //   tutorials: List.generate(
    //     2,
    //     (index) => TutorialContent(
    //       imagePath: 'assets/tutorials/saiz/${index + 1}.png',
    //       audioPath: 'assets/audio/saiz_$index.mp3',
    //       description: descriptionsSaiz[index],
    //     ),
    //   ),
    // ),
  ],
  quizTitle: 'Susun Nombor',
  quizQuestions: susunNomborQuiz,
  videoUrl: 'assets/video/test_video.mp4',
);

final descriptionsKenalNombor = [
  'SATU',
  'DUA',
  'TIGA',
  'EMPAT',
  'LIMA',
  'ENAM',
  'TUJUH',
  'LAPAN',
  'SEMBILAN',
  'SEPULUH',
];

final descriptionsSusunNombor = [
  'SUSUNAN MENAIK',
  'SUSUNAN MENAIK',
  'SUSUNAN MENURUN',
  'SUSUNAN MENURUN',
];
