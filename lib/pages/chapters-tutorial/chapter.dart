import 'package:flutter/material.dart';
import 'package:math_buddy_v1/components/card.dart';
import 'package:math_buddy_v1/models/chapter_model.dart';
import 'package:math_buddy_v1/pages/chapters-tutorial/data-chapters-kenal_bentuk.dart';
import 'package:math_buddy_v1/pages/chapters-tutorial/data-chapters-masa.dart';
import 'package:math_buddy_v1/pages/chapters-tutorial/data-chapters-susun_nombor.dart';
import 'package:math_buddy_v1/pages/chapters-tutorial/data-chapters-tambah.dart';
import 'package:math_buddy_v1/pages/chapters-tutorial/data-chapters-tolak.dart';
import 'package:math_buddy_v1/pages/chapters-tutorial/data-chapters-wang.dart';

class TopicPage extends StatelessWidget {
  final Function(Chapter) onChapterSelected;
  const TopicPage({super.key, required this.onChapterSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.lightBlue.shade300],
            // colors: [Colors.lightBlue.shade200, Colors.lightGreen.shade200],
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
            children: [
              TopicCard(
                title: 'Kenal Objek',
                imagePath: 'assets/chapter/topic-kenal_objek.png',
                onTap: () => onChapterSelected(KenalObjekChapter),
              ),
              TopicCard(
                title: 'Nombor',
                imagePath: 'assets/chapter/topic-susun_nombor.png',
                onTap: () => onChapterSelected(SusunNomborChapter),
              ),
              TopicCard(
                title: 'Tambah',
                imagePath: 'assets/chapter/topic-mengira_tambah.png',
                onTap: () => onChapterSelected(TambahChapter),
              ),
              TopicCard(
                title: 'Tolak',
                imagePath: 'assets/chapter/topic-mengira_tolak.png',
                onTap: () => onChapterSelected(TolakChapter),
              ),
              TopicCard(
                title: 'Wang',
                imagePath: 'assets/chapter/topic-wang.png',
                onTap: () => onChapterSelected(WangChapter),
              ),
              TopicCard(
                title: 'Masa',
                imagePath: 'assets/chapter/topic-masa.png',
                onTap: () => onChapterSelected(MasaChapter),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
