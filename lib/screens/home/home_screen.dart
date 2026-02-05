import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import '../../providers/auth_provider.dart';
import '../profile/profile_screen.dart';
import '../barter/transaction_list_screen.dart';
import '../explore/explore_screen.dart';
import '../explore/radar_screen.dart'; // Import RadarScreen
import '../notifications/notification_screen.dart';
import '../../providers/notification_provider.dart';
import '../profile/activity_log_screen.dart'; // Import ActivityLogScreen
import '../../services/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pageController = PageController(initialPage: 0);
  final _controller = NotchBottomBarController(index: 0);

  final List<Widget> _pages = [
    const DashboardPage(),
    const ExploreScreen(),
    const RadarScreen(), // New Radar Tab
    const TransactionListScreen(),
    const ProfileScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      extendBody: false,
      bottomNavigationBar: AnimatedNotchBottomBar(
        notchBottomBarController: _controller,
        color: theme.colorScheme.surface,
        showLabel: true,
        textOverflow: TextOverflow.visible,
        maxLine: 1,
        shadowElevation: 5,
        kBottomRadius: 28.0,
        notchColor: theme.brightness == Brightness.dark
            ? const Color(0xFF1565C0) // Darker blue for dark mode
            : theme.colorScheme.primary,
        removeMargins: true,
        bottomBarWidth: MediaQuery.of(context).size.width,
        showShadow: true,
        durationInMilliSeconds: 300,
        itemLabelStyle: const TextStyle(fontSize: 10),
        elevation: 1,
        showBlurBottomBar: false,
        bottomBarItems: [
          BottomBarItem(
            inActiveItem: Icon(
              Icons.home_outlined,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            activeItem: const Icon(Icons.home, color: Colors.white),
            itemLabel: AppLocalizations.of(context)!.translate('nav_home'),
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.explore_outlined,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            activeItem: const Icon(Icons.explore, color: Colors.white),
            itemLabel: AppLocalizations.of(context)!.translate('nav_explore'),
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.radar_outlined,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            activeItem: const Icon(Icons.radar, color: Colors.white),
            itemLabel: AppLocalizations.of(context)!.translate('nav_radar'),
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.swap_horiz_outlined,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            activeItem: const Icon(Icons.swap_horiz, color: Colors.white),
            itemLabel: AppLocalizations.of(context)!.translate('nav_trans'),
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.person_outline,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            activeItem: const Icon(Icons.person, color: Colors.white),
            itemLabel: AppLocalizations.of(context)!.translate('nav_profile'),
          ),
        ],
        onTap: (index) {
          _pageController.jumpToPage(index);
        },
        kIconSize: 24.0,
      ),
    );
  }
}

// Dashboard Page
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _contentSlideAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Header Slide (Top Down)
    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOutQuart),
          ),
        );

    // Header Fade
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Content Fade
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    // Content Slide (Bottom Up - Subtle)
    _contentSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutQuart),
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserData();
      _controller.forward();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh when app resumes from background
    if (state == AppLifecycleState.resumed) {
      _refreshUserData();
    }
  }

  Future<void> _refreshUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUserData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          return Column(
            children: [
              // Fixed Header with Animation
              SlideTransition(
                position: _headerSlideAnimation,
                child: FadeTransition(
                  opacity: _headerFadeAnimation,
                  child: _buildHeader(context, user),
                ),
              ),

              // Scrollable Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshUserData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _contentSlideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsGrid(context, user),
                            const SizedBox(height: 25),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.translate('quick_actions'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey[800],
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildQuickActionsGrid(context),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    return Stack(
      children: [
        // Animated Background
        const _AnimatedHeaderBackground(),

        // Content
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${user?.namaPanggilan ?? "User"}! 👋',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.translate('welcome_sub'),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _ScaleButton(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                          if (notificationProvider.unreadCount > 0)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 22,
                                  minHeight: 22,
                                ),
                                child: Text(
                                  '${notificationProvider.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, dynamic user) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildStatCard(
                context,
                icon: Icons.monetization_on_rounded,
                title: AppLocalizations.of(context)!.translate('stat_coins'),
                value: '${user?.saldoSkillcoin ?? 0}',
                color: const Color(0xFFFFB300), // Richer Amber
                delay: 0,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                context,
                icon: Icons.swap_vertical_circle_rounded, // Better icon
                title: AppLocalizations.of(context)!.translate('stat_trans'),
                value: '${user?.jumlahTransaksi ?? 0}',
                color: const Color(0xFF1E88E5), // Richer Blue
                delay: 100,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _buildStatCard(
                context,
                icon: Icons.star_rounded,
                title: AppLocalizations.of(context)!.translate('stat_rating'),
                value: '${user?.ratingRataRata.toStringAsFixed(1) ?? "0.0"}',
                color: const Color(0xFFFF7043), // Deep Orange
                delay: 200,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                context,
                icon: Icons.timer_rounded, // Better icon
                title: AppLocalizations.of(
                  context,
                )!.translate('stat_hours_contrib'),
                value: '${user?.totalJamBerkontribusi ?? 0}',
                color: const Color(0xFF43A047), // Richer Green
                delay: 300,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required int delay,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04), // Cleaner shadow
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF2D3142),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildActionCard(
          context,
          AppLocalizations.of(context)!.translate('action_add_skill'),
          AppLocalizations.of(context)!.translate('action_add_skill_sub'),
          Icons.add_circle_outline_rounded,
          const Color(0xFF5E35B1), // Deep Purple
          () => Navigator.pushNamed(context, '/skills'),
          0,
        ),
        _buildActionCard(
          context,
          AppLocalizations.of(context)!.translate('action_search'),
          AppLocalizations.of(context)!.translate('action_search_sub'),
          Icons.search_rounded,
          const Color(0xFFE91E63), // Pink
          () => Navigator.pushNamed(context, '/explore'),
          100,
        ),
        _buildActionCard(
          context,
          AppLocalizations.of(context)!.translate('action_leaderboard'),
          AppLocalizations.of(context)!.translate('action_leaderboard_sub'),
          Icons.emoji_events_rounded, // Rounded variant
          const Color(0xFFFF8F00), // Amber Dark
          () => Navigator.pushNamed(context, '/leaderboard'),
          200,
        ),
        _buildActionCard(
          context,
          AppLocalizations.of(context)!.translate('action_history'),
          AppLocalizations.of(context)!.translate('action_history_sub'),
          Icons.history_edu_rounded, // More specific icon
          const Color(0xFF00897B), // Teal
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ActivityLogScreen(),
              ),
            );
          },
          300,
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    int delay,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _ScaleButton(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04), // Consistent soft shadow
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: color.withOpacity(0.05), // Subtle tint of brand color
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Colors.grey[300],
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper Widget for Scale Interaction (Hover Effect)
class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleButton({required this.child, required this.onTap});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

// Explore Page (Placeholder)

// Transactions Page - Now using TransactionListScreen from barter module

// Animated Header Background Widget
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
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Container(
        height: 220,
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
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
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
      ),
    );
  }
}
