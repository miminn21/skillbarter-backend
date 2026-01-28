import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/match_result.dart';

class MatchCard extends StatelessWidget {
  final MatchResult match;
  final int rank;
  final VoidCallback onTap;
  final VoidCallback onSendOffer;

  const MatchCard({
    Key? key,
    required this.match,
    required this.rank,
    required this.onTap,
    required this.onSendOffer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with rank and match percentage
              Row(
                children: [
                  // Rank Badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getRankColor(rank),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // User Info
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: match.fotoProfil != null
                              ? MemoryImage(base64Decode(match.fotoProfil!))
                              : null,
                          child: match.fotoProfil == null
                              ? Text(match.namaLengkap[0].toUpperCase())
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match.namaLengkap,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    match.trustScore.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (match.statusVerifikasi) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.verified,
                                      size: 14,
                                      color: Colors.blue,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Match Percentage
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getMatchColor(match.matchPercentage),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${match.matchPercentage}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Match Quality Label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  match.matchQualityLabel,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Skill Info
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    match.namaKeahlian,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      match.skillLevelText,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Location
              if (match.lokasi != null)
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      match.lokasi!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              const SizedBox(height: 12),

              // Stats Row
              Row(
                children: [
                  _buildStat(
                    Icons.lightbulb_outline,
                    '${match.totalSkills} skills',
                  ),
                  const SizedBox(width: 16),
                  _buildStat(
                    Icons.check_circle_outline,
                    '${match.completedSessions} completed',
                  ),
                  if (match.jumlahUlasan != null) ...[
                    const SizedBox(width: 16),
                    _buildStat(
                      Icons.rate_review_outlined,
                      '${match.jumlahUlasan} reviews',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Top Scores
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getTopScores().map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.value.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onSendOffer,
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Kirim Penawaran'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  List<MapEntry<String, double>> _getTopScores() {
    final scores = match.scoreBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return scores.take(3).toList();
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey[400]!;
    if (rank == 3) return Colors.brown[300]!;
    return Colors.blue;
  }

  Color _getMatchColor(int percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 60) return Colors.deepOrange;
    return Colors.red;
  }
}
