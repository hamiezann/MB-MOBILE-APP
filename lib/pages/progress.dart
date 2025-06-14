import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  Future<Map<String, dynamic>> fetchUserProgress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    final userData = userDoc.data();
    if (userData == null) return {};

    final rawScores = userData['score'] ?? {};
    final rawBadges = userData['badge'] ?? {};
    final teacherNo = userData['teacher_no'];
    final teacherQuizzes = Map<String, dynamic>.from(
      userData['teacher_quiz'] ?? {},
    );

    print("Raw teacher_quiz data: $teacherQuizzes");
    print("score: $rawScores");
    print("badge: $rawBadges");

    final scores = <String, String>{};
    final badges = <String, String>{};

    // Handle static (non-teacher) quizzes
    // (rawScores as Map).forEach((key, value) {
    //   scores[key.toString()] = value.toString();
    // });
    // (rawBadges as Map).forEach((key, value) {
    //   badges[key.toString()] = value.toString();
    // });

    // Store titles from teacher-created quizzes
    final dynamicChapters = <String>[];

    // if (teacherNo != null && teacherNo.toString().isNotEmpty) {
    //   for (var quizKey in teacherQuizzes.keys) {
    //     final info = Map<String, dynamic>.from(teacherQuizzes[quizKey] ?? {});
    //     final quizId = info['quiz_id'];
    //     if (quizId != null) {
    //       // Fetch quiz document using teacherNo and quizId
    //       final quizDoc =
    //           await FirebaseFirestore.instance
    //               .collection('chapters')
    //               .where('owner_id', isEqualTo: teacherNo)
    //               .get();

    //       for (var chapter in quizDoc.docs) {
    //         final quizRef = FirebaseFirestore.instance
    //             .collection('chapters')
    //             .doc(chapter.id)
    //             .collection('quizzes')
    //             .doc(quizId);

    //         final quizSnapshot = await quizRef.get();
    //         if (quizSnapshot.exists) {
    //           final quizData = quizSnapshot.data();
    //           final quizTitle = quizData?['title'] ?? quizKey;

    //           dynamicChapters.add(quizTitle);
    //           // Inject score and badge by quiz title
    //           if (rawScores.containsKey(quizKey)) {
    //             scores[quizTitle] = rawScores[quizKey];
    //           }
    //           if (rawBadges.containsKey(quizKey)) {
    //             badges[quizTitle] = rawBadges[quizKey];
    //           }
    //         }
    //       }
    //     }
    //   }

    //   return {
    //     'scores': scores,
    //     'badges': badges,
    //     'chapters': dynamicChapters,
    //     'teacher_quiz': teacherQuizzes,
    //   };
    // }

    if (teacherNo != null && teacherNo.toString().isNotEmpty) {
      for (var quizKey in teacherQuizzes.keys) {
        final info = Map<String, dynamic>.from(teacherQuizzes[quizKey] ?? {});
        final quizId = info['quiz_id'];
        if (quizId != null) {
          final quizDoc =
              await FirebaseFirestore.instance
                  .collection('chapters')
                  .where('owner_id', isEqualTo: teacherNo)
                  .get();

          for (var chapter in quizDoc.docs) {
            final quizRef = FirebaseFirestore.instance
                .collection('chapters')
                .doc(chapter.id)
                .collection('quizzes')
                .doc(quizId);

            final quizSnapshot = await quizRef.get();
            if (quizSnapshot.exists) {
              final quizData = quizSnapshot.data();
              final quizTitle = quizData?['title'] ?? quizKey;

              dynamicChapters.add(quizTitle);
              if (rawScores.containsKey(quizKey)) {
                scores[quizTitle] = rawScores[quizKey].toString();
              }
              if (rawBadges.containsKey(quizKey)) {
                badges[quizTitle] = rawBadges[quizKey].toString();
              }
            }
          }
        }
      }

      return {
        'scores': scores,
        'badges': badges,
        'chapters': dynamicChapters,
        'teacher_quiz': teacherQuizzes,
      };
    } else {
      (rawScores as Map).forEach((key, value) {
        scores[key.toString()] = value.toString();
      });
      (rawBadges as Map).forEach((key, value) {
        badges[key.toString()] = value.toString();
      });
    }

    return {
      'scores': scores,
      'badges': badges,
      'chapters': [
        'kenal_objek',
        'susun_nombor',
        'mengira_tambah',
        'mengira_tolak',
        'wang',
        'masa',
      ],
      'teacher_quiz': {},
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Pencapaian Saya',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.lightBlue.shade300],
              // colors: [Colors.lightBlue.shade200, Colors.lightGreen.shade200],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: fetchUserProgress(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final scores = snapshot.data!['scores'] as Map<String, String>;
              final badges = snapshot.data!['badges'] as Map<String, String>;

              // Calculate total score and achievements
              final totalScore = scores.values.fold(0, (sum, score) {
                final parts = score.split('/');
                final numericScore = int.tryParse(parts[0]) ?? 0;
                return sum + numericScore;
              });

              final earnedBadges =
                  badges.values.where((badge) => badge != "None").length;

              final allChapterLabels = {
                'kenal_objek': 'Kenal Objek',
                'susun_nombor': 'Nombor',
                'mengira_tambah': 'Tambah',
                'mengira_tolak': 'Tolak',
                'wang': 'Wang',
                'masa': 'Masa',
              };

              // Get dynamic or fallback chapters
              // final chapterKeys =
              //     (snapshot.data!['chapters'] as List).cast<String>();
              final rawChapters = snapshot.data!['chapters'] as List ?? [];
              final chapterKeys =
                  rawChapters.whereType<String>().toList() ?? [];

              final chapters = Map.fromEntries(
                chapterKeys.map(
                  (key) => MapEntry(allChapterLabels[key] ?? key, key),
                ),
              );
              // print("chapter: $snapshot");
              return Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + 10),
                  // Trophy showcase at top
                  _buildTrophyHeader(context, totalScore, earnedBadges),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: GridView.count(
                        childAspectRatio: 0.50,
                        crossAxisCount: 2,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        children:
                            chapters.entries.map((entry) {
                              final displayName = entry.key;
                              final key = entry.value;
                              final score = scores[key] ?? "0/10";
                              final badge = badges[key] ?? "None";
                              // print(
                              //   "🔍 Chapter key: $key | Score: $score | Badge: $badge",
                              // );
                              return _buildProgressCard(
                                displayName,
                                // score as String,
                                score,
                                badge,
                                context,
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTrophyHeader(
    BuildContext context,
    int totalScore,
    int earnedBadges,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Trophy avatar with shimmer effect
          _buildAnimatedTrophy(context, earnedBadges),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jumlah Skor',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '$totalScore',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Anda telah memperoleh $earnedBadges pingat!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTrophy(BuildContext context, int earnedBadges) {
    final trophyColor = earnedBadges > 3 ? Colors.amber : Colors.blueGrey;

    return TrophyAnimation(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [trophyColor.shade300, trophyColor.shade700],
                center: Alignment.topLeft,
                radius: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: trophyColor.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Icon(Icons.emoji_events, size: 45, color: Colors.white),
          if (earnedBadges > 0)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$earnedBadges',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String title, String score, String badge, context) {
    final badgeIcon = _getBadgeIcon(badge);
    final badgeColor = _getBadgeColor(badge);
    final hasBadge = badge != "None";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: hasBadge ? badgeColor.withOpacity(0.4) : Colors.black12,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: hasBadge ? badgeColor : Colors.blue.shade300,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Medal or badge with animation for earned badges
          hasBadge
              ? _buildBadgeDisplay(badgeIcon, badgeColor, badge)
              : CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey.shade200,
                child: Icon(badgeIcon, size: 30, color: badgeColor),
              ),
          const SizedBox(height: 10),

          // Chapter title
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Score progress indicator
          _buildScoreIndicator(score as String, badgeColor, hasBadge),

          // Badge label or default text
          const SizedBox(height: 8),
          hasBadge
              ? Text(
                badge,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
              )
              : const Text(
                "Belum ambil",
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildBadgeDisplay(IconData icon, Color color, String badge) {
    // Return different animations based on badge level
    if (badge == 'Cemerlang') {
      return StarBadge(color: color, icon: icon);
    } else if (badge == 'Syabas') {
      return PulsatingBadge(color: color, icon: icon);
    } else {
      return CircleAvatar(
        radius: 30,
        backgroundColor: color.withOpacity(0.2),
        child: Icon(icon, size: 30, color: color),
      );
    }
  }

  Widget _buildScoreIndicator(String score, Color badgeColor, bool hasBadge) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Circular progress indicator
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: () {
                  final parts = score.split('/');
                  final earned = int.tryParse(parts[0]) ?? 0;
                  final total =
                      int.tryParse(parts.length > 1 ? parts[1] : '10') ?? 10;
                  return earned / total;
                }(),

                strokeWidth: 8,
                backgroundColor: Colors.grey.shade200,
                color: hasBadge ? badgeColor : Colors.blue,
              ),
            ),
            // Score text
            Text(
              '$score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: hasBadge ? badgeColor : Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getBadgeIcon(String badge) {
    switch (badge) {
      case 'Cuba Lagi':
        return Icons.replay;
      case 'Bagus':
        return Icons.thumb_up;
      case 'Syabas':
        return Icons.emoji_events;
      case 'Cemerlang':
        return Icons.star;
      default:
        return Icons.emoji_events_outlined;
    }
  }

  Color _getBadgeColor(String badge) {
    switch (badge) {
      case 'Cuba Lagi':
        return Colors.orange;
      case 'Bagus':
        return Colors.blue;
      case 'Syabas':
        return Colors.green;
      case 'Cemerlang':
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }
  }
}

// ANIMATION WIDGETS

// Trophy rotation animation
class TrophyAnimation extends StatefulWidget {
  final Widget child;

  const TrophyAnimation({super.key, required this.child});

  @override
  State<TrophyAnimation> createState() => _TrophyAnimationState();
}

class _TrophyAnimationState extends State<TrophyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + 0.1 * _controller.value,
          child: widget.child,
        );
      },
    );
  }
}

