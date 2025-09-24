// lib/services/auth_service.dart
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isAuthenticated = false;
  String? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUser => _currentUser;

  // Mock credentials - trong thực tế sẽ call API
  final Map<String, String> _validCredentials = {
    'admin@tlu.edu.vn': 'admin123',
    'esteban_schiller@gmail.com': 'password123',
    'admin': 'admin123', // Thêm credential cũ để tương thích
  };

  Future<Map<String, dynamic>> login(String username, String password) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (_validCredentials.containsKey(username) &&
        _validCredentials[username] == password) {
      _isAuthenticated = true;
      _currentUser = username;
      return {'success': true, 'message': 'Đăng nhập thành công'};
    } else {
      return {
        'success': false,
        'message': 'Tên đăng nhập hoặc mật khẩu không đúng',
      };
    }
  }

  void logout() {
    _isAuthenticated = false;
    _currentUser = null;
  }

  // Reset password methods
  Future<Map<String, dynamic>> sendResetCode(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_validCredentials.containsKey(email)) {
      return {
        'success': true,
        'message': 'Mã xác minh đã được gửi đến email của bạn',
      };
    } else {
      return {
        'success': false,
        'message': 'Email không tồn tại trong hệ thống',
      };
    }
  }

  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    await Future.delayed(const Duration(milliseconds: 500));

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

    if (_validCredentials.containsKey(email)) {
      _validCredentials[email] = newPassword;
      return {
        'success': true,
        'message': 'Mật khẩu đã được cập nhật thành công',
      };
    } else {
      return {'success': false, 'message': 'Có lỗi xảy ra, vui lòng thử lại'};
    }
  }
}
