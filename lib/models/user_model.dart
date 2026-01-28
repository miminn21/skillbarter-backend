class UserModel {
  final String nik;
  final String namaLengkap;
  final String namaPanggilan;
  final String jenisKelamin;
  final String tanggalLahir;
  final String alamatLengkap;
  final String kota;
  final String? fotoProfil;
  final String? jenisFoto;
  final int? ukuranFoto;
  final String? bio;
  final double ratingRataRata;
  final int jumlahTransaksi;
  final int totalJamBerkontribusi;
  final int saldoSkillcoin;
  final bool statusAktif;
  final String? terakhirLogin;
  final String dibuatPada;
  final String diperbaruiPada;

  // Detail pengguna
  final String? pekerjaan;
  final String? namaInstansi;
  final String? pendidikanTerakhir;
  final String? keahlianKhusus;
  final Map<String, dynamic>? mediaSosial;
  final String? preferensiLokasi;
  final String? zonaWaktu;
  final String? bahasa;

  UserModel({
    required this.nik,
    required this.namaLengkap,
    required this.namaPanggilan,
    required this.jenisKelamin,
    required this.tanggalLahir,
    required this.alamatLengkap,
    required this.kota,
    this.fotoProfil,
    this.jenisFoto,
    this.ukuranFoto,
    this.bio,
    this.ratingRataRata = 0.0,
    this.jumlahTransaksi = 0,
    this.totalJamBerkontribusi = 0,
    this.saldoSkillcoin = 10,
    this.statusAktif = true,
    this.terakhirLogin,
    required this.dibuatPada,
    required this.diperbaruiPada,
    this.pekerjaan,
    this.namaInstansi,
    this.pendidikanTerakhir,
    this.keahlianKhusus,
    this.mediaSosial,
    this.preferensiLokasi,
    this.zonaWaktu,
    this.bahasa,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert to String (handle JSON objects)
    String? toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      // If it's a Map/List, return null (not a string)
      if (value is Map || value is List) return null;
      return value.toString();
    }

    return UserModel(
      nik: json['nik'] ?? '',
      namaLengkap: json['nama_lengkap'] ?? '',
      namaPanggilan: json['nama_panggilan'] ?? '',
      jenisKelamin: json['jenis_kelamin'] ?? '',
      tanggalLahir: json['tanggal_lahir'] ?? '',
      alamatLengkap: json['alamat_lengkap'] ?? '',
      kota: json['kota'] ?? '',
      fotoProfil: toStringOrNull(json['foto_profil']),
      jenisFoto: toStringOrNull(json['jenis_foto']),
      ukuranFoto: json['ukuran_foto'],
      bio: toStringOrNull(json['bio']),
      ratingRataRata:
          double.tryParse(json['rating_rata_rata']?.toString() ?? '0') ?? 0.0,
      jumlahTransaksi: json['jumlah_transaksi'] ?? 0,
      totalJamBerkontribusi: json['total_jam_berkontribusi'] ?? 0,
      saldoSkillcoin: json['saldo_skillcoin'] ?? 10,
      statusAktif: json['status_aktif'] == 1 || json['status_aktif'] == true,
      terakhirLogin: toStringOrNull(json['terakhir_login']),
      dibuatPada: json['dibuat_pada'] ?? '',
      diperbaruiPada: json['diperbarui_pada'] ?? '',
      pekerjaan: toStringOrNull(json['pekerjaan']),
      namaInstansi: toStringOrNull(json['nama_instansi']),
      pendidikanTerakhir: toStringOrNull(json['pendidikan_terakhir']),
      keahlianKhusus: toStringOrNull(json['keahlian_khusus']),
      mediaSosial: json['media_sosial'] is Map
          ? json['media_sosial'] as Map<String, dynamic>
          : null,
      preferensiLokasi: toStringOrNull(json['preferensi_lokasi']),
      zonaWaktu: toStringOrNull(json['zona_waktu']),
      bahasa: toStringOrNull(json['bahasa']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nik': nik,
      'nama_lengkap': namaLengkap,
      'nama_panggilan': namaPanggilan,
      'jenis_kelamin': jenisKelamin,
      'tanggal_lahir': tanggalLahir,
      'alamat_lengkap': alamatLengkap,
      'kota': kota,
      'bio': bio,
      'pekerjaan': pekerjaan,
      'nama_instansi': namaInstansi,
      'pendidikan_terakhir': pendidikanTerakhir,
      'keahlian_khusus': keahlianKhusus,
      'media_sosial': mediaSosial,
      'preferensi_lokasi': preferensiLokasi,
      'zona_waktu': zonaWaktu,
      'bahasa': bahasa,
    };
  }

  UserModel copyWith({
    String? nik,
    String? namaLengkap,
    String? namaPanggilan,
    String? jenisKelamin,
    String? tanggalLahir,
    String? alamatLengkap,
    String? kota,
    String? fotoProfil,
    String? bio,
    double? ratingRataRata,
    int? jumlahTransaksi,
    int? totalJamBerkontribusi,
    int? saldoSkillcoin,
    String? pekerjaan,
    String? namaInstansi,
    String? pendidikanTerakhir,
    String? keahlianKhusus,
    Map<String, dynamic>? mediaSosial,
    String? preferensiLokasi,
    String? zonaWaktu,
    String? bahasa,
  }) {
    return UserModel(
      nik: nik ?? this.nik,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      namaPanggilan: namaPanggilan ?? this.namaPanggilan,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      alamatLengkap: alamatLengkap ?? this.alamatLengkap,
      kota: kota ?? this.kota,
      fotoProfil: fotoProfil ?? this.fotoProfil,
      bio: bio ?? this.bio,
      ratingRataRata: ratingRataRata ?? this.ratingRataRata,
      jumlahTransaksi: jumlahTransaksi ?? this.jumlahTransaksi,
      totalJamBerkontribusi:
          totalJamBerkontribusi ?? this.totalJamBerkontribusi,
      saldoSkillcoin: saldoSkillcoin ?? this.saldoSkillcoin,
      dibuatPada: dibuatPada,
      diperbaruiPada: diperbaruiPada,
      pekerjaan: pekerjaan ?? this.pekerjaan,
      namaInstansi: namaInstansi ?? this.namaInstansi,
      pendidikanTerakhir: pendidikanTerakhir ?? this.pendidikanTerakhir,
      keahlianKhusus: keahlianKhusus ?? this.keahlianKhusus,
      mediaSosial: mediaSosial ?? this.mediaSosial,
      preferensiLokasi: preferensiLokasi ?? this.preferensiLokasi,
      zonaWaktu: zonaWaktu ?? this.zonaWaktu,
      bahasa: bahasa ?? this.bahasa,
    );
  }
}
