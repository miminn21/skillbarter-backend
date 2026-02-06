import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

// Export background handler so it can be used in main.dart
export 'fcm_service.dart' show firebaseMessagingBackgroundHandler;

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 ===== BACKGROUND MESSAGE RECEIVED =====');
  print('📱 Message ID: ${message.messageId}');
  print('📦 Data: ${message.data}');
  print('🔕 Notification object: ${message.notification}');

  // Explicitly initialize Local Notifications for background isolate
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await localNotifications.initialize(initializationSettings);

  // CRITICAL: Create notification channel BEFORE showing notification
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'skillbarter_urgent_v3',
    'SkillBarter Alerts',
    description: 'Urgent notifications (Offers, Chats)',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    showBadge: true,
  );

  await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  print('✅ Notification channel created in background handler');

  // If message contains data but NO notification payload (Data-Only),
  // parse it and show notification manually.
  if (message.notification == null && message.data.isNotEmpty) {
    String title = message.data['title'] ?? 'SkillBarter';
    String body = message.data['body'] ?? 'You have a new message';

    print('📢 Showing notification: $title - $body');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'skillbarter_urgent_v3', // FIXED: Must match backend & manifest
          'SkillBarter Alerts',
          channelDescription: 'Urgent notifications (Offers, Chats)',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          playSound: true,
          enableVibration: true,
          enableLights: true,
          visibility: NotificationVisibility.public,
          category:
              AndroidNotificationCategory.call, // CRITICAL: Force heads-up
          showWhen: true,
          fullScreenIntent: true, // Force full-screen on some devices
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await localNotifications.show(
      DateTime.now().millisecond, // Unique ID
      title,
      body,
      platformDetails,
      payload: message.data['id_barter'],
    );

    print('✅ Notification displayed successfully');
  } else {
    print(
      '⚠️ Skipping notification display - notification object exists or data is empty',
    );
  }

  print('🔔 ===== BACKGROUND HANDLER COMPLETE =====');
}

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Initialize Local Notifications for Foreground display
      await _initLocalNotifications();

      // 3. Create Notification Channel (Critical for Heads-up)
      await _createNotificationChannel();

      // 3.5. Request Android 13+ Permissions explicitly
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      // NOTE: Background handler is registered in main.dart
      // FirebaseMessaging.onBackgroundMessage() must be called at top-level

      // 4. Get Token and Save to Backend
      // 5. Get Token and Save to Backend
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await _updateBackendToken(token);
      }

      // 6. Build Foreground Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('🔔 Got a message whilst in the foreground!');
        print('📦 Message data: ${message.data}');
        print('🔕 Notification object: ${message.notification}');

        // Handle DATA-ONLY messages (backend sends data-only)
        if (message.notification == null && message.data.isNotEmpty) {
          print('📢 Showing data-only notification in foreground');
          _showDataOnlyNotification(message);
        } else if (message.notification != null) {
          print('📢 Showing standard notification in foreground');
          _showForegroundNotification(message);
        }
      });

      _isInitialized = true;
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'skillbarter_urgent_v3',
      'SkillBarter Alerts',
      description: 'Urgent notifications (Offers, Chats)',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
            print('Notification tapped: ${notificationResponse.payload}');
          },
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'skillbarter_urgent_v3',
            'SkillBarter Alerts',
            channelDescription: 'Important notifications from SkillBarter',
            importance: Importance.max,
            priority: Priority.high,
            category: AndroidNotificationCategory.call,
            showWhen: true,
            visibility: NotificationVisibility.public,
          );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
      );
    }
  }

  Future<void> _showDataOnlyNotification(RemoteMessage message) async {
    // Extract title and body from data payload
    String title = message.data['title'] ?? 'SkillBarter';
    String body = message.data['body'] ?? 'You have a new message';

    print('📢 Displaying data-only notification: $title - $body');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'skillbarter_urgent_v3',
          'SkillBarter Alerts',
          channelDescription: 'Important notifications from SkillBarter',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.call, // Force heads-up
          showWhen: true,
          visibility: NotificationVisibility.public,
          fullScreenIntent: true, // Force full-screen on some devices
          playSound: true,
          enableVibration: true,
          enableLights: true,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond, // Unique ID
      title,
      body,
      platformDetails,
      payload: message.data['id_barter'],
    );

    print('✅ Data-only notification displayed in foreground');
  }

  Future<void> _updateBackendToken(String token) async {
    try {
      // Assuming you have an endpoint to update FCM token
      // You might need to make sure the user is logged in before calling this
      await _apiService.put('/auth/fcm-token', data: {'fcm_token': token});
      print('FCM Token updated to backend successfully');
    } catch (e) {
      print('Failed to update FCM token to backend: $e');
    }
  }
}
