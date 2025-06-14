import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:math_buddy_v1/authentications/login.dart';
import 'dart:async'; // Add this at the top
import 'package:math_buddy_v1/components/sidebar.dart';
import 'package:math_buddy_v1/models/chapter_model.dart';
import 'package:math_buddy_v1/pages/audio_helper.dart';
import 'package:math_buddy_v1/pages/chapters-tutorial/chapter.dart';
import 'package:math_buddy_v1/pages/chapters-tutorial/subtopic_page.dart';
import 'package:math_buddy_v1/pages/profile.dart';
import 'package:math_buddy_v1/pages/progress.dart';
import 'package:math_buddy_v1/components/reusable-modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Chapter? _selectedChapter;
  final PageController _pageController = PageController();
  int _selectedIndex = 0;
  String? teacherNo;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherNo();
  }

  Future<void> _loadTeacherNo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        teacherNo = doc.data()?['teacher_no'];
        isLoading = false;
      });
    }
    // print('store teacher no $teacherNo');
  }

  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedChapter = null;
    });
    _pageController.jumpToPage(index);
  }

  void _handleLogout() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    await Future.delayed(Duration(milliseconds: 100));
    await FirebaseAuth.instance.signOut();
    await AudioCacheHelper.clearAllCachedAudio();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.of(context).pop();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _navigateToSubtopicPage(Chapter chapter) {
    setState(() {
      _selectedChapter = chapter;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return WillPopScope(
      onWillPop: () async {
        bool shouldExit = await _showExitDialog();
        return shouldExit;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.blue,

          toolbarHeight: MediaQuery.of(context).size.height * 0.09,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'MATHBUDDY',
                style: TextStyle(
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          leading: Builder(
            builder:
                (context) => IconButton(
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: const Icon(Icons.menu, size: 40),
                ),
          ),
        ),

        drawer: SizedBox(
          width: MediaQuery.of(context).size.width * 0.60,
          child: Sidebar(
            onItemSelected: _navigateToPage,
            onLogout: _handleLogout,
          ),
        ),

        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedChapter != null
                ? SubtopicPage(chapter: _selectedChapter!, teacherNo: teacherNo)
                : PageView(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    TopicPage(
                      onChapterSelected: _navigateToSubtopicPage,
                      teacherNo: teacherNo,
                    ),
                    ProfilePage(),
                    ProgressPage(),
                  ],
                ),
      ),
    );
  }

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return ConfirmationDialog(
              title: 'Keluar Aplikasi',
              message: 'Adakah anda pasti mahu keluar dari aplikasi?',
              onConfirm: () {
                Navigator.of(context).pop(true); // Return true to exit
              },
              onCancel: () {
                Navigator.of(context).pop(false); // Return false to cancel exit
              },
            );
          },
        ) ??
        false; // Return false if dialog is dismissed
  }
}
