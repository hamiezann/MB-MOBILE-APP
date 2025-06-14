import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:math_buddy_v1/authentications/login.dart';
import 'package:math_buddy_v1/pages/home.dart';
import 'package:math_buddy_v1/pages/teacher/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  Future<Widget> _getPageBasedOnRole(User user) async {
    final prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('role');

    if (role == null) {
      // Fetch from Firestore
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data();
        role = data?['role'] ?? 'student';
        await prefs.setString('role', role!); // Cache it
      } else {
        role = 'student';
      }
    }

    if (role == 'teacher') {
      return TeacherHomePage();
    } else {
      return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return FutureBuilder<Widget>(
            future: _getPageBasedOnRole(snapshot.data!),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else if (roleSnapshot.hasData) {
                return roleSnapshot.data!;
              } else {
                return const LoginPage();
              }
            },
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
