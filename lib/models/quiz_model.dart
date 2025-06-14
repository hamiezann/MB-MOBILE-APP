import 'package:cloud_firestore/cloud_firestore.dart';

class QuizContent {
  final String id;
  final List<String> imagePaths;
  final String optionA;
  final String optionB;
  final String correctAnswer;

  QuizContent({
    required this.id,
    required this.imagePaths,
    required this.optionA,
    required this.optionB,
    required this.correctAnswer,
  });

  factory QuizContent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return QuizContent(
      id: doc.id,
      // imagePaths: List<String>.from(data['imagePaths'] ?? []),
      imagePaths:
          data['imagePaths'] is List
              ? List<String>.from(data['imagePaths'])
              : [data['imagePaths'] ?? ''],
      optionA: data['optionA'] ?? '',
      optionB: data['optionB'] ?? '',
      correctAnswer: data['correctAnswer'] ?? '',
    );
  }
}
