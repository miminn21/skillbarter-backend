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

  Future<void> _showUploadProofDialog() async {
    showDialog(
      context: context,
      builder: (dialogContext) => ProofUploadDialog(
        onUpload: (fotoBase64, catatan) async {
          // Close dialog first
          Navigator.pop(dialogContext);

          // Use State's context, not dialog context
          final provider = Provider.of<BarterProvider>(context, listen: false);

          // Show loading with State's context
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

          // Close loading dialog
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

          // Reload data to get updated status
          await _loadData();

          // Refresh user data (SkillCoin balance) immediately
          if (mounted) {
            await Provider.of<AuthProvider>(
              context,
              listen: false,
            ).refreshUserData();
          }

          // Check if both parties have confirmed (status becomes 'terkonfirmasi')
          final offer = provider.selectedOffer;

          // Only allow rating if status is officially confirmed (both parties agreed)
          final shouldShowRating =
              (offer != null && mounted) && offer.status == 'terkonfirmasi';

          if (shouldShowRating) {
            // Check if user hasn't rated yet
            final ratingService = RatingService();
            try {
              final check = await ratingService.checkMyRating(offer!.id!);
              if (check['hasRated'] == false) {
                // Show rating dialog after a short delay
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
                          // Refresh user data to update rating
                          if (mounted) {
                            await Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            ).refreshUserData();

                            // Refresh offer data to show rating provided
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
      appBar: AppBar(title: const Text('Detail Penawaran'), elevation: 0),
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. STATUS HEADER
              _buildStatusSection(offer),
              const SizedBox(height: 24),

              // 2. PARTNER INFO (Always show)
              _buildSectionHeader('Partner'),
              const SizedBox(height: 12),
              _buildPartnerCard(offer),
              const SizedBox(height: 24),

              // 3. SKILL DETAILS
              _buildSectionHeader(
                offer.isHelpRequest ? 'Detail Permintaan' : 'Detail Pertukaran',
              ),
              const SizedBox(height: 12),
              _buildSkillDetails(offer),
              const SizedBox(height: 24),

              // 4. TRANSACTION DETAILS (Always show)
              _buildSectionHeader('Detail Transaksi'),
              const SizedBox(height: 12),
              _buildTransactionDetails(offer),
              const SizedBox(height: 24),

              // 5. CONFIRMATION STATUS (Show for active sessions)
              if (offer.status == 'berlangsung') ...[
                _buildConfirmationStatus(provider),
                const SizedBox(height: 24),
              ],

              // 6. ACTION BUTTONS
              _buildActionButtons(context, provider, offer),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatusSection(BarterOffer offer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          StatusBadge(status: offer.status, fontSize: 16),
          const SizedBox(height: 8),
          Text(
            offer.isHelpRequest && offer.status == 'menunggu'
                ? 'Permintaan bantuan Anda sedang aktif menunggu partner.'
                : 'Status saat ini: ${offer.status.toUpperCase()}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          if (offer.kodeTransaksi != null) ...[
            const SizedBox(height: 8),
            Text(
              'Kode: ${offer.kodeTransaksi}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartnerCard(BarterOffer offer) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: offer.fotoPartner != null
                  ? MemoryImage(base64Decode(offer.fotoPartner!))
                  : null,
              child: offer.fotoPartner == null
                  ? Text(
                      offer.namaPartner?[0].toUpperCase() ?? 'U',
                      style: const TextStyle(fontSize: 24),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.namaPartner ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(
                        ' ${offer.role == 'sent' ? (offer.ratingDitawar ?? 0.0) : (offer.ratingPenawar ?? 0.0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                        size: 16,
                      ),
                      Text(
                        ' ${offer.role == 'sent' ? (offer.kotaDitawar ?? '-') : (offer.kotaPenawar ?? '-')}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillDetails(BarterOffer offer) {
    // Reverted to standard view for all request types per user preference
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Row 1: Skills
            Row(
              children: [
                Expanded(
                  child: _buildSkillInfo(
                    'Skill Anda',
                    offer.skillOwn ?? '-',
                    Colors.blue.shade100,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.swap_horiz, size: 32, color: Colors.grey),
                ),
                Expanded(
                  child: _buildSkillInfo(
                    'Skill Partner',
                    offer.skillPartner ?? '-',
                    Colors.orange.shade100,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Skillcoin calculation
            // Skillcoin calculation
            SkillcoinCalculator(
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
          ],
        ),
      ),
    );
  }

  Widget _buildSkillInfo(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails(BarterOffer offer) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow(
              Icons.calendar_today,
              'Tanggal Pelaksanaan',
              DateFormat('dd MMMM yyyy').format(offer.tanggalPelaksanaan),
            ),
            const Divider(),
            _buildDetailRow(
              Icons.access_time,
              'Durasi Sesi',
              '${offer.durasiJam} Jam',
            ),
            const Divider(),
            _buildDetailRow(
              Icons.place,
              'Lokasi',
              offer.tipeLokasi == 'online'
                  ? 'Online Meeting'
                  : (offer.detailLokasi ?? 'Offline'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStatus(BarterProvider provider) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final myNik = auth.user?.nik;

    final myConf = provider.confirmations.cast<ConfirmationModel?>().firstWhere(
      (c) => c?.nik == myNik,
      orElse: () => null,
    );

    final partnerConf = provider.confirmations
        .cast<ConfirmationModel?>()
        .firstWhere((c) => c?.nik != myNik, orElse: () => null);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Konfirmasi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildConfirmationRow('Anda', myConf),
            const Divider(),
            _buildConfirmationRow('Partner', partnerConf),
          ],
        ),
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
                    // Show proof image
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
              color: isConfirmed ? Colors.green : Colors.orange,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isConfirmed ? Icons.check_circle : Icons.pending,
                size: 16,
                color: isConfirmed ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                isConfirmed ? 'Sudah Konfirmasi' : 'Belum Konfirmasi',
                style: TextStyle(
                  color: isConfirmed ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
    // 1. REQUEST LOGIC
    // Helper logic for help request cancellation
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
          ),
        ),
      );
    }

    // 2. BARTER LOGIC
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
                    _loadData(); // Refresh page data
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                child: const Text('Terima'),
              ),
            ),
          ],
        );
      }
    }

    // 2. START SESSION LOGIC (and Chat) for 'diterima'
    if (offer.status == 'diterima') {
      return Column(
        children: [
          // Start Button (Primary)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final success = await provider.startSession(offer.id!);
                if (success && mounted) {
                  BeautifulNotification.show(
                    context,
                    title: 'Mulai',
                    message: 'Sesi barter dimulai',
                    type: NotificationType.success,
                  );
                  _loadData();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Mulai Sesi Barter'),
            ),
          ),
          const SizedBox(height: 16),
          // Chat Button (Secondary - Below Start)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final partnerName = offer.namaPartner ?? 'Partner';
                final partnerNik = offer.nikPartner ?? '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      transactionId: offer.id!,
                      partnerName: partnerName,
                      partnerNik: partnerNik,
                      partnerPhoto: offer.fotoPartner,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat Partner'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      );
    }

    // 3. ACTIVE/COMPLETED SESSION LOGIC
    if (['berlangsung', 'selesai', 'terkonfirmasi'].contains(offer.status)) {
      // Determine partner info (for chat screen)
      final partnerName = offer.namaPartner ?? 'Partner';
      final partnerNik = offer.nikPartner ?? '';

      return Column(
        children: [
          // Chat Button (Available anytime here)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      transactionId: offer.id!,
                      partnerName: partnerName,
                      partnerNik: partnerNik,
                      partnerPhoto: offer.fotoPartner,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat Partner'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          // Logic for 'berlangsung' confirm/status
          if (offer.status == 'berlangsung') ...[
            const SizedBox(height: 16),
            _buildBerlangsungStatus(context, provider, offer),
          ],

          // Logic for 'terkonfirmasi' / 'selesai' rating
          if (offer.status == 'terkonfirmasi' || offer.status == 'selesai') ...[
            const SizedBox(height: 16),
            _buildCompletedStatus(context, offer),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }

  // Helper for 'berlangsung' status content
  Widget _buildBerlangsungStatus(
    BuildContext context,
    BarterProvider provider,
    BarterOffer offer,
  ) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final myConf = provider.confirmations.cast<ConfirmationModel?>().firstWhere(
      (c) => c?.nik == auth.user?.nik,
      orElse: () => null,
    );

    if (myConf?.konfirmasiSelesai == true) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(height: 8),
            Text(
              'Anda sudah konfirmasi selesai',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Menunggu konfirmasi partner...',
              style: TextStyle(color: Colors.green),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showUploadProofDialog,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Bukti Pelaksanaan'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (myConf?.fotoBukti == null) ? null : _confirmCompletion,
            icon: const Icon(Icons.check),
            label: const Text('Konfirmasi Selesai'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: (myConf?.fotoBukti == null)
                  ? Colors.grey
                  : Colors.green,
            ),
          ),
        ),
        if (myConf?.fotoBukti == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '*Upload foto bukti dulu sebelum konfirmasi',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
      ],
    );
  }

  // Helper for 'terkonfirmasi'/'selesai'
  Widget _buildCompletedStatus(BuildContext context, BarterOffer offer) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Transaksi Selesai',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        // Only show rating button if NOT rated yet
        if (!_hasRated && !_OfferDetailScreenState.hasShownRatingDialog) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showRatingDialog,
              icon: const Icon(Icons.star),
              label: const Text('Beri Rating Partner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ] else if (_hasRated) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  'Anda sudah memberi rating',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Static field to track if dialog is currently shown to prevent duplicates
  static bool hasShownRatingDialog = false;

  void _showRatingDialog() {
    final offer = Provider.of<BarterProvider>(
      context,
      listen: false,
    ).selectedOffer;
    if (offer == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        partnerName: offer.namaPartner ?? 'Partner',
        onSubmit: (rating, comment, anonymous) async {
          try {
            final ratingService = RatingService();
            await ratingService.submitRating(
              barterId: offer.id!,
              rating: rating,
              comment: comment,
              anonymous: anonymous,
            );

            if (mounted) {
              BeautifulNotification.show(
                context,
                title: 'Berhasil',
                message: 'Rating berhasil dikirim',
                type: NotificationType.success,
              );
              // Update hasRated state locally immediately
              setState(() {
                _hasRated = true;
              });

              // Refresh data
              await Provider.of<AuthProvider>(
                context,
                listen: false,
              ).refreshUserData();
              Navigator.pop(context); // Close dialog
            }
          } catch (e) {
            if (mounted) {
              BeautifulNotification.show(
                context,
                title: 'Gagal',
                message: 'Gagal mengirim rating: $e',
                type: NotificationType.error,
              );
            }
          }
        },
      ),
    );
  }
}
