import 'package:math_buddy_v1/models/quiz_model.dart';

class TutorialContent {
  final String imagePath;
  final String audioPath;
  final String description;

  TutorialContent({
    required this.imagePath,
    required this.audioPath,
    required this.description,
  });
}

class Subtopic {
  final String title;
  final String imagePath;
  final List<TutorialContent> tutorials;

  Subtopic({
    required this.title,
    required this.imagePath,
    required this.tutorials,
  });
}

class Chapter {
  final String id;
  final String title;
  final List<Subtopic> subtopics;
  final String quizTitle;
  final List<QuizContent> quizQuestions;
  final String videoUrl;
  final String imagePath;

  Chapter({
    required this.id,
    required this.title,
    required this.subtopics,
    required this.quizTitle,
    required this.quizQuestions,
    required this.videoUrl,
    required this.imagePath,
  });
}

// class DynamicChapter {
//   final String id;
//   final String title;
//   final String description;
//   final String imagePath;
//   final String status;

//   DynamicChapter({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.imagePath,
//     required this.status,
//   });
// }
