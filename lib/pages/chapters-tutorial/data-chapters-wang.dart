import 'package:math_buddy_v1/models/chapter_model.dart';
import 'package:math_buddy_v1/models/quiz_questions.dart';

final WangChapter = Chapter(
  id: '6',
  imagePath: '',
  title: 'WANG',
  subtopics: [
    Subtopic(
      title: 'WANG KERTAS',
      imagePath: 'assets/subtopics/wang kertas.png',
      tutorials: List.generate(
        6,
        (index) => TutorialContent(
          imagePath: 'assets/tutorials/wang kertas/${index + 1}.png',
          audioPath: 'audio/dummy/test.mp3',
          description: descriptionsWangKertas[index],
        ),
      ),
    ),
    Subtopic(
      title: 'SYILING',
      imagePath: 'assets/subtopics/syiling.png',
      tutorials: List.generate(
        4,
        (index) => TutorialContent(
          imagePath: 'assets/tutorials/syiling/${index + 1}.png',
          audioPath: 'audio/dummy/test.mp3',
          description: descriptionsSyiling[index],
        ),
      ),
    ),
  ],
  quizTitle: 'Wang',
  quizQuestions: wangQuiz,
  videoUrl: 'assets/video/test_video.mp4',
);

final descriptionsWangKertas = [
  'SERINGGIT : RM 1',
  'LIMA RINGGIT : RM 5',
  'SEPULUH RINGGIT : RM 10',
  'DUA PULUH RINGGIT : RM 20',
  'LIMA PULUH RINGGIT : RM 50',
  'SERATUS RINGGIT : RM 100',
];

final descriptionsSyiling = [
  'LIMA SEN : 0.05 SEN',
  'SEPULUH SEN : 0.10 SEN',
  'DUA PULUH SEN : 0.20 SEN',
  'LIMA PULUH SEN : 0.50 SEN',
];
