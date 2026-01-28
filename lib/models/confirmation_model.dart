class ConfirmationModel {
  final int idKonfirmasi;
  final int idBarter;
  final String nik;
  final bool konfirmasiSelesai;
  final String? catatan;
  final String? fotoBukti; // base64
  final DateTime? waktuKonfirmasi;
  final DateTime? waktuUploadFoto;

  // From JOIN with pengguna
  final String? namaLengkap;
  final String? confirmationType; // 'own' or 'partner'

  ConfirmationModel({
    required this.idKonfirmasi,
    required this.idBarter,
    required this.nik,
    required this.konfirmasiSelesai,
    this.catatan,
    this.fotoBukti,
    this.waktuKonfirmasi,
    this.waktuUploadFoto,
    this.namaLengkap,
    this.confirmationType,
  });

  factory ConfirmationModel.fromJson(Map<String, dynamic> json) {
    return ConfirmationModel(
      idKonfirmasi: json['id_konfirmasi'] ?? 0,
      idBarter: json['id_barter'] ?? 0,
      nik: json['nik'] ?? '',
      konfirmasiSelesai:
          json['konfirmasi_selesai'] == 1 || json['konfirmasi_selesai'] == true,
      catatan: json['catatan'],
      fotoBukti: json['foto_bukti'],
      waktuKonfirmasi: json['waktu_konfirmasi'] != null
          ? DateTime.parse(json['waktu_konfirmasi'])
          : null,
      waktuUploadFoto: json['waktu_upload_foto'] != null
          ? DateTime.parse(json['waktu_upload_foto'])
          : null,
      namaLengkap: json['nama_lengkap'],
      confirmationType: json['confirmation_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_konfirmasi': idKonfirmasi,
      'id_barter': idBarter,
      'nik': nik,
      'konfirmasi_selesai': konfirmasiSelesai,
      'catatan': catatan,
      'foto_bukti': fotoBukti,
      'waktu_konfirmasi': waktuKonfirmasi?.toIso8601String(),
      'waktu_upload_foto': waktuUploadFoto?.toIso8601String(),
    };
  }

  bool get isOwn => confirmationType == 'own';
  bool get isPartner => confirmationType == 'partner';
  bool get hasProof => fotoBukti != null && fotoBukti!.isNotEmpty;
}
