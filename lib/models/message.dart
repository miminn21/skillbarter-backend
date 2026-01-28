class Message {
  final int id;
  final String nikPengirim;
  final String nikPenerima;
  final int? idTransaksi;
  final String isiPesan;
  final String tipe;
  final DateTime dibuatPada;

  Message({
    required this.id,
    required this.nikPengirim,
    required this.nikPenerima,
    this.idTransaksi,
    required this.isiPesan,
    required this.tipe,
    required this.dibuatPada,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      nikPengirim: json['nik_pengirim'],
      nikPenerima: json['nik_penerima'],
      idTransaksi: json['id_transaksi'],
      isiPesan: json['isi_pesan'] ?? '',
      tipe: json['tipe'] ?? 'teks',
      dibuatPada: DateTime.parse(json['dibuat_pada']),
    );
  }
}
