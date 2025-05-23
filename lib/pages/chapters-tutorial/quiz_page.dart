import 'package:flutter/material.dart';
import 'package:math_buddy_v1/models/quiz_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizPage extends StatefulWidget {
  final List<QuizContent> questions;
  final String quizTitle;
  const QuizPage({super.key, required this.quizTitle, required this.questions});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int currentIndex = 0;
  int score = 0;
  bool answered = false;
  String? selectedAnswer;
  String _getBadge(int score) {
    if (score >= 9) return 'Cemerlang';
    if (score >= 7) return 'Syabas';
    if (score >= 5) return 'Bagus';
    return 'Cuba Lagi';
  }

  void _checkAnswer(String answer) {
    if (answered) return;

    setState(() {
      answered = true;
      selectedAnswer = answer;
      if (answer == widget.questions[currentIndex].correctAnswer) {
        score++;
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (currentIndex < widget.questions.length - 1) {
        setState(() {
          currentIndex++;
          answered = false;
          selectedAnswer = null;
        });
      } else {
        _showScoreDialog();
      }
    });
  }

  void _showScoreDialog() {
    _updateQuizResult();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Ujian Tamat'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Skor anda: $score / ${widget.questions.length}'),
                const SizedBox(height: 10),
                Text('Lencana: ${_getBadge(score)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // back to subtopic
                },
                child: const Text('Kembali'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentIndex];
    // final quizTitle = widget.quizTitle;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Uji Minda',
          // quizTitle,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.lightBlue.shade300],
            // colors: [Colors.lightBlue.shade100, Colors.greenAccent.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child:
                  question.imagePaths.length == 1
                      ? Image.asset(question.imagePaths[0], fit: BoxFit.contain)
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children:
                            question.imagePaths
                                .map(
                                  (img) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        img,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
            ),
            const SizedBox(height: 30),
            _buildAnswerButton(question.optionA),
            const SizedBox(height: 20),
            _buildAnswerButton(question.optionB),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerButton(String answer) {
    final isSelected = selectedAnswer == answer;
    final isCorrect = answer == widget.questions[currentIndex].correctAnswer;

    return ElevatedButton(
      onPressed: () => _checkAnswer(answer),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            answered
                ? (isSelected
                    ? (isCorrect ? Colors.green : Colors.red)
                    : Colors.grey.shade300)
                : Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        answer,
        style: TextStyle(
          fontSize: 20,
          color:
              answered
                  ? (isSelected ? Colors.white : Colors.black)
                  : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _updateQuizResult() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final quizKey = widget.quizTitle.toLowerCase().replaceAll(' ', '_');
    final totalQuestions = widget.questions.length;
    final badge = _getBadge(score);

    final newScoreFormatted = "$score/$totalQuestions";

    final userSnapshot = await userDoc.get();
    final existingScoreRaw = userSnapshot.data()?['score']?[quizKey];

    // Convert existing score from "x/y" to int x for comparison
    int existingRaw = 0;
    if (existingScoreRaw != null && existingScoreRaw is String) {
      final parts = existingScoreRaw.split('/');
      if (parts.isNotEmpty) existingRaw = int.tryParse(parts[0]) ?? 0;
    }

    if (score > existingRaw) {
      await userDoc.set({
        'score': {quizKey: newScoreFormatted},
        'badge': {quizKey: badge},
      }, SetOptions(merge: true));
    }
  }
}
