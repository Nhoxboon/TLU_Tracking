import '../models/admin.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'auth_manager.dart';

/// Simple utility class for admin-related functions
class AdminUtils {
  // Sử dụng UserService thay vì AdminService
  static final UserService _userService = UserService.instance;

  // Khởi tạo sẵn AuthManager instance để tránh tạo mới nhiều lần
  static final AuthManager _authManager = AuthManager();

  /// Authenticate the admin user (synchronous method for simple UI usage)
  static bool authenticateAdmin(String username, String password) {
    bool result = _authManager.login(username, password);
    print('Auth result for $username: $result');

    // Cập nhật UserService để đảm bảo tính nhất quán
    if (result) {
      _userService.authenticate(username, password, UserRole.admin);
    }

    return result;
  }

  /// Authenticate the admin user asynchronously (for API integration)
  static Future<bool> authenticateAdminAsync(
    String username,
    String password,
  ) async {
    return await _userService.authenticateAsync(
      username,
      password,
      UserRole.admin,
    );
  }

  /// Get the admin's display name
  static String getAdminDisplayName() {
    return Admin.instance.fullName;
  }

  /// Check if admin is logged in
  static bool isAdminLoggedIn() {
    return _authManager.isLoggedIn ||
        (_userService.isLoggedIn &&
            _userService.currentUserRole == UserRole.admin);
  }

  /// Update the last login time
  static void updateAdminLastLogin() {
    Admin.instance.updateLastLogin();
    // Đảm bảo UserService được cập nhật
    if (_userService.currentUser == null ||
        _userService.currentUserRole != UserRole.admin) {
      _userService.currentUser = Admin.instance;
    }
  }

  /// Update the last login time asynchronously (for API integration)
  static Future<void> updateAdminLastLoginAsync() async {
    await _userService.updateLastLogin();
  }

  /// Get admin's email or a default message
  static String getAdminEmail() {
    return Admin.instance.email;
  }

  /// Get all admin information
  static Future<Map<String, dynamic>> getAdminInfo() async {
    // Đảm bảo rằng admin là người dùng hiện tại
    if (_userService.currentUser == null ||
        _userService.currentUserRole != UserRole.admin) {
      _userService.currentUser = Admin.instance;
    }
    return await _userService.getCurrentUserInfo();
  }

  /// Log out the admin user
  static void logoutAdmin() {
    // Sử dụng AuthManager đã được khởi tạo sẵn
    _authManager.logout();

    // Cập nhật UserService
    _userService.logout();

    // Vẫn giữ cách cũ để tương thích
    Admin.instance.lastLogin = null;
    print(
      "Admin logged out: AuthManager, UserService, and Admin.instance updated",
    );
  }
}
