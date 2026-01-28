class SkillModel {
  final int id;
  final String nikPengguna;
  final String namaKeahlian;
  final int idKategori;
  final String tipe; // 'dikuasai' atau 'dicari'
  final String tingkat; // 'pemula', 'menengah', 'mahir', 'ahli'
  final String? pengalaman;
  final String? deskripsi;
  final int hargaPerJam;
  final String? portofolioGambar; // base64
  final String? jenisPortofolio;
  final String? linkPortofolio;
  final String? gambarSkill; // base64
  final String? jenisGambarSkill;
  final bool statusVerifikasi;
  final String dibuatPada;
  final DateTime? tanggalBerakhir;

  // Additional fields from JOIN
  final String? namaKategori;
  final String? kategoriIkon;
  final String? namaPemilik;

  SkillModel({
    required this.id,
    required this.nikPengguna,
    required this.namaKeahlian,
    required this.idKategori,
    required this.tipe,
    required this.tingkat,
    this.pengalaman,
    this.deskripsi,
    required this.hargaPerJam,
    this.portofolioGambar,
    this.jenisPortofolio,
    this.linkPortofolio,
    this.gambarSkill,
    this.jenisGambarSkill,
    required this.statusVerifikasi,
    required this.dibuatPada,
    this.tanggalBerakhir,
    this.namaKategori,
    this.kategoriIkon,
    this.namaPemilik,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: json['id'] ?? 0,
      nikPengguna: json['nik_pengguna'] ?? '',
      namaKeahlian: json['nama_keahlian'] ?? '',
      idKategori: json['id_kategori'] ?? 0,
      tipe: json['tipe'] ?? 'dikuasai',
      tingkat: json['tingkat'] ?? 'menengah',
      pengalaman: json['pengalaman'],
      deskripsi: json['deskripsi'],
      hargaPerJam: json['harga_per_jam'] ?? 1,
      portofolioGambar: json['portofolio_gambar'],
      jenisPortofolio: json['jenis_portofolio'],
      linkPortofolio: json['link_portofolio'],
      gambarSkill: json['gambar_skill'],
      jenisGambarSkill: json['jenis_gambar_skill'],
      statusVerifikasi:
          json['status_verifikasi'] == 1 || json['status_verifikasi'] == true,
      dibuatPada: json['dibuat_pada'] ?? '',
      tanggalBerakhir: json['tanggal_berakhir'] != null
          ? DateTime.parse(json['tanggal_berakhir'])
          : null,
      namaKategori: json['nama_kategori'],
      kategoriIkon: json['kategori_ikon'],
      namaPemilik: json['nama_pemilik'],
    );
  }

  bool get isExpired {
    if (tanggalBerakhir == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      tanggalBerakhir!.year,
      tanggalBerakhir!.month,
      tanggalBerakhir!.day,
    );
    return today.isAfter(expiry);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nik_pengguna': nikPengguna,
      'nama_keahlian': namaKeahlian,
      'id_kategori': idKategori,
      'tipe': tipe,
      'tingkat': tingkat,
      'pengalaman': pengalaman,
      'deskripsi': deskripsi,
      'harga_per_jam': hargaPerJam,
      'link_portofolio': linkPortofolio,
    };
  }

  SkillModel copyWith({
    int? id,
    String? nikPengguna,
    String? namaKeahlian,
    int? idKategori,
    String? tipe,
    String? tingkat,
    String? pengalaman,
    String? deskripsi,
    int? hargaPerJam,
    String? portofolioGambar,
    String? jenisPortofolio,
    String? linkPortofolio,
    String? gambarSkill,
    String? jenisGambarSkill,
    bool? statusVerifikasi,
    String? dibuatPada,
    String? namaKategori,
    String? kategoriIkon,
    String? namaPemilik,
  }) {
    return SkillModel(
      id: id ?? this.id,
      nikPengguna: nikPengguna ?? this.nikPengguna,
      namaKeahlian: namaKeahlian ?? this.namaKeahlian,
      idKategori: idKategori ?? this.idKategori,
      tipe: tipe ?? this.tipe,
      tingkat: tingkat ?? this.tingkat,
      pengalaman: pengalaman ?? this.pengalaman,
      deskripsi: deskripsi ?? this.deskripsi,
      hargaPerJam: hargaPerJam ?? this.hargaPerJam,
      portofolioGambar: portofolioGambar ?? this.portofolioGambar,
      jenisPortofolio: jenisPortofolio ?? this.jenisPortofolio,
      linkPortofolio: linkPortofolio ?? this.linkPortofolio,
      gambarSkill: gambarSkill ?? this.gambarSkill,
      jenisGambarSkill: jenisGambarSkill ?? this.jenisGambarSkill,
      statusVerifikasi: statusVerifikasi ?? this.statusVerifikasi,
      dibuatPada: dibuatPada ?? this.dibuatPada,
      namaKategori: namaKategori ?? this.namaKategori,
      kategoriIkon: kategoriIkon ?? this.kategoriIkon,
      namaPemilik: namaPemilik ?? this.namaPemilik,
    );
  }
}
