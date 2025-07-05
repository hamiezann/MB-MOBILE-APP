import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:math_buddy_v1/root_page.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kReleaseMode
            ? AndroidProvider
                .debug // Use for production
            : AndroidProvider.debug, // Use for development
  );

  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    print('User is authenticated: ${currentUser.uid}');
  } else {
    print('No user is authenticated.');
  }

  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user == null) {
      print('User is signed out.');
    } else {
      print('User is signed in: ${user.uid}');
    }
  });
  runApp(MyApp());
}

// class FirebaseAppCheck {}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Buddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RootPage(),
    );
  }
}
