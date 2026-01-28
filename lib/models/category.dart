class Category {
  final int id;
  final String namaKategori;
  final String? ikon;
  final String? deskripsi;

  Category({
    required this.id,
    required this.namaKategori,
    this.ikon,
    this.deskripsi,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      namaKategori: json['nama_kategori'],
      ikon: json['ikon'],
      deskripsi: json['deskripsi'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_kategori': namaKategori,
      'ikon': ikon,
      'deskripsi': deskripsi,
    };
  }
}
