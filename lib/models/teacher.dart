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

  // Factory constructor to create Teacher from JSON (API response)
  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      teacherId: json['teacher_code'] ?? json['teacherId'] ?? '',
      email: json['email'] ?? '',
      password: '', // Password not included in API response
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      hometown: json['hometown'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : DateTime.now(),
    );
  }

  // Convert Teacher to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_code': teacherId,
      'email': email,
      'full_name': fullName,
      'hometown': hometown,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'user_type': 'teacher',
    };
  }

  @override
  bool authenticate(String username, String password) {
    // In a real app, this would check against a database and use hashing
    return username == email && this.password == password;
  }
}
