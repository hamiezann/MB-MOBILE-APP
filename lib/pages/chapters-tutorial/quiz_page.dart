import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:math_buddy_v1/models/quiz_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizPage extends StatefulWidget {
  final List<QuizContent> questions;
  final String quizTitle;
  final String? teacherNo;
  final String? quizId;
  const QuizPage({
    super.key,
    required this.quizTitle,
    required this.questions,
    required this.teacherNo,
    required this.quizId,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int currentIndex = 0;
  int score = 0;
  bool answered = false;
  String? selectedAnswer;
  String _getBadge(int score, int total) {
    double percentage = (score / total) * 100;

    if (percentage >= 90) return 'Cemerlang'; // Excellent
    if (percentage >= 70) return 'Syabas'; // Great
    if (percentage >= 50) return 'Bagus'; // Good
    return 'Cuba Lagi'; // Try Again
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

  bool isUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
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
                Text('Lencana: ${_getBadge(score, widget.questions.length)}'),
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
                      ? _buildImageWidget(question.imagePaths[0])
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children:
                            question.imagePaths
                                .map(
                                  (img) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: _buildImageWidget(img),
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

  Widget _buildImageWidget(String path) {
    if (isUrl(path)) {
      return CachedNetworkImage(
        imageUrl: path,
        placeholder:
            (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(Icons.error),
        fit: BoxFit.contain,
      );
    } else {
      return Image.asset(path, fit: BoxFit.contain);
    }
  }

  Future<void> _updateQuizResult() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final quizKey = widget.quizTitle.toLowerCase().replaceAll(' ', '_');
    final totalQuestions = widget.questions.length;
    final badge = _getBadge(score, totalQuestions);
    final newScoreFormatted = "$score/$totalQuestions";

    final userSnapshot = await userDoc.get();
    final existingScoreRaw = userSnapshot.data()?['score']?[quizKey];

    int existingRaw = 0;
    if (existingScoreRaw != null && existingScoreRaw is String) {
      final parts = existingScoreRaw.split('/');
      if (parts.isNotEmpty) existingRaw = int.tryParse(parts[0]) ?? 0;
    }
    if (score > existingRaw) {
      final Map<String, dynamic> updateData = {
        'score': {quizKey: newScoreFormatted},
        'badge': {quizKey: badge},
      };

      if (widget.teacherNo != null && widget.teacherNo!.isNotEmpty) {
        updateData['teacher_quiz'] = {
          quizKey: {'teacher_no': widget.teacherNo!, 'quiz_id': widget.quizId},
        };
      }

      await userDoc.set(updateData, SetOptions(merge: true));
    }
  }
}
