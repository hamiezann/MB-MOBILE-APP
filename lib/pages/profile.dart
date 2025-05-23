import 'package:flutter/material.dart';
import 'package:math_buddy_v1/authentications/login.dart';
import 'package:math_buddy_v1/components/button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:math_buddy_v1/components/reusable-modal.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('username')) {
          usernameController.text = data['username'];
        }
        if (data != null && data.containsKey('email')) {
          emailController.text = data['email'];
        }
      }
    }
  }

  void _confirmDeleteAccount() {
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Padam Akaun'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sila masukkan kata laluan untuk mengesahkan pemadaman akaun.',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Kata Laluan'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                _showDeleteConfirmDialog(passwordController.text);
              },
              child: const Text('Sahkan'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(String password) {
    final rootContext = context; // capture context before any await
    showDialog(
      context: rootContext,
      builder: (context) {
        return ConfirmationDialog(
          title: 'Pengesahan',
          message: 'Adakah anda pasti mahu padam akaun ini?',
          onCancel: () => Navigator.pop(context),
          onConfirm: () async {
            Navigator.pop(context);
            await deleteUserAccount(
              rootContext,
              password,
            ); // pass the root context
          },
        );
      },
    );
  }

  void toggleEditing() async {
    if (isEditing) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String currentEmail = user.email!;
        String newEmail = emailController.text.trim();
        String newUsername = usernameController.text.trim();

        try {
          if (newEmail != currentEmail) {
            String? password = await _promptPassword();
            if (password == null || password.isEmpty) return;

            AuthCredential credential = EmailAuthProvider.credential(
              email: currentEmail,
              password: password,
            );
            await user.reauthenticateWithCredential(credential);
            await user.updateEmail(newEmail);
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'username': newUsername,
                'email': newEmail,
              }, SetOptions(merge: true));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profil berjaya dikemaskini!")),
          );
        } on FirebaseAuthException catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Ralat: ${e.message}")));
          return;
        }
      }
    }

    setState(() {
      isEditing = !isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.lightBlue.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.08,
                vertical: screenHeight * 0.05,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PROFIL',
                    style: TextStyle(
                      fontSize: screenHeight * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Container(
                    width: screenHeight * 0.18,
                    height: screenHeight * 0.18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      image: DecorationImage(
                        image: AssetImage('assets/profile-picture.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  _buildTextField(
                    "Nama Pengguna",
                    usernameController,
                    isEditing,
                  ),
                  SizedBox(height: screenHeight * 0.025),
                  if (!isEditing)
                    _buildTextField("E-mel", emailController, isEditing),
                  if (!isEditing) SizedBox(height: screenHeight * 0.025),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: isEditing ? "SIMPAN PERUBAHAN" : "EDIT",
                          color: const Color.fromARGB(255, 73, 209, 237),
                          onTap: toggleEditing,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.05),
                      Expanded(
                        child: CustomButton(
                          text:
                              isEditing ? "BATALKAN PERUBAHAN" : "PADAM AKAUN",
                          color:
                              isEditing
                                  ? Colors.white
                                  : const Color.fromARGB(255, 243, 105, 95),
                          onTap: () {
                            if (isEditing) {
                              _loadUserData();
                              setState(() {
                                isEditing = false;
                              });
                            } else {
                              _confirmDeleteAccount();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isEditable,
  ) {
    return TextField(
      controller: controller,
      readOnly: !isEditable,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }

  Future<String?> _promptPassword() async {
    TextEditingController passwordController = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Masukkan Kata Laluan"),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: "Kata Laluan"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, passwordController.text),
              child: Text("Sahkan"),
            ),
          ],
        );
      },
    );
  }
}

Future<void> deleteUserAccount(BuildContext context, String password) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null && user.email != null) {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      await user.delete();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          Future.delayed(const Duration(seconds: 3), () {
            Navigator.of(context).pop();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          });

          return AlertDialog(
            title: const Text('Akaun Dipadam'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Akaun anda telah dipadam.'),
                SizedBox(height: 20),
                CircularProgressIndicator(),
              ],
            ),
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text("Ralat"),
              content: Text("Gagal memadam akaun: ${e.message}"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
      );
    }
  }
}
