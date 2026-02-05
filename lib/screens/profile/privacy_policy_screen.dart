import 'package:flutter/material.dart';
import '../../services/app_localizations.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryAnimController;
  late Animation<Offset> _headerAnim;
  late Animation<Offset> _contentAnim;

  @override
  void initState() {
    super.initState();
    _entryAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _headerAnim = Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryAnimController,
            curve: Curves.fastOutSlowIn,
          ),
        );

    _contentAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryAnimController,
            curve: Curves.easeOutQuart,
          ),
        );

    _entryAnimController.forward();
  }

  @override
  void dispose() {
    _entryAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('privacy_policy'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 1. Animated Header Background
          SlideTransition(
            position: _headerAnim,
            child: ClipPath(
              clipper: _HeaderClipper(),
              child: const _AnimatedHeaderBackground(),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: SlideTransition(
              position: _contentAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 80), // Spacing for header
                    _buildSection(
                      context,
                      title: AppLocalizations.of(
                        context,
                      )!.translate('privacy_title_1'),
                      content: AppLocalizations.of(
                        context,
                      )!.translate('privacy_content_1'),
                    ),
                    _buildSection(
                      context,
                      title: AppLocalizations.of(
                        context,
                      )!.translate('privacy_title_2'),
                      content: AppLocalizations.of(
                        context,
                      )!.translate('privacy_content_2'),
                    ),
                    _buildSection(
                      context,
                      title: AppLocalizations.of(
                        context,
                      )!.translate('privacy_title_3'),
                      content: AppLocalizations.of(
                        context,
                      )!.translate('privacy_content_3'),
                    ),
                    _buildSection(
                      context,
                      title: AppLocalizations.of(
                        context,
                      )!.translate('privacy_title_4'),
                      content: AppLocalizations.of(
                        context,
                      )!.translate('privacy_content_4'),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.translate('legal_last_updated'),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? [] // No shadow in dark mode for cleaner look
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.05))
            : null, // Subtle border in dark mode
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Helper Components ----------------

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var firstControlPoint = Offset(size.width / 2, size.height + 20);
    var firstEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _AnimatedHeaderBackground extends StatefulWidget {
  const _AnimatedHeaderBackground();

  @override
  State<_AnimatedHeaderBackground> createState() =>
      _AnimatedHeaderBackgroundState();
}

class _AnimatedHeaderBackgroundState extends State<_AnimatedHeaderBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250, // Slightly shorter than About header
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            const Color(0xFF1E88E5),
            const Color(0xFF1565C0),
          ],
        ),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller1,
            builder: (context, child) {
              return Positioned(
                top: -30 + (_controller1.value * 20),
                left: -30 + (_controller1.value * 30),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller2,
            builder: (context, child) {
              return Positioned(
                bottom: 50 + (_controller2.value * 30),
                right: -40 + (_controller2.value * 20),
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
