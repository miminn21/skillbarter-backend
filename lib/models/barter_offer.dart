class BarterOffer {
  final int? id;
  final String? kodeTransaksi;
  final String nikPenawar;
  final String nikDitawar;
  final int? idKeahlianPenawar; // Nullable for help requests
  final int idKeahlianDiminta;
  final int? idSkillRequest;
  final String tipeTransaksi; // NEW: 'barter' or 'bantuan'
  final int durasiJam;
  final DateTime tanggalPelaksanaan;
  final String tipeLokasi;
  final String? detailLokasi;
  final String? catatanPenawar;
  final String status;
  final bool skillcoinDitransfer;
  final bool ratingDiberikan;
  final DateTime? dibuatPada;
  final DateTime? diperbaruiPada;

  // Additional fields from JOIN
  final String? namaPenawar;
  final String? fotoPenawar;
  final String? kotaPenawar;
  final double? ratingPenawar;
  final String? namaDitawar;
  final String? fotoDitawar;
  final String? kotaDitawar;
  final double? ratingDitawar;
  final String? skillPenawar;
  final String? tingkatPenawar;
  final int? hargaPenawar;
  final String? skillDiminta;
  final String? tingkatDiminta;
  final int? hargaDiminta;
  final String? skillRequestNama;
  final String? skillRequestDeskripsi;

  // Proof of completion
  final String? buktiPelaksanaan; // base64 encoded image
  final String? jenisBukti; // file type (jpg, png, etc)

  // For list view
  final String? namaPartner;
  final String? fotoPartner;
  final String? skillPartner;
  final String? skillOwn;
  final String? role; // 'sent' or 'received'

  BarterOffer({
    this.id,
    this.kodeTransaksi,
    required this.nikPenawar,
    required this.nikDitawar,
    this.idKeahlianPenawar, // Optional for help requests
    required this.idKeahlianDiminta,
    this.idSkillRequest,
    this.tipeTransaksi = 'barter', // Default to barter
    required this.durasiJam,
    required this.tanggalPelaksanaan,
    this.tipeLokasi = 'online',
    this.detailLokasi,
    this.catatanPenawar,
    this.status = 'menunggu',
    this.skillcoinDitransfer = false,
    this.ratingDiberikan = false,
    this.dibuatPada,
    this.diperbaruiPada,
    this.namaPenawar,
    this.fotoPenawar,
    this.kotaPenawar,
    this.ratingPenawar,
    this.namaDitawar,
    this.fotoDitawar,
    this.kotaDitawar,
    this.ratingDitawar,
    this.skillPenawar,
    this.tingkatPenawar,
    this.hargaPenawar,
    this.skillDiminta,
    this.tingkatDiminta,
    this.hargaDiminta,
    this.skillRequestNama,
    this.skillRequestDeskripsi,
    this.buktiPelaksanaan,
    this.jenisBukti,
    this.namaPartner,
    this.fotoPartner,
    this.skillPartner,
    this.skillOwn,
    this.role,
  });

  factory BarterOffer.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert to String (handle JSON objects)
    String? toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      // If it's a Map/List, return null (not a string)
      if (value is Map || value is List) return null;
      return value.toString();
    }

    return BarterOffer(
      id: json['id'],
      kodeTransaksi: toStringOrNull(json['kode_transaksi']),
      nikPenawar: json['nik_penawar'],
      nikDitawar: json['nik_ditawar'],
      idKeahlianPenawar: json['id_keahlian_penawar'],
      idKeahlianDiminta: json['id_keahlian_diminta'],
      idSkillRequest: json['id_skill_request'],
      durasiJam: json['durasi_jam'],
      tanggalPelaksanaan: DateTime.parse(json['tanggal_pelaksanaan']),
      tipeLokasi: json['tipe_lokasi'] ?? 'online',
      detailLokasi: toStringOrNull(json['detail_lokasi']),
      catatanPenawar: toStringOrNull(json['catatan_penawar']),
      status: json['status'] ?? 'menunggu',
      skillcoinDitransfer:
          json['skillcoin_ditransfer'] == 1 ||
          json['skillcoin_ditransfer'] == true,
      ratingDiberikan:
          json['rating_diberikan'] == 1 || json['rating_diberikan'] == true,
      dibuatPada: json['dibuat_pada'] != null
          ? DateTime.parse(json['dibuat_pada'])
          : null,
      diperbaruiPada: json['diperbarui_pada'] != null
          ? DateTime.parse(json['diperbarui_pada'])
          : null,
      namaPenawar: toStringOrNull(json['nama_penawar']),
      fotoPenawar: toStringOrNull(json['foto_penawar']),
      kotaPenawar: toStringOrNull(json['kota_penawar']),
      ratingPenawar: json['rating_penawar'] != null
          ? double.parse(json['rating_penawar'].toString())
          : null,
      namaDitawar: toStringOrNull(json['nama_ditawar']),
      fotoDitawar: toStringOrNull(json['foto_ditawar']),
      kotaDitawar: toStringOrNull(json['kota_ditawar']),
      ratingDitawar: json['rating_ditawar'] != null
          ? double.parse(json['rating_ditawar'].toString())
          : null,
      skillPenawar: toStringOrNull(json['skill_penawar']),
      tingkatPenawar: toStringOrNull(json['tingkat_penawar']),
      hargaPenawar: json['harga_penawar'],
      skillDiminta: toStringOrNull(json['skill_diminta']),
      tingkatDiminta: toStringOrNull(json['tingkat_diminta']),
      hargaDiminta: json['harga_diminta'],
      skillRequestNama: toStringOrNull(json['skill_request_nama']),
      skillRequestDeskripsi: toStringOrNull(json['skill_request_deskripsi']),
      buktiPelaksanaan: toStringOrNull(json['bukti_pelaksanaan']),
      jenisBukti: toStringOrNull(json['jenis_bukti']),
      namaPartner: toStringOrNull(json['nama_partner']),
      fotoPartner: toStringOrNull(json['foto_partner']),
      skillPartner: toStringOrNull(json['skill_partner']),
      skillOwn: toStringOrNull(json['skill_own']),
      role: toStringOrNull(json['role']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nik_ditawar': nikDitawar,
      'id_keahlian_penawar': idKeahlianPenawar,
      'id_keahlian_diminta': idKeahlianDiminta,
      'id_skill_request': idSkillRequest,
      'durasi_jam': durasiJam,
      'tanggal_pelaksanaan': tanggalPelaksanaan.toIso8601String(),
      'tipe_lokasi': tipeLokasi,
      'detail_lokasi': detailLokasi,
      'catatan_penawar': catatanPenawar,
    };
  }

  // Helper methods
  String get statusText {
    switch (status) {
      case 'menunggu':
        return 'Menunggu';
      case 'diterima':
        return 'Diterima';
      case 'ditolak':
        return 'Ditolak';
      case 'berlangsung':
        return 'Berlangsung';
      case 'selesai':
        return 'Selesai';
      case 'terkonfirmasi':
        return 'Terkonfirmasi';
      case 'dibatalkan':
        return 'Dibatalkan';
      case 'kedaluwarsa':
        return 'Kedaluwarsa';
      default:
        return status;
    }
  }

  bool get isPending => status == 'menunggu';
  bool get isAccepted => status == 'diterima';
  bool get isRejected => status == 'ditolak';
  bool get isOngoing => status == 'berlangsung';
  bool get isCompleted => status == 'selesai';
  bool get isConfirmed => status == 'terkonfirmasi';
  bool get isCancelled => status == 'dibatalkan';
  bool get isExpired => status == 'kedaluwarsa';

  // Logical helper to detect help request (bantuan)
  bool get isHelpRequest =>
      tipeTransaksi == 'bantuan' || idKeahlianPenawar == null;

  bool get canAccept => isPending;
  bool get canReject => isPending;
  bool get canCancel => isPending || isAccepted;
  bool get canStart => isAccepted;
  bool get canComplete => isOngoing;
  bool get canConfirm => isCompleted;

  int get skillcoinPenawar => durasiJam * (hargaPenawar ?? 0);
  int get skillcoinDiminta => durasiJam * (hargaDiminta ?? 0);

  String get nikPartner => role == 'sent' ? nikDitawar : nikPenawar;

  BarterOffer copyWith({
    int? id,
    String? kodeTransaksi,
    String? nikPenawar,
    String? nikDitawar,
    int? idKeahlianPenawar,
    int? idKeahlianDiminta,
    int? idSkillRequest,
    String? tipeTransaksi,
    int? durasiJam,
    DateTime? tanggalPelaksanaan,
    String? tipeLokasi,
    String? detailLokasi,
    String? catatanPenawar,
    String? status,
    bool? skillcoinDitransfer,
    bool? ratingDiberikan,
    DateTime? dibuatPada,
    DateTime? diperbaruiPada,
    String? namaPenawar,
    String? fotoPenawar,
    String? kotaPenawar,
    double? ratingPenawar,
    String? namaDitawar,
    String? fotoDitawar,
    String? kotaDitawar,
    double? ratingDitawar,
    String? skillPenawar,
    String? tingkatPenawar,
    int? hargaPenawar,
    String? skillDiminta,
    String? tingkatDiminta,
    int? hargaDiminta,
    String? skillRequestNama,
    String? skillRequestDeskripsi,
    String? namaPartner,
    String? fotoPartner,
    String? skillPartner,
    String? skillOwn,
    String? role,
  }) {
    return BarterOffer(
      id: id ?? this.id,
      kodeTransaksi: kodeTransaksi ?? this.kodeTransaksi,
      nikPenawar: nikPenawar ?? this.nikPenawar,
      nikDitawar: nikDitawar ?? this.nikDitawar,
      idKeahlianPenawar: idKeahlianPenawar ?? this.idKeahlianPenawar,
      idKeahlianDiminta: idKeahlianDiminta ?? this.idKeahlianDiminta,
      idSkillRequest: idSkillRequest ?? this.idSkillRequest,
      tipeTransaksi: tipeTransaksi ?? this.tipeTransaksi,
      durasiJam: durasiJam ?? this.durasiJam,
      tanggalPelaksanaan: tanggalPelaksanaan ?? this.tanggalPelaksanaan,
      tipeLokasi: tipeLokasi ?? this.tipeLokasi,
      detailLokasi: detailLokasi ?? this.detailLokasi,
      catatanPenawar: catatanPenawar ?? this.catatanPenawar,
      status: status ?? this.status,
      skillcoinDitransfer: skillcoinDitransfer ?? this.skillcoinDitransfer,
      ratingDiberikan: ratingDiberikan ?? this.ratingDiberikan,
      dibuatPada: dibuatPada ?? this.dibuatPada,
      diperbaruiPada: diperbaruiPada ?? this.diperbaruiPada,
      namaPenawar: namaPenawar ?? this.namaPenawar,
      fotoPenawar: fotoPenawar ?? this.fotoPenawar,
      kotaPenawar: kotaPenawar ?? this.kotaPenawar,
      ratingPenawar: ratingPenawar ?? this.ratingPenawar,
      namaDitawar: namaDitawar ?? this.namaDitawar,
      fotoDitawar: fotoDitawar ?? this.fotoDitawar,
      kotaDitawar: kotaDitawar ?? this.kotaDitawar,
      ratingDitawar: ratingDitawar ?? this.ratingDitawar,
      skillPenawar: skillPenawar ?? this.skillPenawar,
      tingkatPenawar: tingkatPenawar ?? this.tingkatPenawar,
      hargaPenawar: hargaPenawar ?? this.hargaPenawar,
      skillDiminta: skillDiminta ?? this.skillDiminta,
      tingkatDiminta: tingkatDiminta ?? this.tingkatDiminta,
      hargaDiminta: hargaDiminta ?? this.hargaDiminta,
      skillRequestNama: skillRequestNama ?? this.skillRequestNama,
      skillRequestDeskripsi:
          skillRequestDeskripsi ?? this.skillRequestDeskripsi,
      namaPartner: namaPartner ?? this.namaPartner,
      fotoPartner: fotoPartner ?? this.fotoPartner,
      skillPartner: skillPartner ?? this.skillPartner,
      skillOwn: skillOwn ?? this.skillOwn,
      role: role ?? this.role,
    );
  }
}
