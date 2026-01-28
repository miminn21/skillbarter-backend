import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/message.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void startAutoRefresh(int transactionId) {
    stopAutoRefresh();
    // Initial fetch
    fetchMessages(transactionId);
    // Poll every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      fetchMessages(transactionId, silent: true);
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }

  Future<void> fetchMessages(int transactionId, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final response = await _api.get('/chat/history/$transactionId');

      if (response.statusCode == 200) {
        final List data = response.data['data'];
        _messages = data.map((json) => Message.fromJson(json)).toList();
        _error = null;
      } else {
        _error = response.data['message'] ?? 'Gagal memuat pesan';
      }
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      } else {
        // Only notify if content changed to avoid unnecessary rebuilds?
        // For simplicity, notifying always on fetch success to keep UI sync
        notifyListeners();
      }
    }
  }

  Future<bool> sendMessage({
    required int transactionId,
    required String receiverNik,
    required String content,
  }) async {
    try {
      final response = await _api.post(
        '/chat/send',
        data: {
          'id_transaksi': transactionId,
          'nik_penerima': receiverNik,
          'isi_pesan': content,
          'tipe': 'teks',
        },
      );

      if (response.statusCode == 201) {
        // Refresh messages immediately
        await fetchMessages(transactionId, silent: true);
        return true;
      } else {
        _error = response.data['message'] ?? 'Gagal mengirim pesan';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Gagal mengirim pesan: $e';
      notifyListeners();
      return false;
    }
  }
}
