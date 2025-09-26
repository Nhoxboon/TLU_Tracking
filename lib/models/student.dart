import 'user.dart';
import '../utils/id_generator.dart';

class Student extends User {
  final String studentId; // Mã sinh viên
  final String hometown;
  final String phoneNumber;
  final DateTime dateOfBirth;

  Student({
    required this.studentId, // Mã sinh viên (khác với id của hệ thống)
    required super.email, // Email is also the username for students
    required super.password,
    required super.fullName,
    required this.hometown,
    required this.phoneNumber,
    required this.dateOfBirth,
  }) : super(
         id: IdGenerator.generateId('student'),
         username: email,
         role: UserRole.student,
       );

  @override
  bool authenticate(String username, String password) {
    // In a real app, this would check against a database and use hashing
    return username == email && this.password == password;
  }
}
