import 'package:flutter/material.dart';

class AnimatedBadge extends StatefulWidget {
  final String imagePath;
  final bool isLevel4;

  const AnimatedBadge({
    super.key,
    required this.imagePath,
    this.isLevel4 = false,
  });

  @override
  State<AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<AnimatedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnim = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        widget.isLevel4
            ? Colors.purpleAccent.withOpacity(_glowAnim.value)
            : Colors.blueAccent.withOpacity(_glowAnim.value);

    final shadowColor =
        widget.isLevel4
            ? Colors.pinkAccent.withOpacity(_glowAnim.value)
            : Colors.lightBlue.withOpacity(_glowAnim.value);

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: widget.isLevel4 ? 30 : 15,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(color: borderColor, width: 3),
            ),
            child: ClipOval(
              child: Image.asset(widget.imagePath, fit: BoxFit.cover),
            ),
          ),
        );
      },
    );
  }
}
