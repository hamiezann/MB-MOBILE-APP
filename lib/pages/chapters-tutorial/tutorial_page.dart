import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:math_buddy_v1/models/chapter_model.dart';
import 'dart:async';
import 'dart:math';
// import 'package:audioplayers/audioplayers.dart';
import 'package:math_buddy_v1/pages/audio_helper.dart';

class TutorialPage extends StatefulWidget {
  final Subtopic subtopic;

  const TutorialPage({super.key, required this.subtopic});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  late AnimationController _controller;
  late Animation<double> _swingAnimation;
  late Timer _flipTimer;
  bool _isFlipped = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  Future<void> _playAudio() async {
    final audioPath = widget.subtopic.tutorials[currentIndex].audioPath;
    print('audipath: $audioPath');

    try {
      setState(() => _isPlaying = true);
      await _audioPlayer.stop();

      if (isUrl(audioPath)) {
        final file = await AudioCacheHelper.downloadAndCacheAudio(audioPath);
        await _audioPlayer.setFilePath(file.path);
      } else {
        await _audioPlayer.setAsset('assets/$audioPath');
      }

      await _audioPlayer.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Audio gagal dimainkan. Periksa sambungan internet.',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => _playAudio(),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      setState(() => _isPlaying = false);
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _controller.dispose();
    _flipTimer.cancel();
    super.dispose();
  }

  void _goNext() async {
    if (currentIndex < widget.subtopic.tutorials.length - 1) {
      await _stopAudio();
      setState(() {
        currentIndex++;
      });
    }
  }

  void _goPrevious() async {
    await _stopAudio();
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    }
  }

  void _finishTutorial() async {
    await _stopAudio();
    Navigator.pop(context);
  }

  bool isUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });
    });

    _swingAnimation = Tween<double>(
      begin: -15.0,
      end: 15.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _flipTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() {
        _isFlipped = Random().nextBool(); // flip randomly
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.subtopic.tutorials[currentIndex];
    final isLastPage = currentIndex == widget.subtopic.tutorials.length - 1;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          widget.subtopic.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.lightBlue.shade300],
            // colors: [Colors.lightBlue.shade100, Colors.greenAccent.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Tutorial Image
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, child) {
                    return Transform.translate(
                      offset: Offset(_swingAnimation.value, 0),
                      child: Transform(
                        alignment: Alignment.center,
                        transform:
                            Matrix4.identity()
                              ..scale(_isFlipped ? -1.0 : 1.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child:
                      isUrl(content.imagePath)
                          ? CachedNetworkImage(
                            imageUrl: content.imagePath,
                            height: screenWidth * 1.8,
                            fit: BoxFit.contain,
                            placeholder:
                                (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            errorWidget:
                                (context, url, error) =>
                                    const Icon(Icons.broken_image),
                          )
                          : Image.asset(
                            content.imagePath,
                            fit: BoxFit.contain,
                            height: screenWidth * 1.8,
                          ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Description Text
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                content.description,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // Navigation + Audio Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Previous Arrow
                if (currentIndex > 0)
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 48,
                      color: Colors.blue,
                      weight: 800,
                    ),
                    onPressed: _goPrevious,
                  )
                else
                  const SizedBox(width: 48),

                // Speaker Icon (audio playback)
                IconButton(
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                    size: 60,
                    color: Colors.deepOrange,
                  ),
                  onPressed: () {
                    if (_isPlaying) {
                      _pauseAudio();
                    } else {
                      _playAudio();
                    }
                  },
                ),

                // Next Arrow or Done Button
                if (!isLastPage)
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 48,
                      color: Colors.blue,
                      weight: 800,
                    ),
                    onPressed: _goNext,
                  )
                else
                  ElevatedButton(
                    onPressed: _finishTutorial,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Selesai',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
