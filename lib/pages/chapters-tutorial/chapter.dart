import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:math_buddy_v1/components/card.dart';
import 'package:math_buddy_v1/models/chapter_model.dart';
import 'package:math_buddy_v1/pages/audio_helper.dart';

class TopicPage extends StatelessWidget {
  final Function(Chapter) onChapterSelected;
  final String? teacherNo;

  const TopicPage({
    super.key,
    required this.onChapterSelected,
    required this.teacherNo,
  });

  @override
  Widget build(BuildContext context) {
    return teacherNo == null || teacherNo!.isEmpty
        ? Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.lightBlue.shade300],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(child: Text("TIADA KELAS DIDAFTARKAN!")),
        )
        : _buildFirebaseContent();
  }

  Widget _buildFirebaseContent() {
    return FutureBuilder<List<Chapter>>(
      future: fetchChaptersWithSubtopics(teacherNo!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Tiada bab ditemui.'));
        }

        final chapters = snapshot.data!;
        // print($chapters);
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.lightBlue.shade300],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              padding: const EdgeInsets.all(10),
              children:
                  chapters.map((chapter) {
                    return TopicCard(
                      title: chapter.title,
                      imagePath: chapter.imagePath,
                      onTap: () async {
                        await AudioCacheHelper.clearAllCachedAudio();
                        onChapterSelected(chapter);
                      },
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<List<Chapter>> fetchChaptersWithSubtopics(String teacherNo) async {
    final chapterSnapshot =
        await FirebaseFirestore.instance
            .collection('chapters')
            .where('owner_id', isEqualTo: teacherNo)
            .where('status', isEqualTo: 'published')
            .get();

    List<Chapter> chapters = [];

    for (var chapterDoc in chapterSnapshot.docs) {
      final chapterData = chapterDoc.data();
      final chapterId = chapterDoc.id;
      final subtopicSnapshot =
          await FirebaseFirestore.instance
              .collection('chapters')
              .doc(chapterId)
              .collection('subtopics')
              .get();

      final videoSnapshot =
          await FirebaseFirestore.instance
              .collection("chapters")
              .doc(chapterId)
              .collection("videos")
              .get();

      List<Subtopic> subtopics = [];

      for (var subDoc in subtopicSnapshot.docs) {
        final subData = subDoc.data();

        // Fetch tutorials for each subtopic
        final tutorialSnapshot =
            await FirebaseFirestore.instance
                .collection('chapters')
                .doc(chapterId)
                .collection('subtopics')
                .doc(subDoc.id)
                .collection('contents')
                .get();

        List<TutorialContent> tutorials =
            tutorialSnapshot.docs.map((tutDoc) {
              final tutData = tutDoc.data();
              return TutorialContent(
                imagePath: tutData['imageUrl1'] ?? '',
                audioPath: tutData['audioUrl'] ?? '',
                description: tutData['description'] ?? '',
              );
            }).toList();

        subtopics.add(
          Subtopic(
            title: subData['title'] ?? '',
            imagePath: subData['imageUrl'] ?? '',
            tutorials: tutorials,
          ),
        );
      }

      String videoUrl = '';
      if (videoSnapshot.docs.isNotEmpty) {
        videoUrl = videoSnapshot.docs.first.data()['url'] ?? '';
      }

      // Construct full Chapter object
      chapters.add(
        Chapter(
          id: chapterId,
          title: chapterData['title'] ?? '',
          videoUrl: videoUrl,
          imagePath: chapterData['imagePath'].toString().trim(),
          quizTitle: chapterData['quizTitle'] ?? '',
          quizQuestions: [], // Add quiz fetch later
          subtopics: subtopics,
        ),
      );
    }

    return chapters;
  }
}
