import 'package:math_buddy_v1/models/chapter_model.dart';
import 'package:math_buddy_v1/models/quiz_questions.dart';

final TambahChapter = Chapter(
  id: '4',
  imagePath: '',
  title: 'TAMBAH',
  subtopics: [
    Subtopic(
      title: 'MENGIRA TAMBAH',
      imagePath: 'assets/subtopics/mengira_tambah.png',
      tutorials: List.generate(
        4,
        (index) => TutorialContent(
          imagePath: 'assets/tutorials/tambah/mengira tambah -${index + 1}.png',
          audioPath: 'audio/dummy/test.mp3',
          description: descriptionsTambah[index],
        ),
      ),
    ),
  ],
  quizTitle: 'Mengira Tambah',
  quizQuestions: tambahQuiz,
  videoUrl: 'assets/video/test_video.mp4',
);

final descriptionsTambah = ['5', '4', '8', '10', '7'];
