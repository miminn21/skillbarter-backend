import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../screens/home/home_screen.dart';
import '../screens/auth/login_screen.dart';
// TEMPORARILY DISABLED FOR WEB TESTING - UNCOMMENT TO RE-ENABLE FIREBASE
// import '../services/fcm_service.dart';
// import '../providers/notification_provider.dart';

import 'dart:math' as math;

// ... imports remain the same

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Set system status bar style to match dark background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Main entrance animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Continuous rotation for outer ring
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Start initialization
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Artificial delay to show the beautiful logo animation (3 seconds)
    final minDelay = Future.delayed(const Duration(seconds: 3));
    final apiInit = ApiService().initialize();

    await Future.wait([minDelay, apiInit]);

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = await authProvider.tryAutoLogin();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => isAuthenticated
            ? const HomeScreenWrapper()
            : const LoginScreenWrapper(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Background Color based on the image (Dark Navy)
    const backgroundColor = Color(0xFF050B14);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO SECTION
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Rotating Outer Ring
                      AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationController.value * 2 * math.pi,
                            child: CustomPaint(
                              size: const Size(160, 160),
                              painter: RingPainter(),
                            ),
                          );
                        },
                      ),

                      // 2. Center Circle with Gradient and Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFF00CC), // Magenta/Pink
                              Color(0xFF333399), // Deep Blue/Purple
                              Color(0xFF00CCFF), // Cyan/Blue
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE91E63).withOpacity(0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 0),
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.swap_horiz_rounded, // The requested icon
                            size: 56,
                            color: Colors.white, // White icon
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 100), // Spacing to match the image
            // TEXT SECTION
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    'SKILLBARTER',
                    style: TextStyle(
                      fontFamily: 'Roboto', // Clean geometric font
                      fontSize: 32,
                      fontWeight: FontWeight.w900, // Extra Bold
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'TUKAR KEAHLIAN PERLUAS KONEKSI',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(
                        0.9,
                      ), // Slightly dimmer white
                      letterSpacing: 3.0, // Wide spacing as seen in image
                    ),
                  ),
                ],
              ),
            ),

            // Subtle Loading Star at bottom right (optional polish)
          ],
        ),
      ),
    );
  }
}

// Custom Painter for the segmented gradient ring
class RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10; // Slightly smaller than container

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Define the gradient shader
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = const SweepGradient(
      colors: [
        Color(0xFFFF00CC), // Pink
        Color(0xFF00CCFF), // Cyan
        Color(0xFFFF00CC), // Pink
      ],
      stops: [0.0, 0.5, 1.0],
    ).createShader(rect);

    paint.shader = gradient;

    // Draw 3 segments (Arc)
    // 360 degrees = 2*pi
    // We want 3 gaps.

    // Segment 1
    canvas.drawArc(rect, 0.0, 1.5, false, paint);

    // Segment 2
    canvas.drawArc(rect, 2.1, 1.5, false, paint);

    // Segment 3
    canvas.drawArc(rect, 4.2, 1.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Wrappers to allow lazy loading of screens
class HomeScreenWrapper extends StatelessWidget {
  const HomeScreenWrapper({super.key});
  @override
  Widget build(BuildContext context) => const HomeScreen();
}

class LoginScreenWrapper extends StatelessWidget {
  const LoginScreenWrapper({super.key});
  @override
  Widget build(BuildContext context) => const LoginScreen();
}
