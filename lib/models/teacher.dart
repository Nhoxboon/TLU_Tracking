import 'user.dart';
import '../utils/id_generator.dart';

class Teacher extends User {
  final String teacherId;
  final String hometown;
  final String phoneNumber;
  final DateTime dateOfBirth;

  Teacher({
    required this.teacherId, // Mã giảng viên (khác với id của hệ thống)
    required super.email, // Email is also the username for teachers
    required super.password,
    required super.fullName,
    required this.hometown,
    required this.phoneNumber,
    required this.dateOfBirth,
  }) : super(
         id: IdGenerator.generateId('teacher'),
         username: email,
         role: UserRole.teacher,
       );

  @override
  bool authenticate(String username, String password) {
    // In a real app, this would check against a database and use hashing
    return username == email && this.password == password;
  }
}
