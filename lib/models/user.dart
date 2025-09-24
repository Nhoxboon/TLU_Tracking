// Base abstract class for all user types
abstract class User {
  final String id; // Unique identifier (tự động tạo)
  final String username; // For login purposes
  final String password; // Hashed password in real app
  final String email;
  final String fullName;
  DateTime? lastLogin;
  final UserRole role;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
    required this.fullName,
    required this.role,
    this.lastLogin,
  });

  // Method to authenticate user
  bool authenticate(String username, String password);

  // Update last login time
  void updateLastLogin() {
    lastLogin = DateTime.now();
  }

  // Check if user is logged in
  bool get isLoggedIn => lastLogin != null;
}

// Enum to represent the user roles
enum UserRole { admin, teacher, student }
