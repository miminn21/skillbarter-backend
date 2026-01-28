class CategoryModel {
  final int id;
  final String namaKategori;
  final String? ikon;
  final String? deskripsi;
  final int urutanTampil;

  CategoryModel({
    required this.id,
    required this.namaKategori,
    this.ikon,
    this.deskripsi,
    required this.urutanTampil,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      namaKategori: json['nama_kategori'] ?? '',
      ikon: json['ikon'],
      deskripsi: json['deskripsi'],
      urutanTampil: json['urutan_tampil'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_kategori': namaKategori,
      'ikon': ikon,
      'deskripsi': deskripsi,
      'urutan_tampil': urutanTampil,
    };
  }
}
