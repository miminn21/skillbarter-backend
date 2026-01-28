import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/skill_request_provider.dart';
import '../../models/match_result.dart';
import '../../widgets/match_card.dart';
import '../barter/create_offer_screen.dart';

class MatchesScreen extends StatefulWidget {
  final int requestId;
  final String skillName;

  const MatchesScreen({
    Key? key,
    required this.requestId,
    required this.skillName,
  }) : super(key: key);

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  @override
  void initState() {
    super.initState();
    // Load matches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SkillRequestProvider>().findMatches(widget.requestId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Matches Found'),
            Text(
              widget.skillName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Consumer<SkillRequestProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mencari matches terbaik...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.findMatches(widget.requestId);
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (provider.matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada matches',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Coba lagi nanti atau ubah kriteria request Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    Icon(Icons.people, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${provider.matches.length} Matches Ditemukan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          Text(
                            'Diurutkan berdasarkan kesesuaian terbaik',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Matches List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.matches.length,
                  itemBuilder: (context, index) {
                    final match = provider.matches[index];
                    return MatchCard(
                      match: match,
                      rank: index + 1,
                      onTap: () => _showMatchDetail(match),
                      onSendOffer: () => _sendOffer(match),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMatchDetail(MatchResult match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: match.fotoProfil != null
                          ? MemoryImage(base64Decode(match.fotoProfil!))
                          : null,
                      child: match.fotoProfil == null
                          ? Text(match.namaLengkap[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match.namaLengkap,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '${match.trustScore.toStringAsFixed(1)} Trust Score',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Match Quality
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              match.matchQualityLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${match.matchPercentage}% Match Score',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Score Breakdown
                const Text(
                  'Score Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...match.scoreBreakdown.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Text(
                              '${entry.value.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: entry.value / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(
                            _getScoreColor(entry.value),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Stats
                const Text(
                  'Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Skills',
                        match.totalSkills.toString(),
                        Icons.lightbulb_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Completed',
                        match.completedSessions.toString(),
                        Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Level',
                        match.skillLevelText,
                        Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Reviews',
                        match.jumlahUlasan?.toString() ?? '0',
                        Icons.rate_review_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tutup'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _sendOffer(match);
                        },
                        child: const Text('Kirim Penawaran'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  void _sendOffer(MatchResult match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateOfferScreen(
          targetNik: match.nikPengguna,
          targetSkillId: match.skillId,
          targetSkillName: match.namaKeahlian,
          suggestedLocation: match.lokasi,
          // Note: ownSkillId and ownSkillName should come from current user's skills
          // skillRequestId is not available in MatchResult model
        ),
      ),
    );
  }
}
