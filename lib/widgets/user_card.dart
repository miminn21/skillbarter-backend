import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/leaderboard_model.dart';
import '../models/user_public_model.dart';

class UserCard extends StatelessWidget {
  final dynamic user; // Can be LeaderboardModel or UserPublicModel
  final int? rank;
  final VoidCallback? onTap;

  const UserCard({super.key, required this.user, this.rank, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String namaPanggilan = _getNamaPanggilan();
    final String? fotoProfil = _getFotoProfil();
    final int saldoSkillcoin = _getSaldoSkillcoin();
    final double rating = _getRating();
    final int? peringkat = _getPeringkat();

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Rank badge (if provided)
              if (peringkat != null) ...[
                _buildRankBadge(peringkat),
                const SizedBox(width: 12),
              ],

              // Profile photo
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: fotoProfil != null
                    ? MemoryImage(base64Decode(fotoProfil))
                    : null,
                child: fotoProfil == null
                    ? Text(
                        namaPanggilan.isNotEmpty
                            ? namaPanggilan[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      namaPanggilan,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Skillcoin balance
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      size: 16,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      saldoSkillcoin.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[900],
                      ),
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

  Widget _buildRankBadge(int rank) {
    final medal = _getMedalEmoji(rank);
    final color = _getRankColor(rank);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: medal != null
            ? Text(medal, style: const TextStyle(fontSize: 18))
            : Text(
                rank.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
      ),
    );
  }

  String? _getMedalEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return null;
    }
  }

  Color _getRankColor(int rank) {
    if (rank <= 3) return Colors.amber;
    if (rank <= 10) return Colors.blue;
    return Colors.grey;
  }

  // Helper methods to extract data from different model types
  String _getNamaPanggilan() {
    if (user is LeaderboardModel) {
      return (user as LeaderboardModel).namaPanggilan;
    }
    if (user is UserPublicModel) return (user as UserPublicModel).namaPanggilan;
    return '';
  }

  String? _getFotoProfil() {
    if (user is LeaderboardModel) return (user as LeaderboardModel).fotoProfil;
    if (user is UserPublicModel) return (user as UserPublicModel).fotoProfil;
    return null;
  }

  int _getSaldoSkillcoin() {
    if (user is LeaderboardModel) {
      return (user as LeaderboardModel).saldoSkillcoin;
    }
    if (user is UserPublicModel) {
      return (user as UserPublicModel).saldoSkillcoin;
    }
    return 0;
  }

  double _getRating() {
    if (user is LeaderboardModel) {
      return (user as LeaderboardModel).ratingRataRata;
    }
    if (user is UserPublicModel) {
      return (user as UserPublicModel).ratingRataRata;
    }
    return 0.0;
  }

  int? _getPeringkat() {
    if (rank != null) return rank;
    if (user is LeaderboardModel) return (user as LeaderboardModel).peringkat;
    return null;
  }
}
