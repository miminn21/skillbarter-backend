import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier, WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  final ApiService _apiServiceInstance = ApiService();
  Timer? _heartbeatTimer;

  AuthProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Get token from ApiService
  String? get token => _apiServiceInstance.token;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopHeartbeat();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!isAuthenticated) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // App went to background or closed -> Set Offline
      _stopHeartbeat();
      _authService.updateStatus('offline');
    } else if (state == AppLifecycleState.resumed) {
      // App came to foreground -> Set Online
      _startHeartbeat();
      _authService.updateStatus('online');
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    // Immediate heartbeat
    _authService.heartbeat();
    // Then every 60 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _authService.heartbeat();
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Register new user
  Future<bool> register({
    required String nik,
    required String namaLengkap,
    required String namaPanggilan,
    required String kataSandi,
    required String jenisKelamin,
    required String tanggalLahir,
    required String alamatLengkap,
    required String kota,
    String? bio,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        nik: nik,
        namaLengkap: namaLengkap,
        namaPanggilan: namaPanggilan,
        kataSandi: kataSandi,
        jenisKelamin: jenisKelamin,
        tanggalLahir: tanggalLahir,
        alamatLengkap: alamatLengkap,
        kota: kota,
        bio: bio,
      );

      if (response.success && response.data != null) {
        _user = response.data!.user;
        _startHeartbeat(); // Start heartbeat
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login user
  Future<bool> login({required String nik, required String kataSandi}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(nik: nik, kataSandi: kataSandi);

      if (response.success && response.data != null) {
        _user = response.data!.user;
        _startHeartbeat(); // Start heartbeat
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get user profile
  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.getProfile();

      if (response.success && response.data != null) {
        _user = response.data;
        if (_heartbeatTimer == null)
          _startHeartbeat(); // Ensure heartbeat if profile loaded
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
      // Auto logout if 401
      if (_error!.contains('401') ||
          _error!.toLowerCase().contains('unauthorized')) {
        await logout();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Logout user
  Future<void> logout() async {
    _stopHeartbeat(); // Stop heartbeat
    await _authService.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh user data (alias for loadProfile)
  Future<void> refreshUserData() async {
    await loadProfile();
  }

  /// Try auto-login with stored token
  Future<bool> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    // Token is already loaded by ApiService.initialize()
    if (token == null) {
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      // Try to fetch profile to verify token
      await loadProfile();

      _isLoading = false;
      notifyListeners();

      if (isAuthenticated) {
        _startHeartbeat(); // Start heartbeat
        return true;
      } else {
        // Profile load failed but no exception - clear token
        await logout();
        return false;
      }
    } catch (e) {
      // Any error during auto-login = invalid token
      print('[AutoLogin] Failed: $e');
      await logout(); // Clear invalid token
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
