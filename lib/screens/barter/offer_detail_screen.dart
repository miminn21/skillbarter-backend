import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/barter_offer.dart';
import '../../models/confirmation_model.dart';
import '../../providers/barter_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/skillcoin_calculator.dart';
import '../../widgets/beautiful_notification.dart';
import '../../widgets/proof_upload_dialog.dart';
import '../../widgets/rating_dialog.dart';
import '../../services/rating_service.dart';
import '../chat/chat_screen.dart';

class OfferDetailScreen extends StatefulWidget {
  final int offerId;

  const OfferDetailScreen({Key? key, required this.offerId}) : super(key: key);

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  // Track if user has rated this barter
  bool _hasRated = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final barterProvider = Provider.of<BarterProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Pass current user NIK to calculate role (sent/received)
    await barterProvider.fetchOfferDetail(
      widget.offerId,
      currentUserNik: authProvider.user?.nik,
    );

    // Load confirmations
    await barterProvider.loadConfirmations(widget.offerId);

    // Check if I have rated this offer
    try {
      final ratingService = RatingService();
      final check = await ratingService.checkMyRating(widget.offerId);
      if (mounted) {
        setState(() {
          _hasRated = check['hasRated'] == true;
        });
      }
    } catch (e) {
      print('Error checking rating status: $e');
    }
  }

  // ... (Keep existing logic methods: _showUploadProofDialog, _confirmCompletion) ...
  // COPIED LOGIC METHODS FOR BREVITY - WILL BE INCLUDED IN FINAL FILE

  Future<void> _showUploadProofDialog() async {
    showDialog(
      context: context,
      builder: (dialogContext) => ProofUploadDialog(
        onUpload: (fotoBase64, catatan) async {
          Navigator.pop(dialogContext);
          final provider = Provider.of<BarterProvider>(context, listen: false);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (loadingContext) =>
                const Center(child: CircularProgressIndicator()),
          );

          final success = await provider.uploadProof(
            widget.offerId,
            fotoBase64,
            catatan,
          );

          if (mounted) Navigator.of(context, rootNavigator: true).pop();

          if (success) {
            if (mounted) {
              BeautifulNotification.show(
                context,
                title: 'Berhasil!',
                message: 'Bukti pelaksanaan berhasil diupload',
                type: NotificationType.success,
              );
            }
          } else {
            if (mounted) {
              BeautifulNotification.show(
                context,
                title: 'Gagal!',
                message: provider.error ?? 'Gagal upload bukti',
                type: NotificationType.error,
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _confirmCompletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Penyelesaian'),
        content: const Text(
          'Apakah Anda yakin sesi barter sudah selesai dilaksanakan? '
          'Setelah kedua pihak konfirmasi, skillcoin akan ditransfer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Konfirmasi'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = Provider.of<BarterProvider>(context, listen: false);
      final success = await provider.confirmCompletion(widget.offerId, null);

      if (success) {
        if (mounted) {
          BeautifulNotification.show(
            context,
            title: 'Berhasil!',
            message: 'Penyelesaian berhasil dikonfirmasi',
            type: NotificationType.success,
            duration: const Duration(milliseconds: 1500),
          );

          await _loadData();

          if (mounted) {
            await Provider.of<AuthProvider>(
              context,
              listen: false,
            ).refreshUserData();
          }

          final offer = provider.selectedOffer;
          final shouldShowRating =
              (offer != null && mounted) && offer.status == 'terkonfirmasi';

          if (shouldShowRating) {
            final ratingService = RatingService();
            try {
              final check = await ratingService.checkMyRating(offer!.id!);
              if (check['hasRated'] == false) {
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => RatingDialog(
                        partnerName: offer.namaPartner ?? 'Partner',
                        onSubmit: (rating, comment, anonymous) async {
                          await ratingService.submitRating(
                            barterId: offer.id!,
                            rating: rating,
                            comment: comment,
                            anonymous: anonymous,
                          );
                          if (mounted) {
                            await Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            ).refreshUserData();
                            await _loadData();
                          }
                        },
                      ),
                    );
                  }
                });
              }
            } catch (e) {
              print('[Rating] Error checking rating status: $e');
            }
          }
        }
      } else {
        if (mounted) {
          BeautifulNotification.show(
            context,
            title: 'Gagal!',
            message: provider.error ?? 'Gagal konfirmasi',
            type: NotificationType.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Detail Penawaran',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<BarterProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final offer = provider.selectedOffer;
          if (offer == null) {
            return const Center(child: Text('Penawaran tidak ditemukan'));
          }

          return Stack(
            children: [
              // Background Gradient Header
              Align(
                alignment: Alignment.topCenter,
                child: ClipPath(
                  clipper: _HeaderClipper(),
                  child: _AnimatedDetailHeader(),
                ),
              ),

              // Content
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  children: [
                    // 1. STATUS CARD (Overlaying header slightly)
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Kode: ${offer.kodeTransaksi ?? "-"}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Main Info Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Status Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                offer.status,
                              ).withOpacity(0.1),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            child: Column(
                              children: [
                                StatusBadge(status: offer.status, fontSize: 14),
                                const SizedBox(height: 8),
                                Text(
                                  offer.isHelpRequest &&
                                          offer.status == 'menunggu'
                                      ? 'Menunggu partner...'
                                      : 'Status: ${offer.status.toUpperCase()}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _getStatusColor(offer.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Partner & Skill Exchange Info
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Partner Info
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundImage:
                                            offer.fotoPartner != null
                                            ? MemoryImage(
                                                base64Decode(
                                                  offer.fotoPartner!,
                                                ),
                                              )
                                            : null,
                                        child: offer.fotoPartner == null
                                            ? Text(
                                                offer.namaPartner?[0]
                                                        .toUpperCase() ??
                                                    'U',
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            offer.namaPartner ?? 'Unknown',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            offer.role == 'sent'
                                                ? (offer.kotaDitawar ?? '-')
                                                : (offer.kotaPenawar ?? '-'),
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${offer.role == 'sent' ? (offer.ratingDitawar ?? 0.0) : (offer.ratingPenawar ?? 0.0)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.amber,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 32),

                                // Exchange View
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCompactSkillInfo(
                                        'Anda Beri',
                                        offer.skillOwn ?? '-',
                                        Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Icon(
                                        Icons.swap_horiz_rounded,
                                        color: Colors.grey[300],
                                        size: 28,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildCompactSkillInfo(
                                        'Anda Terima',
                                        offer.skillPartner ?? '-',
                                        Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Skillcoin Calc
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SkillcoinCalculator(
                        durasiJam: offer.durasiJam ?? 0,
                        hargaPerJamAnda:
                            (offer.role == 'sent'
                                ? offer.hargaPenawar
                                : offer.hargaDiminta) ??
                            0,
                        hargaPerJamPartner:
                            (offer.role == 'sent'
                                ? offer.hargaDiminta
                                : offer.hargaPenawar) ??
                            0,
                        skillAnda: offer.skillOwn ?? '-',
                        skillPartner: offer.skillPartner ?? '-',
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Transaction Details
                    _buildSectionHeader('Detail Transaksi'),
                    const SizedBox(height: 12),
                    _buildModernTransactionDetails(offer),

                    const SizedBox(height: 24),

                    // Confirmation Status (if active)
                    if (offer.status == 'berlangsung') ...[
                      _buildConfirmationStatus(provider),
                      const SizedBox(height: 24),
                    ],

                    // Action Buttons
                    _buildActionButtons(context, provider, offer),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return Colors.orange;
      case 'diterima':
        return Colors.blue;
      case 'berlangsung':
        return Colors.purple;
      case 'selesai':
        return Colors.green;
      case 'terkonfirmasi':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'dibatalkan':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCompactSkillInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(Icons.work_outline, size: 14, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernTransactionDetails(BarterOffer offer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.calendar_month_rounded,
            'Tanggal',
            DateFormat('dd MMMM yyyy').format(offer.tanggalPelaksanaan),
            Colors.blue,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.grey[100]),
          ),
          _buildDetailRow(
            Icons.timer_rounded,
            'Durasi',
            '${offer.durasiJam} Jam',
            Colors.orange,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.grey[100]),
          ),
          _buildDetailRow(
            Icons.location_on_rounded,
            'Lokasi',
            offer.tipeLokasi == 'online'
                ? 'Online Meeting'
                : (offer.detailLokasi ?? 'Offline'),
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ... (Keep existing _buildConfirmationStatus, _buildConfirmationRow, _buildActionButtons, _buildSectionHeader) ...
  // Since I am replacing the whole file content structure, I need to include these methods.

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildConfirmationStatus(BarterProvider provider) {
    // ... (Same implementation as before but with better card styling)
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final myNik = auth.user?.nik;

    final myConf = provider.confirmations.cast<ConfirmationModel?>().firstWhere(
      (c) => c?.nik == myNik,
      orElse: () => null,
    );

    final partnerConf = provider.confirmations
        .cast<ConfirmationModel?>()
        .firstWhere((c) => c?.nik != myNik, orElse: () => null);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Status Konfirmasi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildConfirmationRow('Anda', myConf),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.grey[100]),
          ),
          _buildConfirmationRow('Partner', partnerConf),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(String label, ConfirmationModel? conf) {
    final isConfirmed = conf?.konfirmasiSelesai == true;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (isConfirmed && conf!.fotoBukti != null)
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => Dialog(
                        child: Image.memory(base64Decode(conf.fotoBukti!)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.image, size: 16),
                  label: const Text('Lihat Bukti'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isConfirmed ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isConfirmed
                  ? Colors.green.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isConfirmed ? Icons.check_circle : Icons.pending,
                size: 14,
                color: isConfirmed ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                isConfirmed ? 'Selesai' : 'Pending',
                style: TextStyle(
                  color: isConfirmed ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    BarterProvider provider,
    BarterOffer offer,
  ) {
    if (offer.isHelpRequest &&
        offer.status == 'menunggu' &&
        offer.role == 'sent') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Batalkan Permintaan?'),
                content: const Text(
                  'Permintaan bantuan ini akan dihapus dan tidak dapat dikembalikan.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Tidak'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Ya, Batalkan'),
                  ),
                ],
              ),
            );

            if (confirm == true && mounted) {
              final success = await provider.cancelOffer(
                offer.id!,
                reason: 'Dibatalkan oleh pengguna',
              );
              if (success && mounted) {
                Navigator.pop(context);
                BeautifulNotification.show(
                  context,
                  title: 'Dibatalkan',
                  message: 'Request bantuan berhasil dibatalkan',
                  type: NotificationType.success,
                );
              }
            }
          },
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          label: const Text(
            'Batalkan Permintaan',
            style: TextStyle(color: Colors.red),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    final isSent = offer.role == 'sent';

    if (offer.status == 'menunggu') {
      if (isSent) {
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              final success = await provider.cancelOffer(
                offer.id!,
                reason: 'Dibatalkan user',
              );
              if (success && mounted) Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Batalkan Penawaran'),
          ),
        );
      } else {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final success = await provider.rejectOffer(
                    offer.id!,
                    reason: 'Ditolak user',
                  );
                  if (success && mounted) {
                    await BeautifulNotification.show(
                      context,
                      title: 'Ditolak',
                      message: 'Penawaran berhasil ditolak',
                      type: NotificationType.error,
                    );
                    if (mounted) Navigator.pop(context);
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Tolak'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final success = await provider.acceptOffer(offer.id!);
                  if (success && mounted) {
                    await BeautifulNotification.show(
                      context,
                      title: 'Berhasil',
                      message: 'Tawaran diterima!',
                      type: NotificationType.success,
                    );
                    _loadData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Terima'),
              ),
            ),
          ],
        );
      }
    }

    if (offer.status == 'diterima') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final success = await provider.startSession(offer.id!);
                if (success && mounted) {
                  BeautifulNotification.show(
                    context,
                    title: 'Mulai',
                    message: 'Sesi barter dimulai!',
                    type: NotificationType.info,
                  );
                  _loadData();
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Mulai Sesi Sekarang'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildChatButton(offer),
        ],
      );
    }

    if (offer.status == 'berlangsung') {
      return Column(
        children: [
          _buildChatButton(offer),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showUploadProofDialog(),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Bukti & Selesaikan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _confirmCompletion,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Konfirmasi Selesai (Tanpa Bukti)'),
            ),
          ),
        ],
      );
    }

    if (offer.status == 'selesai' || offer.status == 'terkonfirmasi') {
      return _buildChatButton(offer);
    }

    return const SizedBox.shrink();
  }

  Widget _buildChatButton(BarterOffer offer) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                transactionId: offer.id!,
                partnerNik: offer.nikPartner,
                partnerName: offer.namaPartner ?? 'Partner',
                partnerPhoto: offer.fotoPartner,
              ),
            ),
          );
        },
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Chat dengan Partner'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// HEADER ANIMATION WIDGET (COPIED AND SIMPLIFIED)
class _AnimatedDetailHeader extends StatefulWidget {
  const _AnimatedDetailHeader();

  @override
  State<_AnimatedDetailHeader> createState() => _AnimatedDetailHeaderState();
}

class _AnimatedDetailHeaderState extends State<_AnimatedDetailHeader>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250, // Slightly shorter than profile
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            const Color(0xFF1E88E5), // Lighter blue
            const Color(0xFF1565C0), // Darker blue
          ],
        ),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller1,
            builder: (context, child) {
              return Positioned(
                top: -30 + (_controller1.value * 20),
                left: -30 + (_controller1.value * 30),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller2,
            builder: (context, child) {
              return Positioned(
                bottom: 20 + (_controller2.value * 30),
                right: -20 + (_controller2.value * 20),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    var firstControlPoint = Offset(size.width / 2, size.height + 20);
    var firstEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
