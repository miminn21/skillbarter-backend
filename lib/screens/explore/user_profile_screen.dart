import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../models/user_public_model.dart';
import '../../services/explore_service.dart';
import '../../widgets/skill_card.dart';
import '../skills/skill_detail_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String nik;

  const UserProfileScreen({super.key, required this.nik});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ExploreService _exploreService = ExploreService();
  UserPublicModel? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _exploreService.getUserProfile(widget.nik);

    if (response.success && response.data != null) {
      setState(() {
        _user = response.data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = response.message;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil User')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil User')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'User tidak ditemukan'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    final dikuasai = _user!.skills.where((s) => s.tipe == 'dikuasai').toList();
    final dicari = _user!.skills.where((s) => s.tipe == 'dicari').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      extendBodyBehindAppBar: true,
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // 1. Transparent AppBar
              SliverAppBar(
                title: Text(
                  _user!.namaPanggilan,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: false,
                floating: true,
                snap: true,
                centerTitle: true,
                iconTheme: const IconThemeData(color: Colors.white),
              ),

              // 2. Profile Header & Info
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -kToolbarHeight),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          // A. Animated Curved Background
                          ClipPath(
                            clipper: _HeaderClipper(),
                            child: const _AnimatedProfileHeader(),
                          ),

                          // B. Floating Avatar
                          Positioned(
                            bottom: -50,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
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
                                backgroundImage: _user!.fotoProfil != null
                                    ? MemoryImage(
                                        base64Decode(_user!.fotoProfil!),
                                      )
                                    : null,
                                child: _user!.fotoProfil == null
                                    ? Text(
                                        _user!.namaPanggilan[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 48,
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 60), // Spacer for Avatar
                      // 2. Name & Handle
                      Text(
                        _user!.namaLengkap,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${_user!.namaPanggilan}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3. Stats Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard(
                              icon: Icons.monetization_on_rounded,
                              label: 'SkillCoin',
                              value: _user!.saldoSkillcoin.toString(),
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              icon: Icons.star_rounded,
                              label: 'Rating',
                              value: _user!.ratingRataRata.toStringAsFixed(1),
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              icon: Icons.swap_horiz_rounded,
                              label: 'Transaksi',
                              value: _user!.jumlahTransaksi.toString(),
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 4. Bio
                      if (_user!.bio != null && _user!.bio!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                                color: Colors.grey[300],
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _user!.bio!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[700],
                                  height: 1.6,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Spacer if bio exists
                      if (_user!.bio != null && _user!.bio!.isNotEmpty)
                        const SizedBox(height: 24),

                      // 5. Personal Info
                      if (_user!.kota != null ||
                          _user!.pekerjaan != null ||
                          _user!.pendidikanTerakhir != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Informasi Pribadi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                              if (_user!.jenisKelamin != null)
                                _buildInfoTile(
                                  icon: Icons.wc_rounded,
                                  title: 'Jenis Kelamin',
                                  value: _user!.jenisKelamin == 'L'
                                      ? 'Laki-laki'
                                      : 'Perempuan',
                                  color: Colors.purple,
                                  isFirst: true,
                                ),
                              if (_user!.tanggalLahir != null)
                                _buildInfoTile(
                                  icon: Icons.cake_rounded,
                                  title: 'Tanggal Lahir',
                                  value: _formatDate(_user!.tanggalLahir),
                                  color: Colors.pink,
                                ),
                              if (_user!.kota != null)
                                _buildInfoTile(
                                  icon: Icons.location_city_rounded,
                                  title: 'Kota',
                                  value: _user!.kota!,
                                  color: Colors.orange,
                                ),
                              if (_user!.pekerjaan != null)
                                _buildInfoTile(
                                  icon: Icons.work_rounded,
                                  title: 'Pekerjaan',
                                  value: _user!.pekerjaan!,
                                  color: Colors.brown,
                                ),
                              if (_user!.pendidikanTerakhir != null)
                                _buildInfoTile(
                                  icon: Icons.school_rounded,
                                  title: 'Pendidikan',
                                  value: _user!.pendidikanTerakhir!,
                                  color: Colors.teal,
                                  isLast: true,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ),

              // 3. Tab Bar
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.workspace_premium_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Dikuasai'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Dicari'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildSkillGrid(
                dikuasai,
                Icons.workspace_premium_rounded,
                'Belum ada skill dikuasai',
              ),
              _buildSkillGrid(
                dicari,
                Icons.person_search_rounded,
                'Belum ada skill dicari',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillGrid(
    List<dynamic> skills,
    IconData emptyIcon,
    String emptyText,
  ) {
    if (skills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              emptyText,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        return SkillCard(
          skill: skill,
          showOwner: false,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SkillDetailScreen(skillId: skill.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        if (!isFirst)
          Divider(height: 1, color: Colors.grey.shade100, indent: 60),
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
              color: Colors.grey[500],
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142),
              ),
            ),
          ),
        ),
      ],
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 24;

  @override
  double get maxExtent => _tabBar.preferredSize.height + 24;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF8F9FD),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: _tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
