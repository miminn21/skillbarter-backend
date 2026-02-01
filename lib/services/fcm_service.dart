import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../providers/notification_provider.dart';
import 'api_service.dart';

/// Firebase Cloud Messaging Service
/// Handles push notification delivery and user interactions

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Background message received: ${message.notification?.title}');
  // Handle background notification
  // Note: Cannot update UI here, only process data
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  NotificationProvider? _notificationProvider;
  BuildContext? _context;

  /// Initialize FCM service
  /// Call this after user login
  Future<void> initialize(
    NotificationProvider notificationProvider,
    BuildContext context,
  ) async {
    _notificationProvider = notificationProvider;
    _context = context;

    debugPrint('[FCM] Initializing Firebase Cloud Messaging...');

    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ FCM permission granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('⚠️ FCM provisional permission granted');
    } else {
      debugPrint('❌ FCM permission denied');
      return;
    }

    // Get FCM token
    String? token = await _fcm.getToken();
    if (token != null) {
      debugPrint('📱 FCM Token: ${token.substring(0, 20)}...');
      await _sendTokenToBackend(token);
    } else {
      debugPrint('❌ Failed to get FCM token');
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM token refreshed');
      _sendTokenToBackend(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Check if app was opened from notification
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('📬 App opened from notification');
      _handleNotificationTap(initialMessage);
    }

    debugPrint('✅ FCM initialized successfully');
  }

  /// Send FCM token to backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final response = await ApiService().put(
        '/auth/fcm-token',
        data: {'fcm_token': token},
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] == true) {
        debugPrint('✅ FCM token sent to backend');
      } else {
        debugPrint('⚠️ Failed to send FCM token: ${responseData['message']}');
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM token: $e');
    }
  }

  /// Handle foreground message (app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📬 Foreground message received');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');

    // Refresh notifications
    _notificationProvider?.fetchNotifications();
    _notificationProvider?.fetchUnreadCount();

    // Show in-app snackbar (optional)
    if (_context != null && message.notification != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.notification!.title ?? 'Notifikasi Baru',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message.notification!.body ?? '',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Lihat',
            onPressed: () => _handleNotificationTap(message),
          ),
        ),
      );
    }
  }

  /// Handle notification tap (navigate to detail)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped');
    debugPrint('   Data: ${message.data}');

    if (_context == null) {
      debugPrint('⚠️ Context is null, cannot navigate');
      return;
    }

    // Navigate based on notification type
    final idBarter = message.data['id_barter'];

    if (idBarter != null && idBarter.isNotEmpty) {
      try {
        final barterId = int.parse(idBarter);

        // Navigate to offer detail screen
        Navigator.pushNamed(
          _context!,
          '/offer-detail',
          arguments: {'offerId': barterId},
        );
      } catch (e) {
        debugPrint('❌ Error parsing barter ID: $e');
      }
    } else {
      // Navigate to notification screen
      Navigator.pushNamed(_context!, '/notifications');
    }
  }

  /// Delete FCM token (call on logout)
  Future<void> deleteToken() async {
    try {
      await _fcm.deleteToken();
      debugPrint('✅ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }
}
