import 'dart:async';
import '../models/user.dart';
import '../models/admin.dart';
import '../models/teacher.dart';
import '../models/student.dart';

/// Dịch vụ quản lý tất cả các loại người dùng (Admin, Teacher, Student)
class UserService {
  // Singleton instance
  static final UserService _instance = UserService._();

  // Private constructor
  UserService._();

  // Getter for the singleton instance
  static UserService get instance => _instance;

  // Mock users for testing - in a real app, these would be fetched from a database
  final List<Teacher> _teachers = [
    Teacher(
      teacherId: 'TCH12345', // Mã giảng viên
      email: 'teacher@thuyloi.edu.vn',
      password: 'password123',
      fullName: 'Nguyễn Văn A',
      hometown: 'Hà Nội',
      phoneNumber: '0123456789',
      dateOfBirth: DateTime(1980, 1, 1),
    ),
  ];

  final List<Student> _students = [
    Student(
      studentId: '2020603789', // Mã sinh viên
      email: 'student@sv.tlu.edu.vn',
      password: 'password123',
      fullName: 'Trần Thị B',
      hometown: 'Hà Nam',
      phoneNumber: '0987654321',
      dateOfBirth: DateTime(2000, 5, 15),
    ),
  ];

  // Current logged-in user
  User? currentUser;

  /// Xác thực người dùng đồng bộ (không đợi)
  bool authenticate(String username, String password, UserRole role) {
    switch (role) {
      case UserRole.admin:
        if (Admin.instance.authenticate(username, password)) {
          currentUser = Admin.instance;
          currentUser!.updateLastLogin();
          return true;
        }
        break;
      case UserRole.teacher:
        try {
          final teacher = _teachers.firstWhere((t) => t.email == username);

          if (teacher.authenticate(username, password)) {
            currentUser = teacher;
            currentUser!.updateLastLogin();
            return true;
          }
        } catch (e) {
          // User not found
          return false;
        }
        break;
      case UserRole.student:
        try {
          final student = _students.firstWhere((s) => s.email == username);

          if (student.authenticate(username, password)) {
            currentUser = student;
            currentUser!.updateLastLogin();
            return true;
          }
        } catch (e) {
          // User not found
          return false;
        }
        break;
    }

    return false;
  }

  /// Xác thực người dùng bất đồng bộ (có mô phỏng độ trễ API)
  Future<bool> authenticateAsync(
    String username,
    String password,
    UserRole role,
  ) async {
    // Mô phỏng độ trễ API
    await Future.delayed(const Duration(milliseconds: 300));
    return authenticate(username, password, role);
  }

  /// Lấy thông tin người dùng hiện tại
  Future<Map<String, dynamic>> getCurrentUserInfo() async {
    // Mô phỏng độ trễ API
    await Future.delayed(const Duration(milliseconds: 300));

    if (currentUser == null) {
      throw Exception('Không có người dùng nào đang đăng nhập');
    }

    // Thông tin cơ bản cho tất cả loại người dùng
    final Map<String, dynamic> userInfo = {
      'id': currentUser!.id,
      'username': currentUser!.username,
      'email': currentUser!.email,
      'fullName': currentUser!.fullName,
      'role': currentUser!.role.toString(),
      'lastLogin': currentUser!.lastLogin?.toIso8601String(),
      'isLoggedIn': currentUser!.isLoggedIn,
    };

    // Thêm thông tin cụ thể cho từng loại người dùng
    if (currentUser is Teacher) {
      final teacher = currentUser as Teacher;
      userInfo['hometown'] = teacher.hometown;
      userInfo['phoneNumber'] = teacher.phoneNumber;
      userInfo['dateOfBirth'] = teacher.dateOfBirth.toIso8601String();
    } else if (currentUser is Student) {
      final student = currentUser as Student;
      userInfo['studentId'] = student.studentId;
      userInfo['hometown'] = student.hometown;
      userInfo['phoneNumber'] = student.phoneNumber;
      userInfo['dateOfBirth'] = student.dateOfBirth.toIso8601String();
    }

    return userInfo;
  }

  /// Cập nhật thời gian đăng nhập cuối cùng của người dùng hiện tại
  Future<void> updateLastLogin() async {
    // Mô phỏng độ trễ API
    await Future.delayed(const Duration(milliseconds: 200));

    if (currentUser != null) {
      currentUser!.updateLastLogin();
    }
  }

  /// Đăng xuất người dùng hiện tại
  void logout() {
    currentUser = null;
  }

  /// Kiểm tra xem có người dùng nào đang đăng nhập hay không
  bool get isLoggedIn => currentUser != null && currentUser!.isLoggedIn;

  /// Lấy vai trò của người dùng hiện tại
  UserRole? get currentUserRole => currentUser?.role;
}
