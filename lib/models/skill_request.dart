class SkillRequest {
  final int? id;
  final String nikPengguna;
  final int idKategori;
  final String namaKeahlian;
  final String? deskripsiKebutuhan;
  final String tingkatKeahlianDiinginkan;
  final String? durasiEstimasi;
  final String? lokasiPreferensi;
  final String? catatanTambahan;
  final String status;
  final DateTime? dibuatPada;
  final DateTime? diperbaruiPada;

  // Additional fields from JOIN
  final String? namaKategori;
  final String? kategoriIkon;
  final String? namaPemohon;
  final String? fotoProfil;
  final String? lokasi;
  final double? trustScore;

  SkillRequest({
    this.id,
    required this.nikPengguna,
    required this.idKategori,
    required this.namaKeahlian,
    this.deskripsiKebutuhan,
    this.tingkatKeahlianDiinginkan = 'menengah',
    this.durasiEstimasi,
    this.lokasiPreferensi,
    this.catatanTambahan,
    this.status = 'terbuka',
    this.dibuatPada,
    this.diperbaruiPada,
    this.namaKategori,
    this.kategoriIkon,
    this.namaPemohon,
    this.fotoProfil,
    this.lokasi,
    this.trustScore,
  });

  factory SkillRequest.fromJson(Map<String, dynamic> json) {
    return SkillRequest(
      id: json['id'],
      nikPengguna: json['nik_pengguna'],
      idKategori: json['id_kategori'],
      namaKeahlian: json['nama_keahlian'],
      deskripsiKebutuhan: json['deskripsi_kebutuhan'],
      tingkatKeahlianDiinginkan:
          json['tingkat_keahlian_diinginkan'] ?? 'menengah',
      durasiEstimasi: json['durasi_estimasi'],
      lokasiPreferensi: json['lokasi_preferensi'],
      catatanTambahan: json['catatan_tambahan'],
      status: json['status'] ?? 'terbuka',
      dibuatPada: json['dibuat_pada'] != null
          ? DateTime.parse(json['dibuat_pada'])
          : null,
      diperbaruiPada: json['diperbarui_pada'] != null
          ? DateTime.parse(json['diperbarui_pada'])
          : null,
      namaKategori: json['nama_kategori'],
      kategoriIkon: json['kategori_ikon'],
      namaPemohon: json['nama_pemohon'] ?? json['nama_lengkap'],
      fotoProfil: json['foto_profil'],
      lokasi: json['lokasi'],
      trustScore: json['trust_score'] != null
          ? double.parse(json['trust_score'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nik_pengguna': nikPengguna,
      'id_kategori': idKategori,
      'nama_keahlian': namaKeahlian,
      'deskripsi_kebutuhan': deskripsiKebutuhan,
      'tingkat_keahlian_diinginkan': tingkatKeahlianDiinginkan,
      'durasi_estimasi': durasiEstimasi,
      'lokasi_preferensi': lokasiPreferensi,
      'catatan_tambahan': catatanTambahan,
      'status': status,
    };
  }

  SkillRequest copyWith({
    int? id,
    String? nikPengguna,
    int? idKategori,
    String? namaKeahlian,
    String? deskripsiKebutuhan,
    String? tingkatKeahlianDiinginkan,
    String? durasiEstimasi,
    String? lokasiPreferensi,
    String? catatanTambahan,
    String? status,
    DateTime? dibuatPada,
    DateTime? diperbaruiPada,
    String? namaKategori,
    String? kategoriIkon,
    String? namaPemohon,
    String? fotoProfil,
    String? lokasi,
    double? trustScore,
  }) {
    return SkillRequest(
      id: id ?? this.id,
      nikPengguna: nikPengguna ?? this.nikPengguna,
      idKategori: idKategori ?? this.idKategori,
      namaKeahlian: namaKeahlian ?? this.namaKeahlian,
      deskripsiKebutuhan: deskripsiKebutuhan ?? this.deskripsiKebutuhan,
      tingkatKeahlianDiinginkan:
          tingkatKeahlianDiinginkan ?? this.tingkatKeahlianDiinginkan,
      durasiEstimasi: durasiEstimasi ?? this.durasiEstimasi,
      lokasiPreferensi: lokasiPreferensi ?? this.lokasiPreferensi,
      catatanTambahan: catatanTambahan ?? this.catatanTambahan,
      status: status ?? this.status,
      dibuatPada: dibuatPada ?? this.dibuatPada,
      diperbaruiPada: diperbaruiPada ?? this.diperbaruiPada,
      namaKategori: namaKategori ?? this.namaKategori,
      kategoriIkon: kategoriIkon ?? this.kategoriIkon,
      namaPemohon: namaPemohon ?? this.namaPemohon,
      fotoProfil: fotoProfil ?? this.fotoProfil,
      lokasi: lokasi ?? this.lokasi,
      trustScore: trustScore ?? this.trustScore,
    );
  }
}
