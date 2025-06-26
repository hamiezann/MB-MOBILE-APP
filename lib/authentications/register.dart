import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:math_buddy_v1/authentications/login.dart';
import 'package:math_buddy_v1/pages/home.dart';
import 'package:math_buddy_v1/pages/teacher/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String _selectedRole = 'student';
  String _studentId = '';
  final TextEditingController _teacherIdController = TextEditingController();
  final TextEditingController _classIdController = TextEditingController();
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

  Future<void> _saveUserSession(String userId, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('role', role);
  }

  void _registerUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final username = _usernameController.text.trim();
    final classIdInput = _classIdController.text.trim();

    // Email validation
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(email)) {
      _showAlert("Email Tidak Sah", "Sila masukkan emel yang sah.");
      return;
    }

    // Password validation: At least one uppercase, one lowercase, one symbol (.,_,,), min 6 characters
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[.,_]).{6,}$');
    if (!passwordRegex.hasMatch(password)) {
      _showAlert(
        "Kata Laluan Lemah",
        "Kata laluan mesti mempunyai sekurang-kurangnya satu huruf besar, satu huruf kecil dan satu simbol (.,_).",
      );
      return;
    }

    if (password != confirmPassword) {
      _showAlert(
        "Kata Laluan Tidak Sama",
        "Kata laluan tidak sepadan. Sila cuba lagi.",
      );
      return;
    }

    String userId = '';
    String? classId;

    if (_selectedRole == 'student') {
      final randomNum = DateTime.now().millisecondsSinceEpoch % 10000;
      userId = 'STUDENT_$randomNum';
    } else {
      userId = _teacherIdController.text.trim();
      if (userId.isEmpty) {
        _showAlert("ID Guru Diperlukan", "Sila masukkan ID guru.");
        return;
      }
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final userData = {
        'username': username,
        'email': email,
        'role': _selectedRole,
        'id': userId,
        // 'score': {
        //   'kenal_objek': '0/10',
        //   'susun_nombor': '0/10',
        //   'mengira_tambah': '0/10',
        //   'mengira_tolak': '0/10',
        //   'wang': '0/10',
        //   'masa': '0/10',
        // },
        if (_selectedRole == 'student') 'teacher_no': '',
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      await _saveUserSession(userId, _selectedRole);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  _selectedRole == 'teacher' ? TeacherHomePage() : HomePage(),
        ),
      );
    } catch (e) {
      _showAlert("Ralat", e.toString());
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // _buildLabel("Peranan", screenWidth),
                              // Row(
                              //   mainAxisAlignment:
                              //       MainAxisAlignment.spaceEvenly,
                              //   children: [
                              //     ChoiceChip(
                              //       label: const Text("Pelajar"),
                              //       selected: _selectedRole == 'student',
                              //       onSelected: (selected) {
                              //         if (selected) {
                              //           setState(() {
                              //             _selectedRole = 'student';
                              //           });
                              //         }
                              //       },
                              //     ),
                              //     ChoiceChip(
                              //       label: const Text("Guru"),
                              //       selected: _selectedRole == 'teacher',
                              //       onSelected: (selected) {
                              //         if (selected) {
                              //           setState(() {
                              //             _selectedRole = 'teacher';
                              //           });
                              //         }
                              //       },
                              //     ),
                              //   ],
                              // ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  color: Colors.grey.shade100,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedRole = 'student';
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          curve: Curves.easeInOut,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 20,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            color:
                                                _selectedRole == 'student'
                                                    ? Colors.lightBlue
                                                    // Theme.of(
                                                    //   context,
                                                    // ).primaryColor
                                                    : Colors.transparent,
                                            boxShadow:
                                                _selectedRole == 'student'
                                                    ? [
                                                      BoxShadow(
                                                        color: Theme.of(context)
                                                            .primaryColor
                                                            .withOpacity(0.3),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ]
                                                    : [],
                                          ),
                                          child: Center(
                                            child: AnimatedDefaultTextStyle(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              style: TextStyle(
                                                color:
                                                    _selectedRole == 'student'
                                                        ? Colors.white
                                                        : Colors.grey.shade700,
                                                fontWeight:
                                                    _selectedRole == 'student'
                                                        ? FontWeight.w600
                                                        : FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                              child: const Text("Pelajar"),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedRole = 'teacher';
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          curve: Curves.easeInOut,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 20,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            color:
                                                _selectedRole == 'teacher'
                                                    ? Colors.amber
                                                    : Colors.transparent,
                                            boxShadow:
                                                _selectedRole == 'teacher'
                                                    ? [
                                                      BoxShadow(
                                                        color: Theme.of(context)
                                                            .primaryColor
                                                            .withOpacity(0.3),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ]
                                                    : [],
                                          ),
                                          child: Center(
                                            child: AnimatedDefaultTextStyle(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              style: TextStyle(
                                                color:
                                                    _selectedRole == 'teacher'
                                                        ? Colors.white
                                                        : Colors.grey.shade700,
                                                fontWeight:
                                                    _selectedRole == 'teacher'
                                                        ? FontWeight.w600
                                                        : FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                              child: const Text("Guru"),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_selectedRole == 'teacher')
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("No Pekerja", screenWidth),
                                    SizedBox(height: 10),
                                    _buildTextField(_teacherIdController),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),

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

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(message, style: const TextStyle(fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ok', style: TextStyle(color: Colors.amber)),
              ),
            ],
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
