import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/app_localizations.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  // Animation State
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
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('settings_title'),
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.white, // Always white on gradient?
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 1. Header Gradient Animation
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
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                children: [
                  const SizedBox(height: 80),

                  // 1. General Settings
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.translate('common_section'),
                  ),
                  _buildContainer(
                    context,
                    children: [
                      _buildLanguageTile(settings),
                      _buildSwitchTile(
                        title: AppLocalizations.of(
                          context,
                        )!.translate('theme_tile'),
                        subtitle: AppLocalizations.of(
                          context,
                        )!.translate('theme_subtitle'),
                        icon: settings.isDarkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        iconColor: Colors.deepPurple,
                        value: settings.isDarkMode,
                        onChanged: (val) {
                          settings.toggleTheme(val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. Notifications
                  _buildSectionHeader(
                    AppLocalizations.of(
                      context,
                    )!.translate('notifications_section'),
                  ),
                  _buildContainer(
                    context,
                    children: [
                      _buildSwitchTile(
                        title: AppLocalizations.of(
                          context,
                        )!.translate('push_notif'),
                        subtitle: AppLocalizations.of(
                          context,
                        )!.translate('push_notif_sub'),
                        icon: Icons.notifications_active_rounded,
                        iconColor: Colors.amber,
                        value: settings.notifPush,
                        onChanged: (val) {
                          settings.setNotifPush(val);
                        },
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. About
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.translate('about_section'),
                  ),
                  _buildContainer(
                    context,
                    children: [
                      _buildActionTile(
                        title: AppLocalizations.of(
                          context,
                        )!.translate('app_version'),
                        subtitle: '1.0.0 (Build 2402)',
                        icon: Icons.info_outline_rounded,
                        iconColor: Colors.grey,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionTile(
                        title: AppLocalizations.of(
                          context,
                        )!.translate('privacy_policy'),
                        icon: Icons.privacy_tip_outlined,
                        iconColor: Colors.teal,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionTile(
                        title: AppLocalizations.of(
                          context,
                        )!.translate('terms_conditions'),
                        icon: Icons.description_outlined,
                        iconColor: Colors.teal,
                        isLast: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TermsConditionsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 4. Danger Zone
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.translate('account_section'),
                  ),
                  _buildContainer(
                    context,
                    children: [
                      _buildActionTile(
                        title: AppLocalizations.of(
                          context,
                        )!.translate('delete_account'),
                        subtitle: AppLocalizations.of(
                          context,
                        )!.translate('delete_account_sub'),
                        icon: Icons.delete_forever_rounded,
                        iconColor: Colors.red,
                        textColor: Colors.red,
                        isLast: true,
                        onTap: () => _showDeleteConfirmDialog(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  Center(
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.translate('rights_reserved'),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildContainer(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildLanguageTile(SettingsProvider settings) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.language_rounded, color: Colors.indigo),
      ),
      title: Text(
        AppLocalizations.of(context)!.translate('language_tile'),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        settings.isEnglish ? 'English' : 'Bahasa Indonesia',
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: () => _showLanguageBottomSheet(context, settings),
    );
  }

  void _showLanguageBottomSheet(
    BuildContext context,
    SettingsProvider settings,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.translate('select_language'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('Bahasa Indonesia'),
            trailing: !settings.isEnglish
                ? Icon(
                    Icons.check_circle_rounded,
                    color: Theme.of(context).primaryColor,
                  )
                : null,
            onTap: () {
              settings.setLanguage('id');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('English'),
            trailing: settings.isEnglish
                ? Icon(
                    Icons.check_circle_rounded,
                    color: Theme.of(context).primaryColor,
                  )
                : null,
            onTap: () {
              settings.setLanguage('en');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          // Visible colors for Dark Mode
          activeColor: Colors.white,
          activeTrackColor: Theme.of(context).primaryColor,
          inactiveThumbColor: Colors.grey.shade400,
          inactiveTrackColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade300,
          value: value,
          onChanged: onChanged,
        ),
        if (!isLast)
          Divider(height: 1, indent: 64, color: Colors.grey.withOpacity(0.1)),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    Color? textColor,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                )
              : null,
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          onTap: onTap,
        ),
        if (!isLast)
          Divider(height: 1, indent: 64, color: Colors.grey.withOpacity(0.1)),
      ],
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun?'),
        content: const Text(
          'Akun Anda akan dihapus secara permanen. Semua data skillcoin dan riwayat barter akan hilang. Anda yakin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              // Simulate delete by logging out
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Memproses penghapusan akun...')),
              );

              // Simulate Async
              await Future.delayed(const Duration(seconds: 2));

              if (!mounted) return;

              // Use AuthProvider to logout (simulating account close)
              try {
                await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).logout();
                if (!mounted) return;
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Gagal log out: $e')));
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
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
      height: 250, // Slightly shorter than profile
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            const Color(0xFF1E88E5), // Lighter blue
            const Color(0xFF1565C0), // Darker blue
          ],
        ),
      ),
      child: Stack(
        children: [
          // Blob 1
          AnimatedBuilder(
            animation: _controller1,
            builder: (context, child) {
              return Positioned(
                top: -30 + (_controller1.value * 20),
                left: -30 + (_controller1.value * 30),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.cyanAccent.withOpacity(0.15),
                        Colors.blueAccent.withOpacity(0.15),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.15),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Blob 2
          AnimatedBuilder(
            animation: _controller2,
            builder: (context, child) {
              return Positioned(
                bottom: -40 + (_controller2.value * 20),
                right: -20 + (_controller2.value * 20),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3949AB).withOpacity(0.2),
                        Theme.of(context).primaryColor.withOpacity(0.2),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3949AB).withOpacity(0.2),
                        blurRadius: 40,
                      ),
                    ],
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
