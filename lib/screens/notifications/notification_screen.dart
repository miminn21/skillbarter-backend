import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import '../../widgets/status_dialog.dart';
import '../barter/offer_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).fetchNotifications(refresh: true);
    });
  }

  IconData _getIcon(String tipe, String judul) {
    // Specific icons based on notification type
    switch (tipe) {
      // Barter offer notifications
      case 'offer_received':
        return Icons.mail_outline;
      case 'offer_accepted':
        return Icons.check_circle_outline;
      case 'offer_rejected':
        return Icons.cancel_outlined;
      case 'offer_cancelled':
        return Icons.block;
      case 'confirmation_needed':
        return Icons.help_outline;
      case 'barter_completed':
        return Icons.verified;
      case 'barter_started':
        return Icons.play_circle_outline;

      // Help request
      case 'help_request':
        return Icons.volunteer_activism;

      // Review
      case 'review_received':
        return Icons.star_border;

      // SkillCoin notifications - check judul for more specific icons
      case 'skillcoin':
        if (judul.contains('Bertambah') ||
            judul.contains('mendapatkan') ||
            judul.contains('Diterima')) {
          return Icons.add_circle_outline;
        } else if (judul.contains('Berkurang') ||
            judul.contains('digunakan') ||
            judul.contains('membayar')) {
          return Icons.remove_circle_outline;
        } else if (judul.contains('Transfer')) {
          return Icons.send_outlined;
        } else if (judul.contains('Bayaran') || judul.contains('Menerima')) {
          return Icons.account_balance_wallet_outlined;
        } else if (judul.contains('Selamat Datang') ||
            judul.contains('bonus')) {
          return Icons.card_giftcard;
        }
        return Icons.monetization_on_outlined;

      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColor(String tipe, String judul) {
    // Specific colors based on notification type
    switch (tipe) {
      // Positive notifications - Green
      case 'offer_accepted':
      case 'barter_completed':
      case 'barter_started':
        return Colors.green;

      // Negative notifications - Red
      case 'offer_rejected':
      case 'offer_cancelled':
        return Colors.red;

      // Pending/Info notifications - Blue
      case 'offer_received':
      case 'confirmation_needed':
        return Colors.blue;

      // Help request - Orange
      case 'help_request':
        return Colors.orange;

      // Review - Amber
      case 'review_received':
        return Colors.amber;

      // SkillCoin - check judul for more specific colors
      case 'skillcoin':
        if (judul.contains('Bertambah') ||
            judul.contains('mendapatkan') ||
            judul.contains('Diterima') ||
            judul.contains('Selamat Datang')) {
          return Colors.green; // Coin received - green
        } else if (judul.contains('Berkurang') ||
            judul.contains('digunakan') ||
            judul.contains('membayar')) {
          return Colors.orange; // Coin spent - orange
        } else if (judul.contains('Transfer')) {
          return Colors.blue; // Transfer - blue
        } else if (judul.contains('Bayaran') || judul.contains('Menerima')) {
          return Colors.teal; // Payment received - teal
        }
        return Colors.amber; // Default skillcoin - amber

      default:
        return Colors.grey;
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read first
    if (!notification.isRead) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).markAsRead(notification.idNotifikasi);
    }

    // Determine navigation based on type
    if (notification.relatedBarterId != null) {
      // Navigate to barter detail
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OfferDetailScreen(offerId: notification.relatedBarterId!),
        ),
      );
    } else {
      // Fallback or other types (e.g. general info)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Detail tidak tersedia')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Theme.of(context).primaryColor, const Color(0xFF1E88E5)],
            ),
          ),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.done_all_rounded, color: Colors.white),
                  tooltip: 'Tandai semua dibaca',
                  onPressed: () async {
                    // Show confirmation
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 10,
                        backgroundColor: Colors.white,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.checklist_rounded,
                                  size: 40,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Tandai Semua Dibaca?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Semua ${provider.unreadCount} notifikasi akan ditandai sudah dibaca.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      child: Text(
                                        'Batal',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Ya, Tandai',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );

                    if (confirmed == true && mounted) {
                      final success = await provider.markAllAsRead();
                      if (success && mounted) {
                        StatusDialog.show(
                          context,
                          success: true,
                          title: 'Berhasil',
                          message: 'Semua notifikasi ditandai dibaca',
                        );
                      }
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchNotifications(refresh: true),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Belum ada notifikasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aktivitas terbaru akan muncul di sini',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(refresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: provider.notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return Dismissible(
                  key: Key('notif_${notification.idNotifikasi}'),
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text(
                          'Hapus',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.delete_outline_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    provider.deleteNotification(notification.idNotifikasi);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: notification.isRead
                          ? Colors.white
                          : Colors.blue.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: notification.isRead
                            ? Colors.transparent
                            : Colors.blue.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _handleNotificationTap(notification),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getColor(
                                    notification.tipe,
                                    notification.judul,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  _getIcon(
                                    notification.tipe,
                                    notification.judul,
                                  ),
                                  color: _getColor(
                                    notification.tipe,
                                    notification.judul,
                                  ),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notification.judul,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: const Color(0xFF2D3142),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          notification.timeAgo,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[400],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      notification.pesan,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        height: 1.4,
                                      ),
                                    ),
                                    if (!notification.isRead)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Baru',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
