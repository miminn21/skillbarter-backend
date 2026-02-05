import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../widgets/custom_notification.dart';
import 'package:intl/intl.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import '../../services/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryAnimationController;

  @override
  void initState() {
    super.initState();
    _entryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Smooth 1s entrance
    );
    _entryAnimationController.forward();
  }

  @override
  void dispose() {
    _entryAnimationController.dispose();
    super.dispose();
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  /// Helper to animate widgets with stagger
  Widget _buildAnimatedItem({
    required Widget child,
    required int index, // 0-based index for stagger
    double slideOffset = 0.2, // vertical offset
  }) {
    // 0.0 -> 0.4
    // 0.1 -> 0.5
    // Each item starts 100ms after the previous (roughly)
    final double startTime = index * 0.1;
    final double endTime = startTime + 0.4; // 400ms duration per item

    // Clamp to 0.0 - 1.0
    final safeStart = startTime > 1.0 ? 1.0 : startTime;
    final safeEnd = endTime > 1.0 ? 1.0 : endTime;

    final Animation<double> fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(
          CurvedAnimation(
            parent: _entryAnimationController,
            curve: Interval(safeStart, safeEnd, curve: Curves.easeOut),
          ),
        );

    final Animation<Offset> slideAnimation =
        Tween<Offset>(begin: Offset(0, slideOffset), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entryAnimationController,
            curve: Interval(safeStart, safeEnd, curve: Curves.easeOutCubic),
          ),
        );

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(position: slideAnimation, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profil Saya',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          if (user == null) {
            return const Center(child: Text('User tidak ditemukan'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // 1. Creative Header with Smooth Top-Down Slide
                SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, -1.0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _entryAnimationController,
                          curve: const Interval(
                            0.0,
                            1.0,
                            curve: Curves.easeOutQuart,
                          ),
                        ),
                      ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Gradient Background with Shapes
                      ClipPath(
                        clipper: _HeaderClipper(),
                        child: const _AnimatedProfileHeader(),
                      ),

                      // Floating Avatar (Pop In Animation would be cool, but slide up for now)
                      Positioned(
                        bottom: -50,
                        child: _buildAnimatedItem(
                          index: 1, // Delay avatar slightly
                          slideOffset: 0.5,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              GestureDetector(
                                onTap: () => _handleUploadPhoto(context),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme
                                          .scaffoldBackgroundColor, // Match scaffold
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.grey.shade100,
                                    backgroundImage: user.fotoProfil != null
                                        ? MemoryImage(
                                            base64Decode(user.fotoProfil!),
                                          )
                                        : null,
                                    child: user.fotoProfil == null
                                        ? Text(
                                            user.namaPanggilan[0].toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 48,
                                              color: theme.primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 20,
                                    color: isDark
                                        ? Colors.white
                                        : theme.primaryColor,
                                  ),
                                  onPressed: () => _handleUploadPhoto(context),
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // 2. User Identity (Stagger Index 1)
                _buildAnimatedItem(
                  index: 1,
                  child: Column(
                    children: [
                      Text(
                        user.namaLengkap,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color:
                              theme.textTheme.headlineMedium?.color ??
                              (isDark ? Colors.white : const Color(0xFF2D3142)),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.namaPanggilan}',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.ratingRataRata.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309), // Dark amber
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Stats Row (Stagger Index 2)
                _buildAnimatedItem(
                  index: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.monetization_on_rounded,
                            label: AppLocalizations.of(
                              context,
                            )!.translate('stat_coins'),
                            value: '${user.saldoSkillcoin}',
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.swap_horiz_rounded,
                            label: AppLocalizations.of(
                              context,
                            )!.translate('stat_trans'),
                            value: '${user.jumlahTransaksi}',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.access_time_filled_rounded,
                            label: AppLocalizations.of(
                              context,
                            )!.translate('stat_hours'),
                            value: '${user.totalJamBerkontribusi}',
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Bio (Stagger Index 3)
                if (user.bio != null && user.bio!.isNotEmpty)
                  _buildAnimatedItem(
                    index: 3,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            color: isDark ? Colors.grey[600] : Colors.grey[300],
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.bio!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // 5. Personal Info (Stagger Index 4)
                _buildAnimatedItem(
                  index: 4,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.translate('info_title'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[800],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoTile(
                              context,
                              icon: Icons.badge_rounded,
                              title: AppLocalizations.of(
                                context,
                              )!.translate('label_nik'),
                              value: user.nik,
                              isFirst: true,
                              color: Colors.blue,
                            ),
                            _buildInfoTile(
                              context,
                              icon: Icons.wc_rounded,
                              title: AppLocalizations.of(
                                context,
                              )!.translate('label_gender'),
                              value: user.jenisKelamin == 'L'
                                  ? AppLocalizations.of(
                                      context,
                                    )!.translate('gender_male')
                                  : AppLocalizations.of(
                                      context,
                                    )!.translate('gender_female'),
                              color: Colors.purple,
                            ),
                            _buildInfoTile(
                              context,
                              icon: Icons.cake_rounded,
                              title: AppLocalizations.of(
                                context,
                              )!.translate('label_dob'),
                              value: _formatDate(user.tanggalLahir),
                              color: Colors.pink,
                            ),
                            _buildInfoTile(
                              context,
                              icon: Icons.location_city_rounded,
                              title: AppLocalizations.of(
                                context,
                              )!.translate('label_city'),
                              value: user.kota,
                              color: Colors.orange,
                            ),
                            if (user.pekerjaan != null)
                              _buildInfoTile(
                                context,
                                icon: Icons.work_rounded,
                                title: AppLocalizations.of(
                                  context,
                                )!.translate('label_job'),
                                value: user.pekerjaan!,
                                color: Colors.brown,
                              ),
                            if (user.pendidikanTerakhir != null)
                              _buildInfoTile(
                                context,
                                icon: Icons.school_rounded,
                                title: AppLocalizations.of(
                                  context,
                                )!.translate('label_edu'),
                                value: user.pendidikanTerakhir!,
                                color: Colors.teal,
                                isLast: true,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 6. Menu Section (Stagger Index 5)
                _buildAnimatedItem(
                  index: 5,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuTile(
                          context,
                          icon: Icons.lock_outline_rounded,
                          title: AppLocalizations.of(
                            context,
                          )!.translate('menu_password'),
                          color: Colors.deepOrange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChangePasswordScreen(),
                              ),
                            );
                          },
                          isFirst: true,
                        ),
                        _buildMenuTile(
                          context,
                          icon: Icons.settings_outlined,
                          title: AppLocalizations.of(
                            context,
                          )!.translate('settings_title'),
                          color: Colors.indigo,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuTile(
                          context,
                          icon: Icons.help_outline_rounded,
                          title: AppLocalizations.of(
                            context,
                          )!.translate('menu_help'),
                          color: Colors.cyan,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpScreen(),
                              ),
                            );
                          },
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        if (!isFirst)
          Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.grey.shade100,
            indent: 60,
          ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF2D3142),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        if (!isFirst)
          Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.grey.shade100,
            indent: 60,
          ),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: isFirst ? const Radius.circular(20) : Radius.zero,
              bottom: isLast ? const Radius.circular(20) : Radius.zero,
            ),
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF2D3142),
            ),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Future<void> _handleUploadPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image == null) return;

    if (!context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final profileService = ProfileService();
      final response = await profileService.uploadPhoto(image);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      if (response.success && response.data != null) {
        // Update user in provider
        final authProvider = context.read<AuthProvider>();
        await authProvider.loadProfile();

        CustomNotification.showSuccess(
          context,
          '📸 Foto profil berhasil diupdate!',
        );
      } else {
        CustomNotification.showError(context, response.message);
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      CustomNotification.showError(context, '❌ Gagal upload foto: $e');
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}

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

class _AnimatedProfileHeader extends StatefulWidget {
  const _AnimatedProfileHeader();

  @override
  State<_AnimatedProfileHeader> createState() => _AnimatedProfileHeaderState();
}

class _AnimatedProfileHeaderState extends State<_AnimatedProfileHeader>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  @override
  void initState() {
    super.initState();
    // Faster animations (Previous: 5, 7, 6 seconds. New: 3, 4, 3 seconds)
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _controller3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
    return Container(
      height: 280,
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
          // Blob 1: Top Left (Cyan/Blue)
          AnimatedBuilder(
            animation: _controller1,
            builder: (context, child) {
              return Positioned(
                top: -50 + (_controller1.value * 20),
                left: -50 + (_controller1.value * 30),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.cyanAccent.withOpacity(0.2),
                        Colors.blueAccent.withOpacity(0.2),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.2),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Blob 2: Bottom Right (Indigo/Primary)
          AnimatedBuilder(
            animation: _controller2,
            builder: (context, child) {
              return Positioned(
                bottom: -60 + (_controller2.value * 30),
                right: -40 + (_controller2.value * 20),
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3949AB).withOpacity(0.3), // Indigo
                        Theme.of(context).primaryColor.withOpacity(0.3),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3949AB).withOpacity(0.3),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Blob 3: Center (Soft Light Blue overlap)
          AnimatedBuilder(
            animation: _controller3,
            builder: (context, child) {
              return Positioned(
                top: 50 + (_controller3.value * 20),
                left: 100 + (_controller3.value * -30),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        blurRadius: 50,
                        spreadRadius: 5,
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
