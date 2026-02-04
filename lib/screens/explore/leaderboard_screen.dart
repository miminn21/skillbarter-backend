import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skilbarter/models/leaderboard_model.dart';
import 'package:video_player/video_player.dart';
import '../../providers/explore_provider.dart';
import '../../widgets/user_card.dart';
import 'user_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _animController;

  // Podium Animations
  late Animation<Offset> _podiumSlide;
  late Animation<double> _podiumFade;

  // List Animations
  late Animation<Offset> _listSlide;
  late Animation<double> _listFade;

  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    // Initialize Video Player
    _controller =
        VideoPlayerController.asset(
            'assets/images/vecteezy_colorful-confetti-party-celebration-or-congratulation_11086923.mp4',
          )
          ..initialize().then((_) {
            _controller.setLooping(true);
            _controller.play();
            setState(() {});
          });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // --- Podium (Top 3) Animations ---
    // Slide from Top
    _podiumSlide = Tween<Offset>(begin: const Offset(0, -3.0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    // Fade In
    _podiumFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // --- List (Rankings) Animations ---
    // Slide from Bottom
    _listSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    // Fade In
    _listFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLeaderboard();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _loadLeaderboard() {
    context.read<ExploreProvider>().loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Video
        if (_controller.value.isInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          )
        else
          Container(color: const Color(0xFFF8F9FA)),

        // Main Content Overlay
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: const BackButton(color: Colors.white),
            title: const Text(
              'Leaderboard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  _animController.reset();
                  _hasAnimated = false;
                  _loadLeaderboard();
                },
              ),
            ],
          ),
          body: Consumer<ExploreProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.leaderboard.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.error != null && provider.leaderboard.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(provider.error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLeaderboard,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                );
              }

              if (provider.leaderboard.isEmpty) {
                return const Center(child: Text('Tidak ada data leaderboard'));
              }

              // Trigger Animation once data is ready
              if (!_hasAnimated) {
                _animController.forward();
                _hasAnimated = true;
              }

              // Split top 3 and the rest
              final top3 = provider.leaderboard.take(3).toList();

              return Column(
                children: [
                  // Top 3 Podium Section (Static)
                  if (top3.isNotEmpty)
                    FadeTransition(
                      opacity: _podiumFade,
                      child: SlideTransition(
                        position: _podiumSlide,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildPodium(top3),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Scrollable List Section
                  Expanded(
                    child: FadeTransition(
                      opacity: _listFade,
                      child: SlideTransition(
                        position: _listSlide,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, -5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Static Header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  20,
                                  20,
                                  10,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Peringkat',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ),

                              // Scrollable List
                              Expanded(
                                // ... rest of list content logic
                                child: RefreshIndicator(
                                  onRefresh: () async {
                                    _animController.reset();
                                    _hasAnimated = false;
                                    _loadLeaderboard();
                                  },
                                  child: SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 10),
                                        // Current User Rank (if not in top 3 and valid)
                                        if (provider.currentUserRank != null &&
                                            !top3.any(
                                              (u) =>
                                                  u.nik ==
                                                  provider.currentUserRank!.nik,
                                            )) ...[
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Posisi Anda',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.5),
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.1),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: UserCard(
                                              user: provider.currentUserRank!,
                                              onTap: null,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          const Divider(),
                                          const SizedBox(height: 10),
                                        ],

                                        // Full Leaderboard List
                                        if (provider.leaderboard.isNotEmpty)
                                          ListView.builder(
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            shrinkWrap: true,
                                            itemCount:
                                                provider.leaderboard.length,
                                            itemBuilder: (context, index) {
                                              final user =
                                                  provider.leaderboard[index];
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                child: UserCard(
                                                  user: user,
                                                  rank: index + 1,
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            UserProfileScreen(
                                                              nik: user.nik,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          ),

                                        const SizedBox(height: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPodium(List<dynamic> users) {
    // Determine 1st, 2nd, and 3rd place users safely
    final first = users.isNotEmpty ? users[0] : null;
    final second = users.length > 1 ? users[1] : null;
    final third = users.length > 2 ? users[2] : null;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      height: 240, // Fixed height for alignment
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 2nd Place (Left)
          if (second != null)
            Expanded(
              child: _buildPodiumCard(
                user: second,
                rank: 2,
                height: 160,
                color: Colors.grey[400]!,
                icon: '🥈',
              ),
            ),
          const SizedBox(width: 8),

          // 1st Place (Center - Biggest)
          if (first != null)
            Expanded(
              child: _buildPodiumCard(
                user: first,
                rank: 1,
                height: 200, // Taller
                color: Colors.amber,
                icon: '🥇',
                isWinner: true,
              ),
            ),
          const SizedBox(width: 8),

          // 3rd Place (Right)
          if (third != null)
            Expanded(
              child: _buildPodiumCard(
                user: third,
                rank: 3,
                height: 140,
                color: Colors.brown[400]!,
                icon: '🥉',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumCard({
    required dynamic user,
    required int rank,
    required double height,
    required Color color,
    required String icon,
    bool isWinner = false,
  }) {
    // Extract photo safely
    String? fotoProfil;
    if (user is LeaderboardModel) fotoProfil = user.fotoProfil;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(nik: user.nik),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar overlapping the card
          Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // Crown for 1st place
              if (isWinner)
                Positioned(
                  top: -24,
                  child: Icon(
                    Icons.workspace_premium,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),

              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: isWinner ? 32 : 26,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (fotoProfil != null && fotoProfil.isNotEmpty)
                      ? MemoryImage(base64Decode(fotoProfil))
                      : null,
                  child: (fotoProfil == null || fotoProfil.isEmpty)
                      ? Text(
                          user.namaPanggilan?[0].toUpperCase() ?? '?',
                          style: TextStyle(
                            fontSize: isWinner ? 24 : 18,
                            fontWeight: FontWeight.bold,
                            color:
                                Colors.white, // Changed to white for visibility
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // The Podium Box
          Container(
            width: double.infinity,
            height: height - 60, // Adjust for avatar height space
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.25), color.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              // Fix: Use Border.all to avoid mismatch error
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    user.namaPanggilan ?? "User",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isWinner ? 16 : 14,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 3.0,
                          color: Colors.black.withOpacity(0.8),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        size: 14,
                        color: Colors.amber[800],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${user.saldoSkillcoin}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isWinner ? 14 : 12,
                          color: Colors.amber[900],
                        ),
                      ),
                    ],
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
