class LeaderboardModel {
  final int peringkat;
  final String nik;
  final String namaPanggilan;
  final String? fotoProfil;
  final int saldoSkillcoin;
  final int totalJamBerkontribusi;
  final double ratingRataRata;

  LeaderboardModel({
    required this.peringkat,
    required this.nik,
    required this.namaPanggilan,
    this.fotoProfil,
    required this.saldoSkillcoin,
    required this.totalJamBerkontribusi,
    required this.ratingRataRata,
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardModel(
      peringkat: json['peringkat'] as int? ?? 0,
      nik: json['nik'] as String? ?? '',
      namaPanggilan: json['nama_panggilan'] as String? ?? 'Unknown',
      fotoProfil: _toStringOrNull(json['foto_profil']),
      saldoSkillcoin: json['saldo_skillcoin'] as int? ?? 0,
      totalJamBerkontribusi: json['total_jam_berkontribusi'] as int? ?? 0,
      ratingRataRata: _toDouble(json['rating_rata_rata']),
    );
  }

  static String? _toStringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    // If it's a Map/List, return null (not a string)
    if (value is Map || value is List) return null;
    return value.toString();
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'peringkat': peringkat,
      'nik': nik,
      'nama_panggilan': namaPanggilan,
      'foto_profil': fotoProfil,
      'saldo_skillcoin': saldoSkillcoin,
      'total_jam_berkontribusi': totalJamBerkontribusi,
      'rating_rata_rata': ratingRataRata,
    };
  }

  // Helper to get medal color for top 3
  String? get medalEmoji {
    switch (peringkat) {
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
}
