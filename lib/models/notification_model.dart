class NotificationModel {
  final int id;
  final String nik;
  final String tipe;
  final String judul;
  final String pesan;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.nik,
    required this.tipe,
    required this.judul,
    required this.pesan,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id_notifikasi'],
      nik: json['nik'],
      tipe: json['tipe'],
      judul: json['judul'],
      pesan: json['pesan'],
      data: json['data'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_notifikasi': id,
      'nik': nik,
      'tipe': tipe,
      'judul': judul,
      'pesan': pesan,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper methods
  String get tipeText {
    switch (tipe) {
      case 'offer_received':
        return 'Penawaran Diterima';
      case 'offer_accepted':
        return 'Penawaran Disetujui';
      case 'offer_rejected':
        return 'Penawaran Ditolak';
      case 'offer_cancelled':
        return 'Penawaran Dibatalkan';
      case 'confirmation_needed':
        return 'Perlu Konfirmasi';
      case 'barter_completed':
        return 'Barter Selesai';
      case 'review_received':
        return 'Review Diterima';
      case 'skillcoin_received':
        return 'SkillCoin Diterima';
      case 'skillcoin_sent':
        return 'SkillCoin Terkirim';
      case 'barter_started':
        return 'Barter Dimulai';
      default:
        return tipe;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} minggu lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  // Get related ID from data
  int? get relatedBarterId => data?['id_barter'];
  String? get relatedNik => data?['nik_penawar'] ?? data?['nik_ditawar'];

  // Check notification type
  bool get isOfferNotification => tipe.startsWith('offer_');
  bool get isBarterNotification => tipe.startsWith('barter_');
  bool get isSkillCoinNotification => tipe.startsWith('skillcoin_');
  bool get isReviewNotification => tipe == 'review_received';

  NotificationModel copyWith({
    int? id,
    String? nik,
    String? tipe,
    String? judul,
    String? pesan,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      nik: nik ?? this.nik,
      tipe: tipe ?? this.tipe,
      judul: judul ?? this.judul,
      pesan: pesan ?? this.pesan,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
