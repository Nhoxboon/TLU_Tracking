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

// Student model for API operations
class StudentModel {
  final int? id;
  final int? facultyId;
  final int? majorId;
  final int? cohortId;
  final String className;
  final String studentCode;
  final String fullName;
  final String? phone;
  final String? birthDate;
  final String? hometown;
  final String? email;
  final String? authId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // For API operations, store the original API ID
  final int? apiId;

  StudentModel({
    this.id,
    this.facultyId,
    this.majorId,
    this.cohortId,
    required this.className,
    required this.studentCode,
    required this.fullName,
    this.phone,
    this.birthDate,
    this.hometown,
    this.email,
    this.authId,
    this.createdAt,
    this.updatedAt,
    this.apiId,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'],
      facultyId: json['faculty_id'],
      majorId: json['major_id'],
      cohortId: json['cohort_id'],
      className: json['class_name'] ?? '',
      studentCode: json['student_code'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'],
      birthDate: json['birth_date'],
      hometown: json['hometown'],
      email: json['email'],
      authId: json['auth_id'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      apiId: json['id'], // Store original API ID for operations
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'faculty_id': facultyId,
      'major_id': majorId,
      'cohort_id': cohortId,
      'class_name': className,
      'student_code': studentCode,
      'full_name': fullName,
      'phone': phone,
      'birth_date': birthDate,
      'hometown': hometown,
      'email': email,
    };
  }

  // Create method for API creation (includes password)
  Map<String, dynamic> toCreateJson({required String password, String? email}) {
    return {
      'faculty_id': facultyId,
      'major_id': majorId,
      'cohort_id': cohortId,
      'class_name': className,
      'student_code': studentCode,
      'full_name': fullName,
      'phone': phone,
      'birth_date': birthDate,
      'hometown': hometown,
      'email': email ?? this.email,
      'password': password,
    };
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
