class BarterConfirmation {
  final int idKonfirmasi;
  final int idBarter;
  final String nik;
  final bool konfirmasiSelesai;
  final String? catatan;
  final String? fotoBukti; // NEW: Base64 proof photo
  final DateTime? waktuUploadFoto; // NEW: When photo was uploaded
  final DateTime waktuKonfirmasi;

  // From JOIN
  final String? namaLengkap;
  final String? fotoProfil;
  final String? confirmationType; // 'own' or 'partner'

  BarterConfirmation({
    required this.idKonfirmasi,
    required this.idBarter,
    required this.nik,
    required this.konfirmasiSelesai,
    this.catatan,
    this.fotoBukti,
    this.waktuUploadFoto,
    required this.waktuKonfirmasi,
    this.namaLengkap,
    this.fotoProfil,
    this.confirmationType,
  });

  factory BarterConfirmation.fromJson(Map<String, dynamic> json) {
    return BarterConfirmation(
      idKonfirmasi: json['id_konfirmasi'],
      idBarter: json['id_barter'],
      nik: json['nik'],
      konfirmasiSelesai:
          json['konfirmasi_selesai'] == 1 || json['konfirmasi_selesai'] == true,
      catatan: json['catatan'],
      fotoBukti: json['foto_bukti'],
      waktuUploadFoto: json['waktu_upload_foto'] != null
          ? DateTime.parse(json['waktu_upload_foto'])
          : null,
      waktuKonfirmasi: DateTime.parse(json['waktu_konfirmasi']),
      namaLengkap: json['nama_lengkap'],
      fotoProfil: json['foto_profil'],
      confirmationType: json['confirmation_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id_barter': idBarter, 'catatan': catatan};
  }

  // Helper methods
  String get statusText =>
      konfirmasiSelesai ? 'Sudah Konfirmasi' : 'Belum Konfirmasi';

  bool get hasNote => catatan != null && catatan!.isNotEmpty;
}

class BarterConfirmationStatus {
  final bool penawarConfirmed;
  final bool ditawarConfirmed;
  final bool bothConfirmed;
  final List<BarterConfirmation> confirmations;

  BarterConfirmationStatus({
    required this.penawarConfirmed,
    required this.ditawarConfirmed,
    required this.confirmations,
  }) : bothConfirmed = penawarConfirmed && ditawarConfirmed;

  factory BarterConfirmationStatus.fromConfirmations(
    List<BarterConfirmation> confirmations,
    String nikPenawar,
    String nikDitawar,
  ) {
    final penawarConf = confirmations.any(
      (c) => c.nik == nikPenawar && c.konfirmasiSelesai,
    );
    final ditawarConf = confirmations.any(
      (c) => c.nik == nikDitawar && c.konfirmasiSelesai,
    );

    return BarterConfirmationStatus(
      penawarConfirmed: penawarConf,
      ditawarConfirmed: ditawarConf,
      confirmations: confirmations,
    );
  }

  String get statusMessage {
    if (bothConfirmed) {
      return 'Kedua pihak sudah konfirmasi';
    } else if (penawarConfirmed || ditawarConfirmed) {
      return 'Menunggu konfirmasi dari partner';
    } else {
      return 'Belum ada konfirmasi';
    }
  }
}
