import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:math_buddy_v1/authentications/forgot_password.dart';
import 'package:math_buddy_v1/authentications/register.dart';
import 'package:math_buddy_v1/authentications/role.dart';
import 'package:math_buddy_v1/pages/home.dart';
import 'package:math_buddy_v1/pages/teacher/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _selectedRole = 'student';
  // bool _roleManuallySelected = false;

  // @override
  // void initState() {
  //   super.initState();
  //   if (FirebaseAuth.instance.currentUser != null) {
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (context) => const HomePage()),
  //       );
  //     });
  //   }
  // }

  // @override
  // void initState() {
  //   super.initState();
  //   _checkLoggedInUser();
  // }

  // void _checkLoggedInUser() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user != null) {
  //     final doc =
  //         await FirebaseFirestore.instance
  //             .collection('users')
  //             .doc(user.uid)
  //             .get();
  //     final data = doc.data();

  //     if (data != null && data.containsKey('role')) {
  //       final role = data['role'];
  //       final prefs = await SharedPreferences.getInstance();
  //       await prefs.setString('role', role);
  //       await prefs.setString('id', data['id'] ?? '');
  //       await prefs.setString('teacher_no', data['teacher_no'] ?? '');

  //       if (!mounted) return;

  //       if (role == 'teacher') {
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(builder: (_) => const TeacherHomePage()),
  //         );
  //       } else {
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(builder: (_) => const HomePage()),
  //         );
  //       }
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlue.shade200, Colors.lightGreen.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.08,
              vertical: screenHeight * 0.04,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Selamat\nKembali!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.09,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 52, 42, 243),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                RoleSelector(
                  selectedRole: _selectedRole,
                  onRoleChanged: (role) {
                    setState(() {
                      _selectedRole = role;
                      // _roleManuallySelected = true;
                    });
                  },
                ),
                SizedBox(height: 20),
                // Email Label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Alamat Emel',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),

                // Email Input
                FractionallySizedBox(
                  widthFactor: 1.0,
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.lightBlue[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                // Password Label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Kata Laluan',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),

                // Password Input
                FractionallySizedBox(
                  widthFactor: 1.0,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.lightBlue[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),

                // Sign In Button
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : ElevatedButton(
                            onPressed: _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                73,
                                209,
                                237,
                              ),
                              foregroundColor: const Color.fromARGB(
                                255,
                                52,
                                42,
                                243,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: const Text("LOG MASUK"),
                          ),
                ),
                SizedBox(height: screenHeight * 0.03),

                // Footer buttons
                Wrap(
                  alignment: WrapAlignment.center,
                  runSpacing: 10,
                  spacing: 20,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgotPasswordPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Lupa Kata Laluan?",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Belum ada akaun? Daftar",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    print("selected role $_selectedRole");
    // return;
    setState(() => _isLoading = true);
    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sila masukkan emel dan kata laluan')),
        );
        return;
      }

      // if (!_roleManuallySelected) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('Sila pilih peranan anda (Pelajar/Guru).'),
      //     ),
      //   );
      //   setState(() => _isLoading = false);
      //   return;
      // }

      // Step 1: Sign in with Firebase Auth
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final String uid = userCredential.user!.uid;

      // Step 2: Fetch user document (allowed by your Firestore rules)
      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akaun tidak dijumpai di Firestore.')),
        );
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final String actualRole = userData['role'] ?? '';
      final String id = userData['id'] ?? '';
      final String teacherNo = userData['teacher_no'] ?? '';
      print("actual role: $actualRole");
      // Step 3: Cross-check selected role
      if (_selectedRole != actualRole) {
        String roleMessage =
            _selectedRole == 'student'
                ? 'Emel ini bukan pelajar berdaftar.'
                : 'Emel ini bukan guru berdaftar.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(roleMessage)));
        await FirebaseAuth.instance.signOut(); // Log out if role mismatch
        return;
      } else {
        // Step 4: Save role info to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', actualRole);
        await prefs.setString('id', id);
        await prefs.setString('teacher_no', teacherNo);
        await prefs.setString('last_selected_role', _selectedRole);

        // Step 5: Navigate based on role
        if (actualRole == 'teacher') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => TeacherHomePage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'user-not-found' => 'Tiada pengguna dijumpai dengan emel tersebut.',
        'wrong-password' => 'Kata laluan tidak sah.',
        _ => 'Log masuk gagal. ${e.message}',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
