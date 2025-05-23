import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const CustomButton({
    required this.text,
    required this.color,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      width: 200, // Fixed width for uniform button size
      height: screenHeight * 0.1, // Fixed height for uniform button size
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color, // White background
          foregroundColor: Color.fromARGB(255, 52, 42, 243), // Blue text
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
            side: BorderSide(color: Colors.white, width: 2), // White border
          ),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: TextStyle(fontSize: screenWidth * 0.045),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