// Star badge with rotating animation
class StarBadge extends StatefulWidget {
  final Color color;
  final IconData icon;

  const StarBadge({super.key, required this.color, required this.icon});

  @override
  State<StarBadge> createState() => _StarBadgeState();
}

class _StarBadgeState extends State<StarBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [widget.color, widget.color.withOpacity(0.1)],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            // Rotating stars
            Transform.rotate(
              angle: _controller.value * 2 * math.pi,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.2),
                ),
                child: Stack(
                  children: List.generate(5, (index) {
                    return Positioned(
                      left: 30 + 25 * math.cos(index * math.pi * 2 / 5),
                      top: 30 + 25 * math.sin(index * math.pi * 2 / 5),
                      child: Icon(Icons.star, color: widget.color, size: 12),
                    );
                  }),
                ),
              ),
            ),
            // Main icon
            Icon(widget.icon, size: 35, color: widget.color),
          ],
        );
      },
    );
  }
}

// Pulsating badge for Syabas achievement
class PulsatingBadge extends StatefulWidget {
  final Color color;
  final IconData icon;

  const PulsatingBadge({super.key, required this.color, required this.icon});

  @override
  State<PulsatingBadge> createState() => _PulsatingBadgeState();
}

class _PulsatingBadgeState extends State<PulsatingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.2),
            border: Border.all(
              color: widget.color.withOpacity(0.5 + 0.5 * _controller.value),
              width: 3 + 2 * _controller.value,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3 * _controller.value),
                blurRadius: 12,
                spreadRadius: 2 + 3 * _controller.value,
              ),
            ],
          ),
          child: Icon(widget.icon, size: 30, color: widget.color),
        );
      },
    );
  }
}
