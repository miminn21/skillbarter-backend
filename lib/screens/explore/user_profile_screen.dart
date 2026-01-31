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

    return Scaffold(
      appBar: AppBar(title: const Text('Profil User')),
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header Card
              Card(
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
                                  color: Theme.of(context).colorScheme.primary,
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
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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

              // Skills Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkillSection(
                      'Skill yang Dikuasai',
                      _user!.skills.where((s) => s.tipe == 'dikuasai').toList(),
                      Icons.workspace_premium,
                    ),
                    const SizedBox(height: 24),
                    _buildSkillSection(
                      'Skill yang Dicari',
                      _user!.skills.where((s) => s.tipe == 'dicari').toList(),
                      Icons.search,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillSection(
    String title,
    List<dynamic> skills,
    IconData emptyIcon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${skills.length} skill',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (skills.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(emptyIcon, size: 32, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada skill',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                      builder: (context) =>
                          SkillDetailScreen(skillId: skill.id),
                    ),
                  );
                },
              );
            },
          ),
      ],
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
