import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:math_buddy_v1/authentications/login.dart';
import 'dart:async'; // Add this at the top
import 'package:math_buddy_v1/components/sidebar.dart';
import 'package:math_buddy_v1/models/chapter_model.dart';
import 'package:math_buddy_v1/pages/chapters-tutorial/chapter.dart';
import 'package:math_buddy_v1/pages/chapters-tutorial/subtopic_page.dart';
import 'package:math_buddy_v1/pages/profile.dart';
import 'package:math_buddy_v1/pages/progress.dart';
import 'package:math_buddy_v1/components/reusable-modal.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Chapter? _selectedChapter;
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

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

    // Wait for a short duration to allow the dialog to build
    await Future.delayed(Duration(milliseconds: 100));

    // Perform sign out
    await FirebaseAuth.instance.signOut();

    // Dismiss loading
    Navigator.of(context).pop();

    // Navigate to login page
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
        return shouldExit; // true = exit app, false = stay
      },
      // onWillPop: _showExitDialog,
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
            _selectedChapter != null
                ? SubtopicPage(chapter: _selectedChapter!)
                : PageView(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    TopicPage(onChapterSelected: _navigateToSubtopicPage),
                    ProfilePage(),
                    ProgressPage(),
                  ],
                ),
      ),
    );
  }

  // Future<bool> _showExitDialog() async {
  //   return await showDialog(
  //         context: context,
  //         builder:
  //             (context) => AlertDialog(
  //               title: const Text('Exit App'),
  //               content: const Text('Are you sure you want to exit the app?'),
  //               actions: [
  //                 TextButton(
  //                   onPressed: () => Navigator.of(context).pop(false),
  //                   child: const Text('Cancel'),
  //                 ),
  //                 TextButton(
  //                   onPressed: () => Navigator.of(context).pop(true),
  //                   child: const Text('Exit'),
  //                 ),
  //               ],
  //             ),
  //       ) ??
  //       false; // fallback false if dialog is dismissed
  // }
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
