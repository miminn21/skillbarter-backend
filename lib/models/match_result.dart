class MatchResult {
  final String nikPengguna;
  final String namaLengkap;
  final String? fotoProfil;
  final String? lokasi;
  final double trustScore;
  final int skillId;
  final String namaKeahlian;
  final int tingkatKeahlian;
  final bool statusVerifikasi;
  final double? ratingRataRata;
  final int? jumlahUlasan;
  final int totalSkills;
  final int completedSessions;

  // Score components
  final double mutualBenefitScore;
  final double trustScoreNormalized;
  final double proximityScore;
  final double skillQualityScore;
  final double availabilityScore;
  final double totalScore;

  MatchResult({
    required this.nikPengguna,
    required this.namaLengkap,
    this.fotoProfil,
    this.lokasi,
    required this.trustScore,
    required this.skillId,
    required this.namaKeahlian,
    required this.tingkatKeahlian,
    required this.statusVerifikasi,
    this.ratingRataRata,
    this.jumlahUlasan,
    required this.totalSkills,
    required this.completedSessions,
    required this.mutualBenefitScore,
    required this.trustScoreNormalized,
    required this.proximityScore,
    required this.skillQualityScore,
    required this.availabilityScore,
    required this.totalScore,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      nikPengguna: json['nik_pengguna'],
      namaLengkap: json['nama_lengkap'],
      fotoProfil: json['foto_profil'],
      lokasi: json['lokasi'],
      trustScore: double.parse(json['trust_score'].toString()),
      skillId: json['skill_id'],
      namaKeahlian: json['nama_keahlian'],
      tingkatKeahlian: json['tingkat_keahlian'],
      statusVerifikasi:
          json['status_verifikasi'] == 1 || json['status_verifikasi'] == true,
      ratingRataRata: json['rating_rata_rata'] != null
          ? double.parse(json['rating_rata_rata'].toString())
          : null,
      jumlahUlasan: json['jumlah_ulasan'],
      totalSkills: json['total_skills'],
      completedSessions: json['completed_sessions'],
      mutualBenefitScore: double.parse(json['mutual_benefit_score'].toString()),
      trustScoreNormalized: double.parse(json['trust_score'].toString()),
      proximityScore: double.parse(json['proximity_score'].toString()),
      skillQualityScore: double.parse(json['skill_quality_score'].toString()),
      availabilityScore: double.parse(json['availability_score'].toString()),
      totalScore: double.parse(json['total_score'].toString()),
    );
  }

  // Get match percentage (0-100)
  int get matchPercentage => totalScore.round();

  // Get skill level text
  String get skillLevelText {
    switch (tingkatKeahlian) {
      case 1:
        return 'Pemula';
      case 2:
        return 'Menengah';
      case 3:
        return 'Mahir';
      case 4:
        return 'Expert';
      case 5:
        return 'Master';
      default:
        return 'Menengah';
    }
  }

  // Get match quality label
  String get matchQualityLabel {
    if (totalScore >= 90) return 'Perfect Match!';
    if (totalScore >= 80) return 'Excellent Match';
    if (totalScore >= 70) return 'Good Match';
    if (totalScore >= 60) return 'Fair Match';
    return 'Potential Match';
  }

  // Get score breakdown for UI
  Map<String, double> get scoreBreakdown => {
    'Mutual Benefit': mutualBenefitScore,
    'Trust Score': trustScoreNormalized,
    'Proximity': proximityScore,
    'Skill Quality': skillQualityScore,
    'Availability': availabilityScore,
  };
}
