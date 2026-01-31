import 'dart:convert';
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: const Text('Profil User'),
                pinned: true,
                floating: true,
                forceElevated: innerBoxIsScrolled,
              ),
              // Profile Header
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Profile Photo
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          backgroundImage: _user!.fotoProfil != null
                              ? MemoryImage(base64Decode(_user!.fotoProfil!))
                              : null,
                          child: _user!.fotoProfil == null
                              ? Text(
                                  _user!.namaPanggilan[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // Name
                        Text(
                          _user!.namaPanggilan,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user!.namaLengkap,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Statistics
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatColumn(
                              Icons.monetization_on,
                              _user!.saldoSkillcoin.toString(),
                              'SkillCoin',
                              Colors.amber,
                            ),
                            _buildStatColumn(
                              Icons.star,
                              _user!.ratingRataRata.toStringAsFixed(1),
                              'Rating',
                              Colors.orange,
                            ),
                            _buildStatColumn(
                              Icons.swap_horiz,
                              _user!.jumlahTransaksi.toString(),
                              'Transaksi',
                              Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Tab Bar (Pinned)
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  const TabBar(
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                    tabs: [
                      Tab(text: 'Dikuasai'),
                      Tab(text: 'Dicari'),
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
                Icons.workspace_premium,
                'Belum ada skill dikuasai',
              ),
              _buildSkillGrid(dicari, Icons.search, 'Belum ada skill dicari'),
            ],
          ),
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
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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

  Widget _buildStatColumn(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
