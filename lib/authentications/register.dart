import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:math_buddy_v1/authentications/login.dart';
import 'package:math_buddy_v1/pages/home.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      });
    }
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Terma dan Perkhidmatan"),
            content: const SingleChildScrollView(
              child: Text(
                "1. Anda mesti mematuhi semua peraturan\n"
                "2. Tidak dibenarkan berkongsi data peribadi.\n"
                "3. Penyalahgunaan akaun akan menyebabkan penggantungan.\n"
                "4. Terma mungkin dikemas kini pada bila-bila masa.",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Tutup"),
              ),
            ],
          ),
    );
  }

  void _registerUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final username = _usernameController.text.trim();

    if (password != confirmPassword) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Kata Laluan Tidak Sama'),
              content: const Text('Kata laluan tidak sepadan. Sila cuba lagi.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ok'),
                ),
              ],
            ),
      );
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'username': username,
            'email': email,
            'score': {
              'kenal_objek': '0/10',
              'susun_nombor': '0/10',
              'mengira_tambah': '0/10',
              'mengira_tolak': '0/10',
              'wang': '0/10',
              'masa': '0/10',
            },
          });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Error'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ok'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.lightBlue.shade200,
                    Colors.lightGreen.shade200,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: screenHeight * 0.05),
                          Column(
                            children: [
                              Text(
                                "Cipta",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.09,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(255, 52, 42, 243),
                                ),
                              ),
                              Text(
                                "Akaun",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.09,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(255, 52, 42, 243),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.04),

                          // Username
                          _buildLabel("Nama Pengguna", screenWidth),
                          SizedBox(height: screenHeight * 0.01),
                          _buildTextField(_usernameController),

                          SizedBox(height: screenHeight * 0.025),

                          // Email
                          _buildLabel("Alamat Emel", screenWidth),
                          SizedBox(height: screenHeight * 0.01),
                          _buildTextField(_emailController, isEmail: true),

                          SizedBox(height: screenHeight * 0.025),

                          // Password
                          _buildLabel("Kata Laluan", screenWidth),
                          SizedBox(height: screenHeight * 0.01),
                          _buildTextField(
                            _passwordController,
                            isPassword: true,
                          ),

                          SizedBox(height: screenHeight * 0.025),

                          // Confirm Password
                          _buildLabel("Sahkan Kata Laluan", screenWidth),
                          SizedBox(height: screenHeight * 0.01),
                          _buildTextField(
                            _confirmPasswordController,
                            isPassword: true,
                          ),
                          SizedBox(height: screenHeight * 0.025),

                          SizedBox(height: screenHeight * 0.025),

                          // Terms checkbox
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _agreeToTerms,
                                onChanged: (value) {
                                  setState(() => _agreeToTerms = value!);
                                },
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _showTermsAndConditions,
                                  child: Text(
                                    "Saya bersetuju dengan Terma dan Perkhidmatan",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.045,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: screenHeight * 0.02),

                          // Sign Up Button
                          SizedBox(
                            width: screenWidth * 0.5,
                            child: ElevatedButton(
                              onPressed: _agreeToTerms ? _registerUser : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _agreeToTerms
                                        ? const Color.fromARGB(
                                          255,
                                          73,
                                          209,
                                          237,
                                        )
                                        : Colors.grey,
                                foregroundColor: const Color.fromARGB(
                                  255,
                                  52,
                                  42,
                                  243,
                                ),
                                padding: EdgeInsets.symmetric(vertical: 20),
                                textStyle: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                ),
                              ),
                              child: const Text("DAFTAR AKAUN"),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.025),

                          // Already have an account?
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Sudah ada akaun?"),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Log masuk di sini",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(String text, double screenWidth) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(left: screenWidth * 0.03),
        child: Text(
          text,
          style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    bool isEmail = false,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      obscureText: isPassword,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.lightBlue[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
