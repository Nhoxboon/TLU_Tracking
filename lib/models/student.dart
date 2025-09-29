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

// Simple student data class for table display
class StudentTableData {
  final int id;
  final String studentCode;
  final String name;
  final String major;
  final String phone;
  final String email;
  final String birthDate;

  StudentTableData({
    required this.id,
    required this.studentCode,
    required this.name,
    required this.major,
    required this.phone,
    required this.email,
    required this.birthDate,
  });

  factory StudentTableData.fromJson(Map<String, dynamic> json) {
    return StudentTableData(
      id: json['id'] ?? 0,
      studentCode: json['studentCode'] ?? '',
      name: json['name'] ?? '',
      major: json['major'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      birthDate: json['birthDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentCode': studentCode,
      'name': name,
      'major': major,
      'phone': phone,
      'email': email,
      'birthDate': birthDate,
    };
  }
}
