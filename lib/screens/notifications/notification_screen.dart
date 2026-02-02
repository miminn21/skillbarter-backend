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
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              // Show button if unread count > 0 (matches badge logic)
              if (provider.unreadCount > 0) {
                return TextButton.icon(
                  onPressed: () async {
                    // Show confirmation dialog (Custom Beautified Dialog)
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
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
                                  size: 48,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Tandai Semua Dibaca?',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Semua ${provider.unreadCount} notifikasi akan ditandai sudah dibaca.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
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
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        foregroundColor: Colors.grey[600],
                                      ),
                                      child: const Text('Batal'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Ya, Tandai'),
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
                          title: 'Berhasil!',
                          message: 'Semua notifikasi telah ditandai dibaca',
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 20),
                  label: const Text('Baca Semua'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
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
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  TextButton(
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
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(refresh: true),
            child: ListView.builder(
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return Dismissible(
                  key: Key('notif_${notification.idNotifikasi}'),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    provider.deleteNotification(notification.idNotifikasi);
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    elevation: notification.isRead ? 0 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: notification.isRead
                            ? Colors.grey.withOpacity(0.2)
                            : _getColor(
                                notification.tipe,
                                notification.judul,
                              ).withOpacity(0.3),
                        width: notification.isRead ? 0.5 : 1.5,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getColor(
                            notification.tipe,
                            notification.judul,
                          ).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIcon(notification.tipe, notification.judul),
                          color: _getColor(
                            notification.tipe,
                            notification.judul,
                          ),
                          size: 24,
                        ),
                      ),
                      title: Text(
                        notification.judul,
                        style: TextStyle(
                          fontWeight: notification.isRead
                              ? FontWeight.w500
                              : FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            notification.pesan,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                notification.timeAgo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              if (!notification.isRead) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _getColor(
                                      notification.tipe,
                                      notification.judul,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      onTap: () => _handleNotificationTap(notification),
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
