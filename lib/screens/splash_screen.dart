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

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Set system status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

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
    // Artificial minimum delay to show animation (2 seconds)
    final minDelay = Future.delayed(const Duration(seconds: 2));

    // Initialize API service (load token)
    final apiInit = ApiService().initialize();

    await Future.wait([minDelay, apiInit]);

    if (!mounted) return;

    // Check auth status
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // TEMPORARILY DISABLED FOR WEB TESTING - UNCOMMENT TO RE-ENABLE FIREBASE
    // final notificationProvider = Provider.of<NotificationProvider>(
    //   context,
    //   listen: false,
    // );

    final isAuthenticated = await authProvider.tryAutoLogin();

    if (isAuthenticated && mounted) {
      // TEMPORARILY DISABLED FOR WEB TESTING - UNCOMMENT TO RE-ENABLE FIREBASE
      // Initialize FCM Service
      // await FCMService().initialize(notificationProvider, context);
    }

    if (!mounted) return;

    // Navigate with fade transition
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => isAuthenticated
            ? const HomeScreenWrapper()
            : const LoginScreenWrapper(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade600,
              Colors.blue.shade400,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.compare_arrows_rounded,
                      size: 64,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App Name
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Text(
                      'SkillBarter',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tukar Keahlian, Perluas Koneksi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade100,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Loading Indicator
              const SizedBox(height: 60),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade100,
                    ),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
