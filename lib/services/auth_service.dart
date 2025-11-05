// lib/services/auth_service.dart
import 'api_service.dart';
import '../models/api_models.dart';
import 'user_session.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  bool _isAuthenticated = false;
  String? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUser => _currentUser;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Gọi API login
      final loginRequest = LoginRequest(email: email, password: password);
      final loginResponse = await _apiService.login(loginRequest);

      if (!loginResponse.success || loginResponse.data == null) {
        return {'success': false, 'message': loginResponse.message};
      }

      // Lưu token vào session
      final loginData = loginResponse.data!;
      UserSession().setUser(
        role: loginData.role,
        userData: loginData.user,
        username: loginData.user['email'] ?? email,
        email: loginData.user['email'] as String? ?? email,
        accessToken: loginData.accessToken,
        tokenType: loginData.tokenType,
      );

      // Gọi API /auth/me để lấy thông tin chi tiết user
      final userResponse = await _apiService.getCurrentUser();

      if (!userResponse.success || userResponse.data == null) {
        return {
          'success': false,
          'message': 'Không thể lấy thông tin người dùng',
        };
      }

      final userData = userResponse.data!;
      final userType = userData['user_type'] as String?;

      // Kiểm tra user_type
      if (userType != 'admin') {
        // Không phải admin, logout và thông báo lỗi
        logout();
        return {
          'success': false,
          'message': 'Bạn không có quyền truy cập vào hệ thống admin',
        };
      }

      // Đăng nhập thành công với user_type là admin
      _isAuthenticated = true;
      _currentUser = email;

      return {
        'success': true,
        'message': 'Đăng nhập thành công',
        'user_type': userType,
        'user_data': userData,
      };
    } catch (e) {
      return {'success': false, 'message': 'Có lỗi xảy ra: ${e.toString()}'};
    }
  }

  void logout() {
    _isAuthenticated = false;
    _currentUser = null;
    UserSession().logout();
  }

  // Reset password methods (mock implementation - cần thay bằng API thật)
  Future<Map<String, dynamic>> sendResetCode(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Implement real API call
    return {
      'success': true,
      'message': 'Mã xác minh đã được gửi đến email của bạn',
    };
  }

  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Implement real API call
    // Mock verification - mã đúng là "123456"
    if (code == "123456") {
      return {'success': true, 'message': 'Xác minh thành công'};
    } else {
      return {'success': false, 'message': 'Mã xác minh không đúng'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String newPassword,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Implement real API call
    return {'success': true, 'message': 'Mật khẩu đã được cập nhật thành công'};
  }
}
