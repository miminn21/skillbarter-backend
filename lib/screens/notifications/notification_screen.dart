import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';

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

  IconData _getIcon(String tipe) {
    if (tipe.startsWith('offer_')) return Icons.local_offer;
    if (tipe.startsWith('skillcoin_')) return Icons.monetization_on;
    if (tipe.startsWith('barter_')) return Icons.swap_horiz;
    if (tipe == 'review_received') return Icons.star;
    return Icons.notifications;
  }

  Color _getColor(String tipe) {
    if (tipe.startsWith('offer_')) return Colors.blue;
    if (tipe.startsWith('skillcoin_')) return Colors.amber;
    if (tipe == 'offer_accepted' || tipe == 'barter_completed') {
      return Colors.green;
    }
    if (tipe == 'offer_rejected' || tipe == 'offer_cancelled') {
      return Colors.red;
    }
    return Colors.grey;
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
    // Note: We might need to add specific routes or args for deep linking later
    if (notification.relatedBarterId != null) {
      // Navigate to barter detail?
      // For now, just show a snackbar or navigate to transactions tab
      Navigator.pushNamed(context, '/transactions');
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
              if (provider.notifications.any((n) => !n.isRead)) {
                return TextButton(
                  onPressed: () {
                    provider.markAllAsRead();
                  },
                  child: const Text('Baca Semua'),
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
                  child: Container(
                    color: notification.isRead
                        ? null
                        : Theme.of(context).primaryColor.withOpacity(0.05),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getColor(
                          notification.tipe,
                        ).withOpacity(0.1),
                        child: Icon(
                          _getIcon(notification.tipe),
                          color: _getColor(notification.tipe),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        notification.judul,
                        style: TextStyle(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            notification.pesan,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
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
