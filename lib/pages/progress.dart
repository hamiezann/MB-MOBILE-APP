import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:math_buddy_v1/pages/animated_badge.dart';

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
    final quizAttempts = Map<String, dynamic>.from(
      userData['quiz_attempts'] ?? {},
    );

    final scores = <String, String>{};
    final badges = <String, String>{};
    final dynamicChapters = <String>[];
    final attemptsInfo = <String, List<Map<String, dynamic>>>{};

    for (var quizKey in teacherQuizzes.keys) {
      final info = Map<String, dynamic>.from(teacherQuizzes[quizKey] ?? {});
      final quizId = info['quiz_id'];

      if (quizId != null) {
        final chapterSnapshot =
            await FirebaseFirestore.instance
                .collection('chapters')
                .where('owner_id', isEqualTo: teacherNo)
                .get();

        for (var chapter in chapterSnapshot.docs) {
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

            if (quizAttempts.containsKey(quizKey)) {
              final attemptsRaw = quizAttempts[quizKey] as List;
              final parsedAttempts =
                  attemptsRaw.map((e) => Map<String, dynamic>.from(e)).toList();
              attemptsInfo[quizTitle] = parsedAttempts;
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
      'attempts': attemptsInfo,
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
              final attempts =
                  snapshot.data!['attempts'] as Map<String, List<dynamic>>;

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
              final rawChapters = snapshot.data!['chapters'] as List ?? [];
              final chapterKeys =
                  rawChapters.whereType<String>().toList() ?? [];

              final chapters = Map.fromEntries(
                chapterKeys.map(
                  (key) => MapEntry(allChapterLabels[key] ?? key, key),
                ),
              );
              return Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + 10),
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
                              final chapterAttempts =
                                  (attempts[key] ?? [])
                                      .cast<Map<String, dynamic>>();
                              return _buildProgressCard(
                                displayName,
                                score,
                                badge,
                                chapterAttempts,
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
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Trophy avatar with animation/shimmer
              _buildAnimatedTrophy(context, earnedBadges),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jumlah Skor',
                      style: TextStyle(
                        fontSize: 13,
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
                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Anda telah memperoleh $earnedBadges lencana!',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Info icon at top right
        Positioned(
          right: 15,
          top: 10,
          child: IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.blue),
            tooltip: 'Maklumat Lencana',
            onPressed: () => _showBadgeInfoDialog(context),
          ),
        ),
      ],
    );
  }

  void _showBadgeInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 3),
                Text(
                  'Maklumat Lencana',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  _buildBadgeRow(
                    'assets/badge/lvl1.png',
                    'Cuba Lagi',
                    'Markah kurang daripada 50%',
                  ),
                  _buildBadgeRow(
                    'assets/badge/lvl2.png',
                    'Bagus',
                    'Markah 50% hingga 69%',
                  ),
                  _buildBadgeRow(
                    'assets/badge/lvl3.png',
                    'Syabas',
                    'Markah 70% hingga 99%',
                  ),
                  _buildBadgeRow(
                    'assets/badge/lvl3.png',
                    'Cemerlang',
                    'Markah penuh untuk kuiz tersebut',
                  ),
                  _buildBadgeRow(
                    'assets/badge/lvl4.png',
                    'Legenda',
                    'Markah penuh untuk semua 3 percubaan',
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    '🧠 Kumpul semua lencana untuk setiap topik!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Jika anda berjaya dapat semua lencana tahap tertinggi, anda akan mendapat sijil penghargaan dan dibuka ganjaran khas!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
            actions: [
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  label: const Text('Mari Kumpul Lebih Banyak Lencana!'),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildBadgeRow(String assetPath, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Image.asset(assetPath, height: 40, width: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getBadgeAssetPath(String badge) {
    switch (badge) {
      case 'Cemerlang':
        return 'assets/badge/lvl3.png';
      case 'Syabas':
        return 'assets/badge/lvl3.png';
      case 'Bagus':
        return 'assets/badge/lvl2.png';
      case 'Cuba Lagi':
        return 'assets/badge/lvl1.png';
      default:
        return 'assets/badge/lvl1.png'; // fallback
    }
  }

  void _showAttemptsDialog(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> attempts,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                const Icon(Icons.history, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sejarah Percubaan - $title',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  attempts.isEmpty
                      ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Tiada percubaan direkodkan.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: attempts.length,
                        itemBuilder: (context, index) {
                          final attempt = attempts[attempts.length - 1 - index];
                          final score = attempt['score'] ?? 'N/A';
                          final badge = attempt['badge'] ?? '-';
                          final timestamp = attempt['timestamp'];
                          final formattedDate =
                              timestamp != null
                                  ? DateTime.tryParse(timestamp)
                                          ?.toLocal()
                                          .toString()
                                          .split('.')[0]
                                          .replaceFirst(' ', ' @ ') ??
                                      'Tidak diketahui'
                                  : 'Tidak diketahui';

                          // Determine badge image path
                          final badgeImage = _getBadgeAssetPath(badge);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: AssetImage(badgeImage),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Skor: $score',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        'Lencana: $badge',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Tutup'),
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

  Widget _buildProgressCard(
    String title,
    String score,
    String badge,
    List<Map<String, dynamic>> attempts,
    context,
  ) {
    // final badgeIcon = _getBadgeIcon(badge);
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
              // ? _buildBadgeDisplay(badgeIcon, badgeColor, badge)
              ? _buildBadgeDisplay(badge, attempts)
              : CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey.shade200,
                child: Image.asset('assets/badge/lvl1.png'),
              ),
          // : CircleAvatar(
          //   radius: 30,
          //   backgroundColor: Colors.grey.shade200,
          //   child: Icon(badgeIcon, size: 30, color: badgeColor),
          // ),
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
          TextButton.icon(
            onPressed: () => _showAttemptsDialog(context, title, attempts),
            icon: const Icon(Icons.history, size: 18),
            label: const Text('Lihat Percubaan'),
          ),
        ],
      ),
    );
  }

  // Widget _buildBadgeDisplay(IconData icon, Color color, String badge) {
  //   // Return different animations based on badge level
  //   if (badge == 'Cemerlang') {
  //     return StarBadge(color: color, icon: icon);
  //   } else if (badge == 'Syabas') {
  //     return PulsatingBadge(color: color, icon: icon);
  //   } else {
  //     return CircleAvatar(
  //       radius: 30,
  //       backgroundColor: color.withOpacity(0.2),
  //       child: Icon(icon, size: 30, color: color),
  //     );
  //   }
  // }

  bool _isLevel4Badge(List<Map<String, dynamic>> attempts) {
    if (attempts.length < 3) return false;

    for (var attempt in attempts.take(3)) {
      final score = attempt['score'] ?? '';
      final parts = score.split('/');
      if (parts.length != 2) return false;

      final earned = int.tryParse(parts[0]) ?? 0;
      final total = int.tryParse(parts[1]) ?? 0;

      if (earned != total || total == 0) return false;
    }

    return true;
  }

  Widget _buildBadgeDisplay(String badge, List<Map<String, dynamic>> attempts) {
    String assetPath;

    if (_isLevel4Badge(attempts)) {
      assetPath = 'assets/badge/lvl4.png';
      return AnimatedBadge(imagePath: assetPath, isLevel4: true);
    } else {
      switch (badge) {
        case 'Cemerlang':
          assetPath = 'assets/badge/lvl3.png';
          break;
        case 'Syabas':
          assetPath = 'assets/badge/lvl3.png';
          break;
        case 'Bagus':
          assetPath = 'assets/badge/lvl2.png';
          break;
        case 'Cuba Lagi':
          assetPath = 'assets/badge/lvl1.png';
          break;
        default:
          assetPath = 'assets/badge/lvl1.png';
      }
      return AnimatedBadge(imagePath: assetPath, isLevel4: false);
    }

    // return CircleAvatar(
    //   radius: 30,
    //   backgroundColor: Colors.transparent,
    //   backgroundImage: AssetImage(assetPath),
    // );
  }

  Widget _buildScoreIndicator(String score, Color badgeColor, bool hasBadge) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Circular progress indicator
            SizedBox(
              width: 50,
              height: 50,
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: hasBadge ? badgeColor : Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // IconData _getBadgeIcon(String badge) {
  //   switch (badge) {
  //     case 'Cuba Lagi':
  //       return Icons.replay;
  //     case 'Bagus':
  //       return Icons.thumb_up;
  //     case 'Syabas':
  //       return Icons.emoji_events;
  //     case 'Cemerlang':
  //       return Icons.star;
  //     default:
  //       return Icons.emoji_events_outlined;
  //   }
  // }

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
