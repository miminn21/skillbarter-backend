import 'skill_model.dart';

class UserPublicModel {
  final String nik;
  final String namaLengkap;
  final String namaPanggilan;
  final String? fotoProfil;
  final double ratingRataRata;
  final int jumlahTransaksi;
  final int saldoSkillcoin;
  final int totalJamBerkontribusi;
  final String? statusOnline;
  final String? terakhirAktif;
  final List<SkillModel> skills;

  UserPublicModel({
    required this.nik,
    required this.namaLengkap,
    required this.namaPanggilan,
    this.fotoProfil,
    required this.ratingRataRata,
    required this.jumlahTransaksi,
    required this.saldoSkillcoin,
    required this.totalJamBerkontribusi,
    this.statusOnline,
    this.terakhirAktif,
    this.skills = const [],
  });

  factory UserPublicModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert to double
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Helper to safely convert to int
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Helper to safely convert to String (handle JSON objects)
    String? toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      // If it's a Map/List, return null (not a string)
      if (value is Map || value is List) return null;
      return value.toString();
    }

    return UserPublicModel(
      nik: json['nik'] ?? '',
      namaLengkap: json['nama_lengkap'] ?? '',
      namaPanggilan: json['nama_panggilan'] ?? '',
      fotoProfil: toStringOrNull(json['foto_profil']),
      ratingRataRata: toDouble(json['rating_rata_rata']),
      jumlahTransaksi: toInt(json['jumlah_transaksi']),
      saldoSkillcoin: toInt(json['saldo_skillcoin']),
      totalJamBerkontribusi: toInt(json['total_jam_berkontribusi']),
      statusOnline: toStringOrNull(json['status_online']),
      terakhirAktif: toStringOrNull(json['terakhir_aktif']),
      skills: json['skills'] != null
          ? (json['skills'] as List)
                .map((skill) => SkillModel.fromJson(skill))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nik': nik,
      'nama_lengkap': namaLengkap,
      'nama_panggilan': namaPanggilan,
      'foto_profil': fotoProfil,
      'rating_rata_rata': ratingRataRata,
      'jumlah_transaksi': jumlahTransaksi,
      'saldo_skillcoin': saldoSkillcoin,
      'total_jam_berkontribusi': totalJamBerkontribusi,
      'status_online': statusOnline,
      'terakhir_aktif': terakhirAktif,
      'skills': skills.map((s) => s.toJson()).toList(),
    };
  }
}
