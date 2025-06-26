import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:math_buddy_v1/models/chapter_model.dart';
import 'package:math_buddy_v1/models/quiz_model.dart';
import 'package:math_buddy_v1/pages/chapters-tutorial/quiz_page.dart';
import 'package:math_buddy_v1/pages/chapters-tutorial/tutorial_page.dart';
import 'package:video_player/video_player.dart';

class SubtopicPage extends StatefulWidget {
  final Chapter chapter;
  final String? teacherNo;
  const SubtopicPage({
    super.key,
    required this.chapter,
    required this.teacherNo,
  });

  @override
  State<SubtopicPage> createState() => _SubtopicPageState();
}

class _SubtopicPageState extends State<SubtopicPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  bool _muted = false;
  double _volume = 1.0;
  List<Map<String, dynamic>> chapterQuizzes = [];
  bool isLoadingQuizzes = true;

  @override
  void initState() {
    super.initState();
    // if (isUrl(widget.chapter.videoUrl)) {
    _fetchVideoSUbtopic();
    // } else {
    //   _videoPlayerController = VideoPlayerController.asset(
    //       widget.chapter.videoUrl,
    //     )
    //     ..initialize().then((_) {
    //       setState(() {});
    //     });
    // }
    _fetchChapterQuizzes();
  }

  Future<void> _fetchChapterQuizzes() async {
    final quizSnapshot =
        await FirebaseFirestore.instance
            .collection('chapters')
            .doc(widget.chapter.id) // ensure Chapter model has `id`
            .collection('quizzes')
            .get();

    setState(() {
      chapterQuizzes =
          quizSnapshot.docs.map((doc) {
            final data = doc.data();
            return {'id': doc.id, 'title': data['title'] ?? 'Untitled Quiz'};
          }).toList();
      isLoadingQuizzes = false;
    });
  }

  Future<void> _fetchVideoSUbtopic() async {
    try {
      final url = widget.chapter.videoUrl.trim();
      if (url.isNotEmpty) {
        String downloadUrl;

        if (url.startsWith('http')) {
          downloadUrl = url;
        } else {
          final ref = FirebaseStorage.instance.ref(url);
          downloadUrl = await ref.getDownloadURL();
        }

        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(downloadUrl),
        );
        await _videoPlayerController.initialize();
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: false,
          looping: false,
          allowMuting: true,
          allowPlaybackSpeedChanging: true,
          showControls: true,
        );
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal muat turun video'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _showVideoDialog() {
    if (_chewieController == null ||
        !_videoPlayerController.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Video tidak tersedia untuk bab ini.'),
            ],
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => Stack(
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Container(color: Colors.black54),
                    ),
                    Center(
                      child: Material(
                        color: Colors.transparent,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.95,
                            maxHeight: MediaQuery.of(context).size.height * 0.8,
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Reserve space for close button
                                    const SizedBox(height: 40),
                                    Flexible(
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final aspectRatio =
                                              _videoPlayerController
                                                  .value
                                                  .aspectRatio;

                                          // Available space after padding and close button
                                          final availableWidth =
                                              constraints.maxWidth;
                                          final availableHeight =
                                              constraints.maxHeight -
                                              40; // Account for close button space

                                          // Calculate video dimensions that fit within available space
                                          double videoWidth;
                                          double videoHeight;

                                          // Try fitting by width first
                                          videoWidth = availableWidth;
                                          videoHeight =
                                              videoWidth / aspectRatio;

                                          // If height exceeds available space, fit by height instead
                                          if (videoHeight > availableHeight) {
                                            videoHeight = availableHeight;
                                            videoWidth =
                                                videoHeight * aspectRatio;
                                          }

                                          return Center(
                                            child: SizedBox(
                                              width: videoWidth,
                                              height: videoHeight,
                                              child: Chewie(
                                                controller: _chewieController!,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      _videoPlayerController.pause();
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  // bool isUrl(String path) {
  //   return path.startsWith('http://') || path.startsWith('https://');
  // }

  @override
  Widget build(BuildContext context) {
    final totalItems = widget.chapter.subtopics.length + 1;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    // var isImageFromUrl = false;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.lightBlue.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                widget.chapter.title,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: totalItems,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  if (index < widget.chapter.subtopics.length) {
                    final subtopic = widget.chapter.subtopics[index];
                    return GestureDetector(
                      onTap: () {
                        if (subtopic.tutorials.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TutorialPage(subtopic: subtopic),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              // content: Text('Tiada Konten Untuk Subtopik Ini'),
                              content: const Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Tiada konten untuk Subtopik ini.'),
                                ],
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // isUrl(subtopic.imagePath)
                            //     ?
                            CachedNetworkImage(
                              imageUrl: subtopic.imagePath,
                              height: screenHeight * 0.15,
                              width: screenWidth * 0.3,
                              fit: BoxFit.contain,
                              placeholder:
                                  (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              errorWidget:
                                  (context, url, error) =>
                                      const Icon(Icons.broken_image),
                            ),
                            // : Image.asset(
                            //   subtopic.imagePath,
                            //   fit: BoxFit.contain,
                            //   height: screenHeight * 0.15,
                            //   width: screenWidth * 0.3,
                            // ),
                            Text(
                              subtopic.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenHeight * 0.02,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              textScaler: TextScaler.linear(0.8),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return GestureDetector(
                      onTap: () {
                        if (widget.teacherNo == null ||
                            widget.teacherNo!.isEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => QuizPage(
                                    quizTitle: widget.chapter.quizTitle,
                                    questions: widget.chapter.quizQuestions,
                                    teacherNo: widget.teacherNo,
                                    quizId: widget.chapter.id,
                                  ),
                            ),
                          );
                        } else {
                          _startQuiz(
                            widget.chapter.id,
                          ); // Pass chapter ID for Firebase
                        }
                      },

                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange, width: 2),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: screenHeight * 0.15,
                                width: screenWidth * 0.3,
                                child: Image.asset(
                                  'assets/uji minda.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Text(
                                'Uji Minda',
                                style: TextStyle(
                                  fontSize: screenHeight * 0.02,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                _showVideoDialog();
              },
              icon: const Icon(Icons.play_circle_filled),
              label: const Text('Tonton Video Bab'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _startQuiz(String chapterId) async {
    final quizRef = FirebaseFirestore.instance
        .collection('chapters')
        .doc(chapterId)
        .collection('quizzes');

    final snapshot = await quizRef.orderBy('createdAt').get();

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Tiada kuiz untuk bab ini.'),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // Show dialog to choose quiz
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.quiz, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Pilih Uji Minda',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      snapshot.docs.map((doc) {
                        final quizId = doc.id;
                        final quizTitle = doc['title'];
                        final createdAt = doc['createdAt']?.toDate();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.quiz_outlined,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              quizTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle:
                                createdAt != null
                                    ? Text(
                                      'Dibuat: ${_formatDate(createdAt)}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    )
                                    : null,
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            onTap: () async {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:
                                    (context) => const Center(
                                      child: Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(20),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(),
                                              SizedBox(height: 16),
                                              Text('Memuatkan soalan...'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                              );

                              try {
                                final questionSnapshot =
                                    await quizRef
                                        .doc(quizId)
                                        .collection('questions')
                                        .orderBy('createdAt')
                                        .get();

                                final questions =
                                    questionSnapshot.docs
                                        .map(
                                          (q) => QuizContent.fromFirestore(q),
                                        )
                                        .toList();

                                // Close loading dialog
                                Navigator.pop(context);
                                // Close quiz selection dialog
                                Navigator.pop(context);

                                if (questions.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Tiada soalan untuk kuiz ini.'),
                                        ],
                                      ),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: Colors.orange,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => QuizPage(
                                          quizTitle: quizTitle,
                                          questions: questions,
                                          teacherNo: widget.teacherNo,
                                          quizId: quizId,
                                        ),
                                  ),
                                );
                              } catch (error) {
                                // Close loading dialog if still open
                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Ralat memuatkan kuiz: $error',
                                          ),
                                        ),
                                      ],
                                    ),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
