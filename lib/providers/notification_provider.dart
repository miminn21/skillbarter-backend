import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  Timer? _pollingTimer;
  AuthProvider? _authProvider;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize with AuthProvider to handle lifecycle based on auth state
  void updateAuth(AuthProvider auth) {
    _authProvider = auth;

    if (_authProvider?.isAuthenticated == true) {
      _startPolling();
      fetchNotifications();
      fetchUnreadCount();
    } else {
      _stopPolling();
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
    }
  }

  void _startPolling() {
    _stopPolling();
    // Poll every 30 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_authProvider?.isAuthenticated == true) {
        fetchUnreadCount();
        // Optionally fetch latest notifications quietly if screen is open
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> fetchNotifications({
    bool refresh = false,
    bool unreadOnly = false,
  }) async {
    if (refresh) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await _notificationService.getNotifications(
        limit: 50,
        unreadOnly: unreadOnly,
      );

      print('[NotificationProvider] Response success: ${response.success}');
      print('[NotificationProvider] Response message: ${response.message}');

      if (response.success && response.data != null) {
        final data = response.data!;
        _notifications = data['notifications'] as List<NotificationModel>;
        _unreadCount = data['unread_count'] as int;
        _error = null;

        print(
          '[NotificationProvider] Loaded ${_notifications.length} notifications',
        );
      } else {
        _error = response.message;
        print('[NotificationProvider] Error: $_error');
        print('[NotificationProvider] Full response: ${response.data}');
      }
    } catch (e) {
      print('[NotificationProvider] Exception: $e');
      _error = 'Terjadi kesalahan: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchUnreadCount() async {
    final response = await _notificationService.getUnreadCount();

    if (response.success && response.data != null) {
      final newCount = response.data!;
      if (newCount != _unreadCount) {
        _unreadCount = newCount;
        notifyListeners();
      }
    }
  }

  Future<bool> markAsRead(int id) async {
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.idNotifikasi == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = (_unreadCount - 1).clamp(0, 999);
      notifyListeners();
    }

    final response = await _notificationService.markAsRead(id);

    if (!response.success) {
      // Revert if failed
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: false);
        _unreadCount++;
        notifyListeners();
      }
      return false;
    }

    return true;
  }

  Future<bool> markAllAsRead() async {
    // Optimistic update
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    _unreadCount = 0;
    notifyListeners();

    final response = await _notificationService.markAllAsRead();

    if (!response.success) {
      fetchNotifications(); // Refresh to source of truth if failed
      return false;
    }

    return true;
  }

  Future<bool> deleteNotification(int id) async {
    // Optimistic update
    final existing = _notifications.firstWhere(
      (n) => n.idNotifikasi == id,
      orElse: () => NotificationModel(
        idNotifikasi: -1,
        nik: '',
        tipe: '',
        judul: '',
        pesan: '',
        createdAt: DateTime.now(),
        isRead: true,
      ),
    );

    _notifications.removeWhere((n) => n.idNotifikasi == id);
    if (!existing.isRead && existing.idNotifikasi != -1) {
      _unreadCount = (_unreadCount - 1).clamp(0, 999);
    }
    notifyListeners();

    final response = await _notificationService.deleteNotification(id);

    if (!response.success) {
      fetchNotifications(); // Refresh if failed
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
