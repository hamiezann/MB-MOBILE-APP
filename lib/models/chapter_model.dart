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
  final String title;
  final List<Subtopic> subtopics;
  final String quizTitle;
  final List<QuizContent> quizQuestions;
  final String videoUrl;

  Chapter({
    required this.title,
    required this.subtopics,
    required this.quizTitle,
    required this.quizQuestions,
    required this.videoUrl,
  });
}
