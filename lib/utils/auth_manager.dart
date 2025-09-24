import 'package:flutter/material.dart';
import 'dart:async'; // Thêm vào để sử dụng Timer

// Lớp quản lý trạng thái đăng nhập toàn cục
class AuthManager {
  // Singleton instance
  static final AuthManager _instance = AuthManager._internal();

  // Private constructor
  AuthManager._internal() {
    // Thêm listener để tự động reset trạng thái sau một thời gian dài không hoạt động
    _setupActivityTimeout();
  }

  // Factory constructor để trả về instance
  factory AuthManager() {
    return _instance;
  }

  // Thông tin đăng nhập mẫu
  static const String _adminUsername = 'admin';
  static const String _adminPassword = 'admin123';

  // Trạng thái đăng nhập
  bool _isLoggedIn = false;

  // Timer cho timeout
  Timer? _inactivityTimer;

  // Getter cho trạng thái đăng nhập
  bool get isLoggedIn => _isLoggedIn;

  // Thiết lập timeout để tự động đăng xuất
  void _setupActivityTimeout() {
    // Reset timer bất cứ khi nào có hoạt động
    // Trong trường hợp thực tế, bạn sẽ gọi resetInactivityTimer() từ activity listeners
  }

  // Reset timer khi có hoạt động
  void resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(hours: 1), () {
      // Tự động logout sau 1 giờ không hoạt động
      if (_isLoggedIn) {
        logout();
        debugPrint('Auth Manager: Auto logout due to inactivity');
      }
    });
  }

  // Phương thức đăng nhập với kiểm tra chặt chẽ hơn
  bool login(String username, String password) {
    // Reset trạng thái trước khi thử đăng nhập
    _isLoggedIn = false;

    // Debug logging
    debugPrint('Auth Manager: Login attempt for user: $username');

    // Kiểm tra tính hợp lệ của username/password
    if (username.isEmpty || password.isEmpty) {
      debugPrint('Auth Manager: Empty credentials');
      return false;
    }

    // Kiểm tra thông tin đăng nhập
    bool isValid = (username == _adminUsername && password == _adminPassword);

    if (isValid) {
      _isLoggedIn = true;
      resetInactivityTimer(); // Bắt đầu tính thời gian không hoạt động
      debugPrint('Auth Manager: Login successful');
      return true;
    } else {
      debugPrint('Auth Manager: Login failed - invalid credentials');
      return false;
    }
  }

  // Phương thức đăng xuất
  void logout() {
    _isLoggedIn = false;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    debugPrint('Auth Manager: User logged out');
  }

  // Phương thức kiểm tra đăng nhập
  bool checkLogin() {
    if (_isLoggedIn) {
      resetInactivityTimer(); // Reset timer khi kiểm tra đăng nhập
    }
    return _isLoggedIn;
  }

  // Xử lý khi ứng dụng đóng
  void dispose() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }
}
