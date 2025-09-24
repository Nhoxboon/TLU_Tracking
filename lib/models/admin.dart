import 'user.dart';
import '../utils/id_generator.dart';

class Admin extends User {
  // Private constructor for singleton pattern
  Admin._({
    required super.username,
    required super.password,
    required super.email,
    required super.fullName,
  }) : super(id: IdGenerator.generateId('admin'), role: UserRole.admin);

  // Singleton instance
  static final Admin _instance = Admin._(
    username: 'admin',
    password: 'admin123', // In a real app, this would be hashed
    email: 'admin@thuyloi.edu.vn',
    fullName: 'Quản trị viên',
  );

  // Getter for the singleton instance
  static Admin get instance => _instance;

  // Method to authenticate admin
  @override
  bool authenticate(String username, String password) {
    // So sánh với giá trị hardcoded thay vì giá trị singleton
    return username == 'admin' && password == 'admin123';
  }
}
