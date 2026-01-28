import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _controller3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark Background Base
        Container(
          color: const Color(0xFF0F111A), // Darker background
        ),

        // Floating Blob 1 (Top Left - Purple/Pink)
        AnimatedBuilder(
          animation: _controller1,
          builder: (context, child) {
            return Positioned(
              top: -50 + (_controller1.value * 30),
              left: -50 + (sin(_controller1.value * 2 * pi) * 20),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFD4145A).withOpacity(0.5),
                      const Color(0xFFFBB03B).withOpacity(0.5),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4145A).withOpacity(0.4),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Floating Blob 2 (Center Right - Blue/Cyan)
        AnimatedBuilder(
          animation: _controller2,
          builder: (context, child) {
            return Positioned(
              top: 300 + (cos(_controller2.value * 2 * pi) * 40),
              right: -80 + (_controller2.value * 40),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00C6FB).withOpacity(0.5),
                      const Color(0xFF005BEA).withOpacity(0.5),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF005BEA).withOpacity(0.4),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Floating Blob 3 (Bottom Left - Purple/Blue)
        AnimatedBuilder(
          animation: _controller3,
          builder: (context, child) {
            return Positioned(
              bottom: -50 + (_controller3.value * 40),
              left: -20 + (cos(_controller3.value * pi) * 30),
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF662D8C).withOpacity(0.5),
                      const Color(0xFFED1E79).withOpacity(0.5),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF662D8C).withOpacity(0.4),
                      blurRadius: 120,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // The content stays on top
        widget.child,
      ],
    );
  }
}
