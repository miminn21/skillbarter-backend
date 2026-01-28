class Review {
  final int id;
  final int idBarter;
  final String nikReviewer;
  final String nikReviewed;
  final int rating;
  final String? komentar;
  final DateTime createdAt;

  // From JOIN
  final String? namaReviewer;
  final String? fotoReviewer;
  final int? idBarterRef;
  final DateTime? tanggalPelaksanaan;

  Review({
    required this.id,
    required this.idBarter,
    required this.nikReviewer,
    required this.nikReviewed,
    required this.rating,
    this.komentar,
    required this.createdAt,
    this.namaReviewer,
    this.fotoReviewer,
    this.idBarterRef,
    this.tanggalPelaksanaan,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id_review'],
      idBarter: json['id_barter'],
      nikReviewer: json['nik_reviewer'],
      nikReviewed: json['nik_reviewed'],
      rating: json['rating'],
      komentar: json['komentar'],
      createdAt: DateTime.parse(json['created_at']),
      namaReviewer: json['nama_reviewer'],
      fotoReviewer: json['foto_reviewer'],
      idBarterRef: json['id_barter_ref'],
      tanggalPelaksanaan: json['tanggal_pelaksanaan'] != null
          ? DateTime.parse(json['tanggal_pelaksanaan'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id_barter': idBarter, 'rating': rating, 'komentar': komentar};
  }

  // Helper methods
  String get ratingText {
    switch (rating) {
      case 5:
        return 'Sangat Baik';
      case 4:
        return 'Baik';
      case 3:
        return 'Cukup';
      case 2:
        return 'Kurang';
      case 1:
        return 'Sangat Kurang';
      default:
        return 'Unknown';
    }
  }

  bool get hasComment => komentar != null && komentar!.isNotEmpty;
}

class ReviewStats {
  final double avgRating;
  final int totalReviews;
  final Map<int, int>? distribution;

  ReviewStats({
    required this.avgRating,
    required this.totalReviews,
    this.distribution,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    Map<int, int>? dist;
    if (json['distribution'] != null) {
      dist = {};
      for (var item in json['distribution']) {
        dist[item['rating'] as int] = item['count'] as int;
      }
    }

    return ReviewStats(
      avgRating: json['avgRating'] != null
          ? double.parse(json['avgRating'].toString())
          : 0.0,
      totalReviews: json['totalReviews'] ?? 0,
      distribution: dist,
    );
  }

  String get ratingDisplay => avgRating.toStringAsFixed(1);

  int getCountForRating(int rating) {
    return distribution?[rating] ?? 0;
  }
}
