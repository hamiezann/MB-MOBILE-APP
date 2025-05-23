import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:math_buddy_v1/authentications/login.dart';
import 'package:math_buddy_v1/pages/home.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _fadeController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _logoSlideAnimation;
  late Animation<double> _fadeAnimation;

  bool showButtons = false;
  bool logoAtTop = false; // Track when logo reaches top

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
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Animation sequence
    Future.delayed(Duration(seconds: 3), () {
      _scaleController.stop();
      _slideController.forward().whenComplete(() {
        setState(() {
          logoAtTop = true; // Set logoAtTop to true when slide finishes
        });
      });

      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          showButtons = true;
        });
        _fadeController.forward();
      });
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double slideDistance = screenHeight * 0.35; // Adjusted to prevent overflow

    _logoSlideAnimation = Tween<double>(begin: 0, end: -slideDistance).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // **BACKGROUND GRADIENT**
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlue.shade200, Colors.lightGreen.shade200],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // **LOGO ANIMATION**
          AnimatedBuilder(
            animation: _logoSlideAnimation,
            builder: (context, child) {
              return Positioned(
                top: screenHeight * 0.3 + _logoSlideAnimation.value,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Image.asset(
                    'assets/mathbuddy-nbg.png',
                    width:
                        logoAtTop
                            ? screenWidth * 0.75
                            : screenWidth * 0.6, // 3/4 width when at top
                  ),
                ),
              );
            },
          ),

          // **BUTTONS & TEXT**
          if (showButtons)
            Positioned(
              bottom: screenHeight * 0.1, // Ensures good spacing
              child: Column(
                children: [
                  // **BACKGROUND IMAGE**
                  Container(
                    width: screenWidth * 0.9,
                    height: screenHeight * 0.25, // Adjust height if needed
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/math-nbg.png'),
                        fit: BoxFit.contain, // Ensure no overflow
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.2),

                  // **FADE-IN TEXT**
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width:
                          screenWidth *
                          0.9, // Use more width to allow better wrapping
                      alignment: Alignment.center,
                      child: Text(
                        "Pembelajaran Matematik yang Menyeronokkan & Mudah untuk Semua!",
                        textAlign: TextAlign.center,
                        softWrap: true,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize:
                              screenWidth *
                              0.06, // Adjust font size for better wrapping
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 50),

                  // **"Tap to Start" TEXT**
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      "Tekan untuk Mula",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  SizedBox(height: 10),

                  // **START BUTTON**
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.15,
                          vertical: screenHeight * 0.02,
                        ),
                        textStyle: TextStyle(
                          fontSize: screenWidth * 0.07,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: Text("Mula"),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
