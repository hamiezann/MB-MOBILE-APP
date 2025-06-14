import 'package:math_buddy_v1/models/chapter_model.dart';
import 'package:math_buddy_v1/models/quiz_questions.dart';

final TolakChapter = Chapter(
  id: '5',
  imagePath: '',
  title: 'TOLAK',
  subtopics: [
    Subtopic(
      title: 'MENGIRA TOLAK',
      imagePath: 'assets/subtopics/mengira_tolak.png',
      tutorials: List.generate(
        4,
        (index) => TutorialContent(
          imagePath: 'assets/tutorials/tolak/mengira tolak - ${index + 1}.png',
          audioPath: 'audio/dummy/test.mp3',
          description: descriptionsTolak[index],
        ),
      ),
    ),
  ],
  quizTitle: 'Mengira Tolak',
  quizQuestions: tolakQuiz,
  videoUrl: 'assets/video/test_video.mp4',
);

final descriptionsTolak = ['6', '4', '1', '0', '2'];
