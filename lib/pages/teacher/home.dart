import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:path/path.dart' as path;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:math_buddy_v1/authentications/login.dart';
import 'package:math_buddy_v1/pages/teacher/ManageQuizzes.dart';
import 'package:math_buddy_v1/pages/teacher/SubtopicContentPage.dart';
import 'package:math_buddy_v1/pages/teacher/reusable%20loading.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _chapters = [];
  List<Map<String, dynamic>> _quiz = [];
  Map<String, dynamic>? _user;
  int _videoCOunt = 0;
  bool _loading = true;
  final List<Map<String, dynamic>> _chapter_status = [
    {'status': 'published'},
    {'status': 'draft'},
  ];

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _fetchChapters();
    _fetchQuiz();
    _fetchUserData();
  }

  // Future<void> _fetchStudents() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final querySnapshot =
  //       await FirebaseFirestore.instance
  //           .collection('users')
  //           .where('role', isEqualTo: 'student')
  //           .where(
  //             'teacher_no',
  //             isEqualTo: FirebaseAuth.instance.currentUser!.uid,
  //           )
  //           .get();
  //   setState(() {
  //     _students =
  //         querySnapshot.docs.map((doc) {
  //           final data = doc.data() as Map<String, dynamic>;
  //           data['uid'] = doc.id; // Firestore document ID
  //           return data;
  //         }).toList();
  //     _loading = false;
  //   });
  // }

  Future<void> _fetchStudents() async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where(
              'teacher_no',
              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
            )
            .get();

    setState(() {
      _students =
          querySnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['uid'] = doc.id;

            // Only extract teacher_quiz marks
            final teacherQuiz =
                data['teacher_quiz'] as Map<String, dynamic>? ?? {};

            // Optional: Flatten teacher_quiz to show quiz_name and score if needed
            final Map<String, dynamic> teacherQuizScores = {};
            for (final entry in teacherQuiz.entries) {
              final quizName = entry.key;
              final quizData = entry.value as Map<String, dynamic>;
              final quizScore =
                  data['score']?[quizName]; // Fetch score from main 'score' map
              teacherQuizScores[quizName] = quizScore ?? 'N/A';
            }

            data['teacher_quiz_scores'] =
                teacherQuizScores; // For UI display or use
            return data;
          }).toList();

      _loading = false;
    });
  }

  Future<void> _fetchChapters() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snapshot =
        await FirebaseFirestore.instance
            .collection('chapters')
            .where('owner_id', isEqualTo: uid)
            .get();

    int videoCount = 0;
    List<Map<String, dynamic>> chapters = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;

      final videosSnapshot = await doc.reference.collection('videos').get();
      if (videosSnapshot.docs.isNotEmpty) {
        videoCount++;
      }

      chapters.add(data);
    }

    setState(() {
      _chapters = chapters;
      _videoCOunt = videoCount;
    });

    debugPrint('Number of chapters with videos: $videoCount');
  }

  Future<void> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (doc.exists) {
      setState(() {
        _user = doc.data()!..['id'] = doc.id; // optional: add 'id' field
      });
    }
  }

  Future<void> _fetchQuiz() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final chaptersSnapshot =
        await FirebaseFirestore.instance
            .collection('chapters')
            .where('owner_id', isEqualTo: uid)
            .get();

    List<Map<String, dynamic>> allQuizzes = [];

    for (var chapterDoc in chaptersSnapshot.docs) {
      final quizzesSnapshot =
          await chapterDoc.reference.collection('quizzes').get();

      for (var quizDoc in quizzesSnapshot.docs) {
        final data = quizDoc.data();
        data['id'] = quizDoc.id;
        data['chapterId'] = chapterDoc.id; // optional, in case you need it
        allQuizzes.add(data);
      }
    }

    setState(() {
      _quiz = allQuizzes;
    });
  }

  Future<void> deleteImageIfExists(String? imageUrl) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(imageUrl);
        await ref.delete();
      } catch (e) {
        debugPrint("Failed to delete chapter image: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            _fetchStudents();
          } else if (index == 2) {
            _fetchChapters();
          }
        },
        children: [
          _buildOverviewPage(),
          _buildStudentsPage(),
          _buildChaptersPage(),
          _buildContentPage(),
          // _buildProfilePage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final titles = ['Dashboard', 'Pelajar', 'Bab', 'Kandungan'];

    return AppBar(
      backgroundColor: Colors.blue.shade600,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        titles[_selectedIndex],
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        // IconButton(
        //   icon: const Icon(Icons.notifications_outlined),
        //   onPressed: () {
        //     _showNotifications();
        //   },
        // ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            _showLogoutConfirmation();
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue.shade600,
      unselectedItemColor: Colors.grey.shade600,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pelajar'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Bab'),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle),
          label: 'Kandungan',
        ),
        // BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }

  // OVERVIEW PAGE
  Widget _buildOverviewPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildStatsGrid(),
          const SizedBox(height: 20),
          _buildQuickActions(),
          // const SizedBox(height: 20),
          // _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selamat Datang!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cikgu ${_user?['username']}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Email: ${_user?['email']}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.today, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'Hari ini: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(
          'Jumlah Pelajar',
          '${_students.length}',
          Icons.people,
          Colors.green,
        ),
        _buildStatCard(
          'Bab Aktif',
          '${_chapters.length}',
          Icons.book,
          Colors.orange,
        ),
        _buildStatCard(
          'Quiz Dibuat',
          '${_quiz.length}',
          Icons.quiz,
          Colors.purple,
        ),
        _buildStatCard(
          'Video Upload',
          '${_videoCOunt}',
          Icons.video_library,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tindakan Pantas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Tambah Bab',
                Icons.book_outlined,
                Colors.blue,
                () => _showAddChapterDialog(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Buat Quiz',
                Icons.quiz_outlined,
                Colors.purple,
                () => _showAddQuizDialog(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Upload Video',
                Icons.video_call_outlined,
                Colors.red,
                () => _showAddVideoDialog(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Urus Pelajar',
                Icons.people_outlined,
                Colors.green,
                () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aktiviti Terkini',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                'Ahmad Syafiq telah selesaikan Quiz Nombor',
                '2 jam yang lalu',
                Icons.quiz,
                Colors.green,
              ),
              _buildActivityItem(
                'Siti Aisyah memulakan Bab Kenal Objek',
                '4 jam yang lalu',
                Icons.play_circle,
                Colors.blue,
              ),
              _buildActivityItem(
                'Muhammad Ali menghantar tugasan',
                '1 hari yang lalu',
                Icons.assignment_turned_in,
                Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STUDENTS PAGE
  Widget _buildStudentsPage() {
    return Container(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari pelajar...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showAddStudentDialog,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchStudents,
              child:
                  _students.isEmpty
                      ? const Center(child: Text("Tiada Pelajar"))
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          // print(student);
                          return _buildStudentCard(student);
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final scoreMap =
        (student['teacher_quiz_scores'] as Map<String, dynamic>?) ?? {};
    int totalMarks = 0;
    int obtainedMarks = 0;

    scoreMap.forEach((key, value) {
      final parts = value.split('/');
      if (parts.length == 2) {
        obtainedMarks += int.tryParse(parts[0]) ?? 0;
        totalMarks += int.tryParse(parts[1]) ?? 0;
      }
    });

    final percentage = totalMarks > 0 ? (obtainedMarks / totalMarks) : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.white]),
        ),
        child: ExpansionTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              (student['username'] ?? 'P')[0].toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade600,
              ),
            ),
          ),
          title: Text(
            student['username'] ?? 'No name',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${student['email'] ?? ''}\nAktif',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$obtainedMarks/$totalMarks',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 60,
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage > 0.7 ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ...scoreMap.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key.replaceAll('_', ' ').toUpperCase()),
                          Text(entry.value),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showStudentDetails(student),
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                        ),
                        label: const Text('Lihat Butiran'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade500,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            () => _showRemoveStudentConfirmation(
                              context,
                              student,
                            ),
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: const Text('Keluarkan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
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
    );
  }

  // CHAPTERS PAGE
  Widget _buildChaptersPage() {
    return Container(
      // onRefresh:  _fetchChapters,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Pengurusan Bab',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddChapterDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Bab Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchChapters,
              child:
                  _chapters.isEmpty
                      ? const Center(child: Text("Tiada Bab"))
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = _chapters[index];
                          return _buildChapterCard(chapter);
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(Map<String, dynamic> chapter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      chapter['imagePath'] != null
                          ? CachedNetworkImage(
                            imageUrl: chapter['imagePath'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            errorWidget:
                                (context, url, error) => Icon(
                                  Icons.book,
                                  color: Colors.blue.shade600,
                                  size: 24,
                                ),
                          )
                          : Icon(
                            Icons.book,
                            color: Colors.blue.shade600,
                            size: 24,
                          ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chapter['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  chapter['status'] == 'published'
                                      ? Colors.green.shade100
                                      : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              chapter['status'] == 'published'
                                  ? 'Diterbitkan'
                                  : 'Draf',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    chapter['status'] == 'published'
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        chapter['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                _buildChapterStat(
                  Icons.topic,
                  '${chapter['subtopics']} Subtopik',
                  Colors.blue,
                ),
                // const SizedBox(width: 16),
                // _buildChapterStat(
                //   Icons.quiz,
                //   '${chapter['quizzes']} Quiz',
                //   Colors.purple,
                // ),
                const SizedBox(width: 16),
                _buildChapterStat(
                  Icons.video_library,
                  '${chapter['videos']} Video',
                  Colors.red,
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditChapterDialog(chapter);
                        break;
                      case 'subtopics':
                        _showSubtopicsDialog(chapter);
                        break;
                      case 'videos':
                        _showChapterVideosDialog(chapter);
                        break;
                      case 'quizzes':
                        _showChapterQuizzesDialog(chapter);
                        break;
                      case 'delete':
                        _showDeleteChapterConfirmation(context, chapter);
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit Bab'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'subtopics',
                          child: Row(
                            children: [
                              Icon(Icons.list),
                              SizedBox(width: 8),
                              Text('Urus Subtopik'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'videos',
                          child: Row(
                            children: [
                              Icon(Icons.video_library),
                              SizedBox(width: 8),
                              Text('Urus Video'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'quizzes',
                          child: Row(
                            children: [
                              Icon(Icons.quiz),
                              SizedBox(width: 8),
                              Text('Urus Quiz'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Padam',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterStat(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  // CONTENT PAGE
  Widget _buildContentPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tambah Kandungan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final cardHeight =
                  width / 2 * 1.2; // Adjust height based on width

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: width / (2 * cardHeight), // wider/taller
                children: [
                  _buildContentCard(
                    'Tambah Bab',
                    'Cipta bab pembelajaran baru',
                    Icons.book_outlined,
                    Colors.blue,
                    _showAddChapterDialog,
                  ),
                  _buildContentCard(
                    'Tambah Subtopik',
                    'Pecahkan bab kepada subtopik',
                    Icons.topic_outlined,
                    Colors.green,
                    _showAddSubtopicDialog,
                  ),
                  _buildContentCard(
                    'Buat Quiz',
                    'Cipta kuiz untuk penilaian',
                    Icons.quiz_outlined,
                    Colors.purple,
                    _showAddQuizDialog,
                  ),
                  _buildContentCard(
                    'Upload Video',
                    'Muat naik video pembelajaran',
                    Icons.video_call_outlined,
                    Colors.red,
                    _showAddVideoDialog,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 140,
          maxHeight: 180, // Limit height to prevent overflow
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width < 350 ? 8 : 16,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // PROFILE PAGE
  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cikgu Ahmad Rahman',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'ahmad.rahman@sekolah.edu.my',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildProfileStat('Pelajar', '${_students.length}'),
                    _buildProfileStat('Bab', '${_chapters.length}'),
                    _buildProfileStat('Quiz', '${_quiz.length}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildProfileMenu(),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade600,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildProfileMenu() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileMenuItem(
            Icons.edit,
            'Edit Profil',
            'Kemaskini maklumat peribadi',
            () => _showEditProfileDialog(),
          ),
          _buildProfileMenuItem(
            Icons.settings,
            'Tetapan',
            'Konfigurasi aplikasi',
            () => _showSettingsDialog(),
          ),
          _buildProfileMenuItem(
            Icons.help,
            'Bantuan',
            'Panduan dan sokongan',
            () => _showHelpDialog(),
          ),
          _buildProfileMenuItem(
            Icons.logout,
            'Log Keluar',
            'Keluar dari aplikasi',
            () => _showLogoutConfirmation(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.shade100 : Colors.blue.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red.shade600 : Colors.blue.shade600,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red.shade600 : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // Dialog Functions
  void _showAddChapterDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    File? selectedImage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 16,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    constraints: const BoxConstraints(maxHeight: 600),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blue.shade50, Colors.white],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade600,
                                Colors.blue.shade400,
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.book_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tambah Bab Baru',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Content
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Title Field
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade200,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: titleController,
                                    decoration: InputDecoration(
                                      labelText: 'Tajuk Bab',
                                      labelStyle: TextStyle(
                                        color: Colors.blue.shade600,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ),

                                // Description Field
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade200,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: descController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      labelText: 'Penerangan',
                                      labelStyle: TextStyle(
                                        color: Colors.blue.shade600,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ),

                                // Image Picker
                                _buildFilePickerCard(
                                  title: 'Pilih Imej Bab',
                                  icon: Icons.image_outlined,
                                  file: selectedImage,
                                  // onTap: () async {
                                  //   await _pickImage((file) {
                                  //     setState(() {
                                  //       selectedImage = file;
                                  //     });
                                  //   });
                                  // },
                                  onTap: () async {
                                    final picked = await ImagePicker()
                                        .pickImage(source: ImageSource.gallery);
                                    if (picked != null) {
                                      setState(
                                        () => selectedImage = File(picked.path),
                                      );
                                    }
                                  },
                                  color: Colors.blueAccent,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Actions
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  'Batal',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () async {
                                  final title = titleController.text.trim();
                                  final desc = descController.text.trim();
                                  final uid =
                                      FirebaseAuth.instance.currentUser?.uid;

                                  if (title.isNotEmpty && uid != null) {
                                    String? imageUrl;
                                    LoadingDialog.show(
                                      context,
                                      title: 'Memuat naik kandungan...',
                                      subtitle: 'Sila tunggu sebentar',
                                    );

                                    if (selectedImage != null) {
                                      imageUrl = await uploadChapterImage(
                                        selectedImage!,
                                      );
                                      if (imageUrl == null) {
                                        LoadingDialog.hide();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Row(
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Gagal memuat naik imej'),
                                              ],
                                            ),
                                            backgroundColor:
                                                Colors.orangeAccent,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                    }

                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('chapters')
                                          .add({
                                            'title': title,
                                            'description': desc,
                                            'owner_id': uid,
                                            'created_at':
                                                FieldValue.serverTimestamp(),
                                            'status': 'draft',
                                            'subtopics': 0,
                                            'quizzes': 0,
                                            'videos': 0,
                                            'imagePath': imageUrl ?? '',
                                          });

                                      LoadingDialog.hide();
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Bab berjaya ditambah!'),
                                            ],
                                          ),
                                          backgroundColor: Colors.lightGreen,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      LoadingDialog.hide();
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Ralat: $e')),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_box_outlined,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Tambah',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void _showAddSubtopicDialog() {
    final outerContext = context;
    if (_chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sila tambah bab terlebih dahulu')),
      );
      return;
    }

    String? selectedChapter;
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    File? selectedImage;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    constraints: const BoxConstraints(maxHeight: 600),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blue.shade50, Colors.white],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Gradient Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade600,
                                Colors.green.shade400,
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.book_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tambah Subtopik Baru',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Dialog Content
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade200,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Pilih Bab',
                                      labelStyle: TextStyle(
                                        color: Colors.green.shade600,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                    value: selectedChapter,
                                    items:
                                        _chapters.map((chapter) {
                                          return DropdownMenuItem<String>(
                                            value: chapter['id'],
                                            child: Text(chapter['title']),
                                          );
                                        }).toList(),
                                    onChanged:
                                        (value) => setState(
                                          () => selectedChapter = value,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade200,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: titleController,
                                    decoration: InputDecoration(
                                      labelText: 'Tajuk Subtopik',
                                      labelStyle: TextStyle(
                                        color: Colors.green.shade600,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade200,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: descController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      labelText: 'Penerangan',
                                      labelStyle: TextStyle(
                                        color: Colors.green.shade600,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildFilePickerCard(
                                  title: 'Pilih Imej Bab',
                                  icon: Icons.image_outlined,
                                  file: selectedImage,
                                  onTap: () async {
                                    final picked = await ImagePicker()
                                        .pickImage(source: ImageSource.gallery);
                                    if (picked != null) {
                                      setState(
                                        () => selectedImage = File(picked.path),
                                      );
                                    }
                                  },
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Dialog Actions
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  'Batal',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () async {
                                  if (selectedChapter != null &&
                                      titleController.text.isNotEmpty &&
                                      selectedImage != null) {
                                    Navigator.pop(context);

                                    try {
                                      final userId =
                                          FirebaseAuth
                                              .instance
                                              .currentUser!
                                              .uid;
                                      final imageRef = FirebaseStorage.instance.ref(
                                        'contents/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg',
                                      );
                                      LoadingDialog.show(
                                        context,
                                        title: 'Memuat naik kandungan...',
                                        subtitle: 'Sila tunggu sebentar',
                                      );

                                      await imageRef.putFile(selectedImage!);
                                      final imageUrl =
                                          await imageRef.getDownloadURL();

                                      await FirebaseFirestore.instance
                                          .collection('chapters')
                                          .doc(selectedChapter)
                                          .collection('subtopics')
                                          .add({
                                            'title': titleController.text,
                                            'description': descController.text,
                                            'imageUrl': imageUrl,
                                            'ownerId': userId,
                                            'chapterId': selectedChapter,
                                            'createdAt':
                                                FieldValue.serverTimestamp(),
                                          });

                                      await FirebaseFirestore.instance
                                          .collection('chapters')
                                          .doc(selectedChapter)
                                          .update({
                                            'subtopics': FieldValue.increment(
                                              1,
                                            ),
                                          });
                                      LoadingDialog.hide();
                                      ScaffoldMessenger.of(
                                        outerContext,
                                      ).showSnackBar(
                                        SnackBar(
                                          // content: Text(
                                          //   'Subtopik berjaya ditambah!',
                                          // ),
                                          content: const Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Subtopik berjaya ditambah!',
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.lightGreen,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        outerContext,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Ralat: ${e.toString()}',
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(
                                      outerContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Sila lengkapkan semua maklumat!',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_box_outlined,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Tambah',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void _showAddQuizDialog() async {
    final chaptersSnapshot =
        await FirebaseFirestore.instance
            .collection('chapters')
            .orderBy('title')
            .get();

    final chapters = chaptersSnapshot.docs;

    if (chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila tambah bab terlebih dahulu')),
      );
      return;
    }

    String? selectedChapterId;
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 16,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    constraints: const BoxConstraints(maxHeight: 600),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blue.shade50, Colors.white],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.shade600,
                                Colors.purple.shade400,
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.quiz_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tambah Quiz Baru',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Content
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Chapter Dropdown
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade200,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Pilih Bab',
                                      labelStyle: TextStyle(
                                        color: Colors.purple.shade600,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                    value: selectedChapterId,
                                    items:
                                        // chapters.map((doc) {
                                        //   final data =
                                        //       doc.data()
                                        //           as Map<String, dynamic>;
                                        //   return DropdownMenuItem<String>(
                                        //     value: doc.id,
                                        //     child: Text(
                                        //       data['title'] ?? 'Tiada tajuk',
                                        //     ),
                                        //   );
                                        // }).toList(),
                                        _chapters.map((chapter) {
                                          return DropdownMenuItem<String>(
                                            value: chapter['id'],
                                            child: Text(chapter['title']),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedChapterId = value;
                                      });
                                    },
                                  ),
                                ),

                                // Title
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade200,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: titleController,
                                    decoration: InputDecoration(
                                      labelText: 'Tajuk Quiz',
                                      labelStyle: TextStyle(
                                        color: Colors.purple.shade600,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ),

                                // Description
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade200,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: descController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      labelText: 'Penerangan',
                                      labelStyle: TextStyle(
                                        color: Colors.purple.shade600,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Actions
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  'Batal',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () async {
                                  final title = titleController.text.trim();
                                  final desc = descController.text.trim();

                                  if (selectedChapterId != null &&
                                      title.isNotEmpty) {
                                    try {
                                      LoadingDialog.show(
                                        context,
                                        title: 'Memuat naik kandungan...',
                                        subtitle: 'Sila tunggu sebentar',
                                      );
                                      await FirebaseFirestore.instance
                                          .collection('chapters')
                                          .doc(selectedChapterId)
                                          .collection('quizzes')
                                          .add({
                                            'title': title,
                                            'description': desc,
                                            'chapterId': selectedChapterId,
                                            'createdAt': Timestamp.now(),
                                          });

                                      LoadingDialog.hide();
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          // content: Text('Quiz berjaya dibuat!'),
                                          content: const Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Quiz berjaya dibuat!'),
                                            ],
                                          ),
                                          backgroundColor: Colors.lightGreen,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Ralat: $e')),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Sila pilih bab dan isi tajuk quiz.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_box_outlined,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Tambah',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void _showAddVideoDialog() async {
    if (_chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila tambah bab terlebih dahulu')),
      );
      return;
    }

    final chaptersSnapshot =
        await FirebaseFirestore.instance
            .collection('chapters')
            .orderBy('title')
            .get();
    final chapters = chaptersSnapshot.docs;
    if (chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila tambah bab terlebih dahulu')),
      );
      return;
    }

    String? selectedChapter;
    File? selectedVideo;
    String? videoFileName;
    final TextEditingController titleController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 16,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    constraints: const BoxConstraints(maxHeight: 600),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blue.shade50, Colors.white],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade600,
                                Colors.red.shade400,
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.video_collection, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Muat Naik Video',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Form
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Chapter dropdown
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Pilih Bab',
                                    labelStyle: TextStyle(
                                      color: Colors.red.shade600,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                  value: selectedChapter,
                                  items:
                                      // chapters.map((doc) {
                                      //   final data =
                                      //       doc.data() as Map<String, dynamic>;
                                      //   return DropdownMenuItem<String>(
                                      //     value: doc.id,
                                      //     child: Text(
                                      //       data['title'] ?? 'Tiada tajuk',
                                      //     ),
                                      //   );
                                      // }).toList(),
                                      _chapters.map((chapter) {
                                        return DropdownMenuItem<String>(
                                          value: chapter['id'],
                                          child: Text(chapter['title']),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedChapter = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Video title
                                TextField(
                                  controller: titleController,
                                  decoration: InputDecoration(
                                    labelText: 'Tajuk Video',
                                    labelStyle: TextStyle(
                                      color: Colors.red.shade600,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Video picker button
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.video_file),
                                  label: Text(
                                    selectedVideo != null
                                        ? 'Video: $videoFileName'
                                        : 'Pilih Fail Video',
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  onPressed: () async {
                                    final result = await FilePicker.platform
                                        .pickFiles(type: FileType.video);
                                    if (result != null &&
                                        result.files.single.path != null) {
                                      setState(() {
                                        selectedVideo = File(
                                          result.files.single.path!,
                                        );
                                        videoFileName = path.basename(
                                          result.files.single.path!,
                                        );
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Buttons
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Batal',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.upload_file,
                                  color: Colors.white,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                label: const Text('Muat Naik'),
                                onPressed: () async {
                                  final title = titleController.text.trim();

                                  if (selectedChapter != null &&
                                      selectedVideo != null &&
                                      title.isNotEmpty) {
                                    try {
                                      LoadingDialog.show(
                                        context,
                                        title: 'Memuat naik video...',
                                        subtitle: 'Sila tunggu sebentar',
                                      );

                                      final videoId =
                                          FirebaseFirestore.instance
                                              .collection('tmp')
                                              .doc()
                                              .id;

                                      final storageRef = FirebaseStorage
                                          .instance
                                          .ref()
                                          .child(
                                            'chapters/$selectedChapter/videos/$videoId.mp4',
                                          );

                                      final uploadTask = await storageRef
                                          .putFile(selectedVideo!);
                                      final downloadUrl =
                                          await uploadTask.ref.getDownloadURL();

                                      await FirebaseFirestore.instance
                                          .collection('chapters')
                                          .doc(selectedChapter)
                                          .collection('videos')
                                          .doc(videoId)
                                          .set({
                                            'title': title,
                                            'url': downloadUrl,
                                            'chapterId': selectedChapter,
                                            'createdAt': Timestamp.now(),
                                          });

                                      LoadingDialog.hide();
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          // content: Text(
                                          //   'Video berjaya dimuat naik!',
                                          // ),
                                          content: const Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Video berjaya dimuat naik!',
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.lightGreen,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      LoadingDialog.hide();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Ralat: $e')),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Sila pilih bab, video dan tajuk.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void _showAddStudentDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tambah Pelajar'),
            content: TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Pelajar',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) return;

                  // Query Firestore for the student by email
                  final query =
                      await FirebaseFirestore.instance
                          .collection('users')
                          .where('email', isEqualTo: email)
                          .limit(1)
                          .get();

                  if (query.docs.isEmpty) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pelajar tidak dijumpai.')),
                    );
                    return;
                  }

                  final studentDoc = query.docs.first;
                  final studentData = studentDoc.data();

                  if (studentData['role'] != 'student') {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hanya pelajar boleh ditambah.'),
                      ),
                    );
                    return;
                  }

                  if (studentData.containsKey('teacher_no') &&
                      studentData['teacher_no'] != '') {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        // content: Text(
                        //   'Pelajar sudah didaftarkan dalam kelas lain.',
                        // ),
                        content: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Pelajar sudah didaftarkan dalam kelas lain.'),
                          ],
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    return;
                  }

                  final teacherId = FirebaseAuth.instance.currentUser?.uid;

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(studentDoc.id)
                      .update({
                        'teacher_no': FirebaseAuth.instance.currentUser!.uid,
                      });
                  // .update({'teacher_no': teacherId});

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      // content: Text('Pelajar berjaya ditambah ke kelas!'),
                      content: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Pelajar berjaya ditambah ke kelas!'),
                        ],
                      ),
                      backgroundColor: Colors.lightGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
                child: const Text('Tambah'),
              ),
            ],
          ),
    );
  }

  void _showEditChapterDialog(Map<String, dynamic> chapter) {
    final TextEditingController titleController = TextEditingController(
      text: chapter['title'],
    );
    final TextEditingController descController = TextEditingController(
      text: chapter['description'],
    );
    String? status = chapter['status'];
    File? selectedImage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 16,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    constraints: const BoxConstraints(maxHeight: 600),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blue.shade50, Colors.white],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade600,
                                Colors.blue.shade400,
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.book_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Edit Bab',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade200,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: titleController,
                                    decoration: InputDecoration(
                                      labelText: 'Tajuk Bab',
                                      labelStyle: TextStyle(
                                        color: Colors.blue.shade600,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade200,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: descController,
                                    decoration: InputDecoration(
                                      labelText: 'Penerangan',
                                      labelStyle: TextStyle(
                                        color: Colors.blue.shade600,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                    maxLines: 3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Status Bab',
                                    labelStyle: TextStyle(
                                      color: Colors.blue.shade600,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                  value: status,
                                  items:
                                      _chapter_status.map((chapter) {
                                        return DropdownMenuItem<String>(
                                          value: chapter['status'],
                                          child: Text(
                                            chapter['status']
                                                .toString()
                                                .toUpperCase(),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      status = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildFilePickerCard(
                                  title: 'Pilih Imej Bab',
                                  icon: Icons.image_outlined,
                                  file: selectedImage,
                                  onTap: () async {
                                    final picked = await ImagePicker()
                                        .pickImage(source: ImageSource.gallery);
                                    if (picked != null) {
                                      setState(
                                        () => selectedImage = File(picked.path),
                                      );
                                    }
                                  },
                                  color: Colors.green,
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: Text(
                                        'Batal',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final title =
                                            titleController.text.trim();
                                        final desc = descController.text.trim();
                                        final uid =
                                            FirebaseAuth
                                                .instance
                                                .currentUser
                                                ?.uid;

                                        if (title.isNotEmpty && uid != null) {
                                          String? imageUrl;
                                          LoadingDialog.show(
                                            context,
                                            title: 'Memuat naik kandungan...',
                                            subtitle: 'Sila tunggu sebentar',
                                          );
                                          // If a new image is selected
                                          if (selectedImage != null) {
                                            // Delete old image
                                            if (chapter['imagePath'] != null &&
                                                chapter['imagePath']
                                                    .toString()
                                                    .startsWith('https://')) {
                                              try {
                                                final ref = FirebaseStorage
                                                    .instance
                                                    .refFromURL(
                                                      chapter['imagePath'],
                                                    );
                                                await ref.delete();
                                              } catch (e) {
                                                debugPrint(
                                                  'Failed to delete old image: $e',
                                                );
                                              }
                                            }

                                            // Upload new image
                                            imageUrl = await uploadChapterImage(
                                              selectedImage!,
                                            );
                                            if (imageUrl == null) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Gagal memuat naik imej.',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                          }

                                          try {
                                            final updateData = {
                                              'title': title,
                                              'description': desc,
                                              'status': status ?? '',
                                            };
                                            if (imageUrl != null) {
                                              updateData['imagePath'] =
                                                  imageUrl;
                                            }

                                            await FirebaseFirestore.instance
                                                .collection('chapters')
                                                .doc(chapter['id'])
                                                .update(updateData);
                                            LoadingDialog.hide();
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: const Row(
                                                  children: [
                                                    Icon(
                                                      Icons.info_outline,
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'bab berjaya dikemaskini!!',
                                                    ),
                                                  ],
                                                ),
                                                backgroundColor:
                                                    Colors.lightGreen,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            Navigator.pop(context);
                                            LoadingDialog.hide();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('Ralat: $e'),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 4,
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_box_outlined,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Kemaskini',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void _showSubtopicsDialog(Map<String, dynamic> chapter) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              constraints: const BoxConstraints(maxHeight: 500),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade50, Colors.white],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade400],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.topic_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Subtopik - ${chapter['title']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FutureBuilder<QuerySnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('chapters')
                                .doc(chapter['id'])
                                .collection('subtopics')
                                .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(strokeWidth: 3),
                                    SizedBox(height: 16),
                                    Text(
                                      'Memuatkan subtopik...',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Container(
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade400,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Ralat memuatkan subtopik',
                                      style: TextStyle(
                                        color: Colors.red.shade600,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final subtopics = snapshot.data?.docs ?? [];

                          if (subtopics.isEmpty) {
                            return Container(
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder_open_outlined,
                                      color: Colors.grey.shade400,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Tiada subtopik untuk bab ini',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: subtopics.length,
                            itemBuilder: (context, index) {
                              final sub = subtopics[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade100,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    sub['title'] ?? 'Tiada tajuk',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle:
                                      sub['description'] != null &&
                                              sub['description']
                                                  .toString()
                                                  .isNotEmpty
                                          ? Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              sub['description'],
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )
                                          : null,
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey.shade400,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    Navigator.pop(
                                      context,
                                    ); // Close dialog first
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => SubtopicContentPage(
                                              chapterId: chapter['id'],
                                              subtopicId: sub.id,
                                              subtopicTitle: sub['title'],
                                            ),
                                      ),
                                    );
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showChapterVideosDialog(Map<String, dynamic> chapter) {
    VideoPlayerController? _controller;
    ChewieController? _chewieController;
    String? _videoUrl;
    bool _loading = true;

    final chapterId = chapter['id'];

    void fetchVideo(VoidCallback rebuild) async {
      try {
        final videoSnapshot =
            await FirebaseFirestore.instance
                .collection('chapters')
                .doc(chapterId)
                .collection('videos')
                .limit(1)
                .get();

        if (videoSnapshot.docs.isNotEmpty) {
          final videoDoc = videoSnapshot.docs.first;
          final videoData = videoDoc.data();
          final videoPath = videoData['url'];

          if (videoPath == null || videoPath.toString().trim().isEmpty) {
            _loading = false;
            rebuild();
            return;
          }

          String downloadUrl;
          if (videoPath.startsWith('http')) {
            downloadUrl = videoPath;
          } else {
            downloadUrl =
                await FirebaseStorage.instance.ref(videoPath).getDownloadURL();
          }

          _controller = VideoPlayerController.networkUrl(
            Uri.parse(downloadUrl),
          );
          await _controller!.initialize();
          _chewieController = ChewieController(
            videoPlayerController: _controller!,
            autoPlay: true,
            looping: false,
          );
          _videoUrl = downloadUrl;
          _loading = false;
          rebuild();
        } else {
          _loading = false;
          rebuild();
        }
      } catch (e) {
        print("Error loading video: $e");
        _loading = false;
        rebuild();
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (_loading && _videoUrl == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                fetchVideo(() => setState(() {}));
              });
            }

            return AlertDialog(
              title: Text('Video - ${chapter['title']}'),
              content: SizedBox(
                width: 300,
                height: 300,
                child:
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : (_chewieController != null)
                        ? Chewie(controller: _chewieController!)
                        : const Text('Tiada video dimuat naik.'),
              ),
              actions: [
                if (_videoUrl != null)
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Adakah anda pasti untuk padam video ini?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Batal'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await _controller?.dispose();
                                          _chewieController?.dispose();

                                          final snapshot = await FirebaseFirestore
                                              .instance
                                              .collection('chapters')
                                              .doc(chapterId)
                                              .collection('videos')
                                              .get()
                                              .then((snapshot) async {
                                                if (snapshot.docs.isNotEmpty) {
                                                  final doc =
                                                      snapshot.docs.first;
                                                  final data = doc.data();
                                                  final videoUrl = data['url'];

                                                  if (videoUrl != null &&
                                                      videoUrl
                                                          .toString()
                                                          .trim()
                                                          .isNotEmpty) {
                                                    try {
                                                      final ref =
                                                          FirebaseStorage
                                                              .instance
                                                              .refFromURL(
                                                                videoUrl,
                                                              );
                                                      await ref.delete();
                                                    } catch (e) {
                                                      print(
                                                        'Error deleting video from storage: $e',
                                                      );
                                                    }
                                                  }

                                                  await doc.reference.delete();
                                                }
                                              });

                                          _controller = null;
                                          _chewieController = null;
                                          _videoUrl = null;
                                          _loading = false;
                                          setState(() {});
                                        },
                                        child: const Text(
                                          'Padam',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: const Text(
                      'Padam Video',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final video = await picker.pickVideo(
                      source: ImageSource.gallery,
                    );

                    if (video != null) {
                      // Delete old video if exists
                      final oldVideoSnapshot =
                          await FirebaseFirestore.instance
                              .collection('chapters')
                              .doc(chapterId)
                              .collection('videos')
                              .get();

                      if (oldVideoSnapshot.docs.isNotEmpty) {
                        final oldDoc = oldVideoSnapshot.docs.first;
                        final path = oldDoc['url'];
                        if (path != null && path.toString().trim().isNotEmpty) {
                          try {
                            final storagePath =
                                path.startsWith('http')
                                    ? Uri.decodeComponent(
                                      Uri.parse(path).pathSegments.last,
                                    )
                                    : path;
                            await FirebaseStorage.instance
                                .ref(storagePath)
                                .delete();
                          } catch (_) {}
                        }
                        await oldDoc.reference.delete();
                      }
                      try {
                        LoadingDialog.show(
                          context,
                          title: 'Memuat naik video...',
                          subtitle: 'Sila tunggu sebentar',
                        );
                        final fileName =
                            FirebaseFirestore.instance
                                .collection('tmp')
                                .doc()
                                .id;
                        // '${DateTime.now().millisecondsSinceEpoch}_${video.name}';
                        final storageRef = FirebaseStorage.instance.ref(
                          // 'chapter_videos/$chapterId/$fileName',
                          'chapters/$chapterId/videos/$fileName.mp4',
                        );
                        await storageRef.putFile(File(video.path));
                        final newUrl = await storageRef.getDownloadURL();
                        final title = chapterId;
                        await FirebaseFirestore.instance
                            .collection('chapters')
                            .doc(chapterId)
                            .collection('videos')
                            .add({
                              'title': title,
                              'url': newUrl,
                              'chapterId': chapterId,
                              'createdAt': Timestamp.now(),
                            });
                        _controller?.dispose();
                        _chewieController?.dispose();
                        _controller = null;
                        _chewieController = null;
                        _videoUrl = null;
                        _loading = true;
                        setState(() {});

                        LoadingDialog.hide();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Video berjaya dimuat naik!'),
                              ],
                            ),
                            backgroundColor: Colors.lightGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      } catch (e) {
                        LoadingDialog.hide();
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Ralat: $e')));
                      }
                    }
                  },
                  child: Text(
                    _videoUrl != null ? 'Tukar Video' : 'Muat Naik Video',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _controller?.dispose();
                    _chewieController?.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChapterQuizzesDialog(Map<String, dynamic> chapter) async {
    final chapterId = chapter['id'];
    final topicSnapshot =
        await FirebaseFirestore.instance
            .collection('chapters')
            .doc(chapterId)
            .collection('quizzes')
            .get();

    final quizzes = topicSnapshot.docs;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              constraints: const BoxConstraints(maxHeight: 500),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade50, Colors.white],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade400],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.quiz_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Quiz - ${chapter['title']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child:
                          quizzes.isEmpty
                              ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.quiz_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tiada Quiz Didaftarkan.',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                              : ListView.builder(
                                shrinkWrap: true,
                                itemCount: quizzes.length,
                                itemBuilder: (context, index) {
                                  final doc = quizzes[index];
                                  final quiz = doc.data();

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.shade100,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        quiz['title'] ?? 'Tiada tajuk',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      trailing: ElevatedButton(
                                        // onPressed:
                                        //     () => _navigateToManageQuiz(
                                        //       chapterId,
                                        //       doc.id,
                                        //     ),
                                        onPressed: () async {
                                          Navigator.pop(
                                            context,
                                          ); // Close the dialog first
                                          _navigateToManageQuiz(
                                            chapterId,
                                            doc.id,
                                          );
                                          setState(
                                            () {},
                                          ); // Trigger UI refresh (if this method is inside a stateful widget)
                                        },

                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade400,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Urus'),
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _navigateToManageQuiz(String topicId, String quizId) {
    print("id: $topicId");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ManageQuizContentPage(chapterId: topicId, quizId: quizId),
      ),
    );
  }

  Future<void> _showDeleteChapterConfirmation(
    BuildContext context,
    Map<String, dynamic> chapter,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.red.shade50, Colors.white],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_forever,
                      color: Colors.red.shade600,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Padam Bab',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Adakah anda pasti ingin memadam bab "${chapter['title']}" dan semua kandungannya? Tindakan ini tidak boleh dibatalkan.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Padam',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );

    if (confirm != true) return;
    setState(() {
      _chapters.removeWhere((c) => c['id'] == chapter['id']);
    });

    try {
      final chapterId = chapter['id'];

      await deleteImageIfExists(chapter['imagePath']);

      final subtopicsSnapshot =
          await FirebaseFirestore.instance
              .collection('chapters')
              .doc(chapterId)
              .collection('subtopics')
              .get();

      for (final subtopicDoc in subtopicsSnapshot.docs) {
        final subtopicRef = subtopicDoc.reference;

        final contentsSnapshot = await subtopicRef.collection('contents').get();

        for (final contentDoc in contentsSnapshot.docs) {
          final content = contentDoc.data();
          await deleteImageIfExists(content['imageUrl1']);
          await deleteImageIfExists(content['imageUrl2']);
          await deleteImageIfExists(content['audioUrl']);
          await contentDoc.reference.delete();
        }

        await subtopicRef.delete();
      }

      await FirebaseFirestore.instance
          .collection('chapters')
          .doc(chapterId)
          .delete();

      _fetchChapters();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bab dan semua kandungan berjaya dipadam!',
                  maxLines: 2,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Gagal memadam bab: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Detail - ${student['username']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${student['email']}'),
                Text('No Pelajar: ${student['id']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  void _showSendMessageDialog(Map<String, dynamic> student) {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Hantar Mesej - ${student['username']}'),
            content: TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Mesej',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (messageController.text.isNotEmpty) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Mesej berjaya dihantar!'),
                          ],
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Hantar'),
              ),
            ],
          ),
    );
  }

  Future<void> _showRemoveStudentConfirmation(
    BuildContext context,
    Map<String, dynamic> student,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.red.shade50, Colors.white],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_forever,
                      color: Colors.red.shade600,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Padam Bab',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Adakah anda pasti ingin memadam bab "${student['username']}"?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Padam',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(student['uid'])
          .update({'teacher_no': ''});
      _fetchStudents(); // Refresh list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Pelajar berjaya dikeluarkan!', maxLines: 2),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Gagal mengeluarkan pelajar: ${e.toString()}',
                  maxLines: 2,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Profil'),
            content: const Text(
              'Dialog untuk mengedit profil akan dipaparkan di sini.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tetapan'),
            content: const Text(
              'Dialog untuk tetapan akan dipaparkan di sini.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bantuan'),
            content: const Text(
              'Dialog untuk bantuan akan dipaparkan di sini.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Notifikasi'),
            content: const Text('Tiada notifikasi baru.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  double _parseScore(String score) {
    try {
      final parts = score.split('/');
      if (parts.length == 2) {
        final obtained = int.tryParse(parts[0]) ?? 0;
        final total = int.tryParse(parts[1]) ?? 10;
        return obtained / total;
      }
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Log Keluar'),
            content: const Text('Adakah anda pasti ingin log keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close the dialog

                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (_) => const Center(child: CircularProgressIndicator()),
                  );

                  // Sign out and clear shared prefs
                  await FirebaseAuth.instance.signOut();
                  setState(() {
                    _students = [];
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  // Navigate to login page
                  Navigator.of(context).pop(); // Dismiss loading
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Log Keluar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Future<String?> uploadChapterImage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'chapter_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Widget _buildFilePickerCard({
    required String title,
    required IconData icon,
    required File? file,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () async {
        final granted = await _requestStoragePermission();
        if (granted) {
          onTap();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Sila benarkan akses storan untuk memuat naik fail.'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      },
      child: Card(
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child:
                    file == null
                        ? Text(title, style: TextStyle(color: color))
                        : Image.file(file, height: 80, fit: BoxFit.cover),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _requestStoragePermission() async {
    // For Android 13 and above
    if (await Permission.photos.request().isGranted) {
      return true;
    }

    // For below Android 13
    if (await Permission.storage.request().isGranted) {
      return true;
    }

    return false;
  }
}
