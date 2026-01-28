class SkillcoinTransaction {
  final int id;
  final String nikPengguna;
  final int? idTransaksi;
  final String jenis;
  final int jumlah;
  final int saldoSebelum;
  final int saldoSesudah;
  final String? keterangan;
  final String? penerimaNik;
  final DateTime dibuatPada;

  // Additional fields from JOIN
  final String? namaPenerima;
  final String? kodeTransaksi;

  SkillcoinTransaction({
    required this.id,
    required this.nikPengguna,
    this.idTransaksi,
    required this.jenis,
    required this.jumlah,
    required this.saldoSebelum,
    required this.saldoSesudah,
    this.keterangan,
    this.penerimaNik,
    required this.dibuatPada,
    this.namaPenerima,
    this.kodeTransaksi,
  });

  factory SkillcoinTransaction.fromJson(Map<String, dynamic> json) {
    return SkillcoinTransaction(
      id: json['id'],
      nikPengguna: json['nik_pengguna'],
      idTransaksi: json['id_transaksi'],
      jenis: json['jenis'],
      jumlah: json['jumlah'],
      saldoSebelum: json['saldo_sebelum'],
      saldoSesudah: json['saldo_sesudah'],
      keterangan: json['keterangan'],
      penerimaNik: json['penerima_nik'],
      dibuatPada: DateTime.parse(json['dibuat_pada']),
      namaPenerima: json['nama_penerima'],
      kodeTransaksi: json['kode_transaksi'],
    );
  }

  // Helper methods
  bool get isIncome => jumlah > 0;
  bool get isExpense => jumlah < 0;

  String get jenisText {
    switch (jenis) {
      case 'bonus_awal':
        return 'Bonus Awal';
      case 'hasil_barter':
        return 'Hasil Barter';
      case 'pengembalian':
        return 'Pengembalian';
      case 'denda':
        return 'Denda';
      case 'hadiah':
        return 'Hadiah';
      case 'transfer_keluar':
        return 'Transfer Keluar';
      case 'transfer_masuk':
        return 'Transfer Masuk';
      case 'tarik':
        return 'Penarikan';
      case 'bayar_verifikasi':
        return 'Bayar Verifikasi';
      default:
        return jenis;
    }
  }
}

class SkillcoinStatistics {
  final int totalTransactions;
  final int totalEarned;
  final int totalSpent;
  final int currentBalance;

  SkillcoinStatistics({
    required this.totalTransactions,
    required this.totalEarned,
    required this.totalSpent,
    required this.currentBalance,
  });

  factory SkillcoinStatistics.fromJson(Map<String, dynamic> json) {
    return SkillcoinStatistics(
      totalTransactions: json['total_transactions'] ?? 0,
      totalEarned: json['total_earned'] ?? 0,
      totalSpent: json['total_spent'] ?? 0,
      currentBalance: json['current_balance'] ?? 0,
    );
  }

  int get netIncome => totalEarned - totalSpent;
}
