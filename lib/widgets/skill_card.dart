import 'package:flutter/material.dart';
import '../models/skill_model.dart';
import 'dart:convert';

class SkillCard extends StatelessWidget {
  final SkillModel skill;
  final VoidCallback? onTap;
  final bool showOwner;

  const SkillCard({
    super.key,
    required this.skill,
    this.onTap,
    this.showOwner = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasImage = skill.gambarSkill != null && skill.gambarSkill!.isNotEmpty;
    final textColor = hasImage
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);
    final subTextColor = hasImage
        ? Colors.white70
        : (isDark ? Colors.grey[400] : Colors.grey[600]);
    final iconColor = hasImage
        ? Colors.white
        : (isDark ? Colors.grey[400] : Colors.grey[600]);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: hasImage
              ? BoxDecoration(
                  image: DecorationImage(
                    image: MemoryImage(base64Decode(skill.gambarSkill!)),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.65),
                      BlendMode.darken,
                    ),
                  ),
                )
              : null,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon and verified badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: hasImage
                                ? Colors.white.withOpacity(0.2)
                                : Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getCategoryIcon(skill.kategoriIkon),
                            size: 20,
                            color: hasImage
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            skill.namaKeahlian,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Only show inline badge if NO image (Text Card style)
                        if (skill.statusVerifikasi && !hasImage)
                          const Icon(
                            Icons.verified,
                            size: 18,
                            color: Colors.blue,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Category name
                    Text(
                      skill.namaKategori ?? '',
                      style: TextStyle(fontSize: 11, color: subTextColor),
                    ),
                    const SizedBox(height: 8),

                    // Badges (Tingkat & Harga)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildBadge(
                          _getTingkatLabel(skill.tingkat),
                          _getTingkatColor(skill.tingkat),
                          hasImage,
                        ),
                        _buildBadge(
                          '${skill.hargaPerJam} SC',
                          Colors.amber,
                          hasImage,
                        ),
                      ],
                    ),

                    // Owner info (if showOwner)
                    if (showOwner && skill.namaPemilik != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: iconColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              skill.namaPemilik!,
                              style: TextStyle(
                                fontSize: 11,
                                color: subTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Creation date
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: iconColor),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(skill.dibuatPada),
                          style: TextStyle(fontSize: 10, color: subTextColor),
                        ),
                      ],
                    ),

                    // Expiry date (for dicari only)
                    if (skill.tipe == 'dicari' &&
                        skill.tanggalBerakhir != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            skill.isExpired
                                ? Icons.event_busy
                                : Icons.event_available,
                            size: 12,
                            color: skill.isExpired
                                ? Colors.red[600]
                                : Colors.green[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              skill.isExpired
                                  ? 'Kadaluarsa ${_formatDate(skill.tanggalBerakhir!.toIso8601String())}'
                                  : 'Berlaku s/d ${_formatDate(skill.tanggalBerakhir!.toIso8601String())}',
                              style: TextStyle(
                                fontSize: 10,
                                color: skill.isExpired
                                    ? Colors.red[600]
                                    : Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Floating Badge for Image Cards
              if (skill.statusVerifikasi && hasImage)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(2), // White border effect
                    decoration: const BoxDecoration(
                      color: Colors.white, // Background behind check
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      size: 20,
                      color: Colors.blue,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return 'Tanggal tidak tersedia';

      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];

      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Tanggal tidak valid';
    }
  }

  Widget _buildBadge(String label, Color color, bool hasImage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: hasImage ? color.withOpacity(0.8) : color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: hasImage ? Colors.white : color.withOpacity(0.8),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? icon) {
    switch (icon) {
      case 'computer':
        return Icons.computer;
      case 'palette':
        return Icons.palette;
      case 'language':
        return Icons.language;
      case 'music_note':
        return Icons.music_note;
      default:
        return Icons.star;
    }
  }

  String _getTingkatLabel(String tingkat) {
    switch (tingkat) {
      case 'pemula':
        return 'Pemula';
      case 'menengah':
        return 'Menengah';
      case 'mahir':
        return 'Mahir';
      case 'ahli':
        return 'Ahli';
      default:
        return tingkat;
    }
  }

  Color _getTingkatColor(String tingkat) {
    switch (tingkat) {
      case 'pemula':
        return Colors.blue;
      case 'menengah':
        return Colors.green;
      case 'mahir':
        return Colors.orange;
      case 'ahli':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
