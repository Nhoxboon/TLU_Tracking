// API Models based on OpenAPI specification

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class LoginResponse {
  final String message;
  final UserRole role;
  final Map<String, dynamic> user;

  LoginResponse({
    required this.message,
    required this.role,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] ?? '',
      role: UserRole.fromString(json['user_type'] ?? 'student'),
      user: json['user'] ?? {},
    );
  }
}

enum UserRole {
  admin,
  teacher,
  student;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'teacher':
        return UserRole.teacher;
      case 'student':
      case 'studennt': // Handle backend typo
        return UserRole.student;
      default:
        return UserRole.student;
    }
  }

  String toJson() {
    return name;
  }
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {String message = 'Success'}) {
    return ApiResponse(
      success: true,
      message: message,
      data: data,
      statusCode: 200,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

class Student {
  final String id;
  final String studentId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? address;

  Student({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.address,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
    };
  }
}

class Teacher {
  final String id;
  final String teacherId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? department;

  Teacher({
    required this.id,
    required this.teacherId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.department,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id']?.toString() ?? '',
      teacherId: json['teacher_id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      department: json['department'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'department': department,
    };
  }
}

class Admin {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;

  Admin({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
    };
  }
}

class Subject {
  final String id;
  final String name;
  final String code;
  final int credits;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.credits,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      credits: json['credits'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'credits': credits,
    };
  }
}

class TeachingSession {
  final String id;
  final String subjectId;
  final String teacherId;
  final String classCode;
  final DateTime startTime;
  final DateTime endTime;
  final String location;

  TeachingSession({
    required this.id,
    required this.subjectId,
    required this.teacherId,
    required this.classCode,
    required this.startTime,
    required this.endTime,
    required this.location,
  });

  factory TeachingSession.fromJson(Map<String, dynamic> json) {
    return TeachingSession(
      id: json['id']?.toString() ?? '',
      subjectId: json['subject_id']?.toString() ?? '',
      teacherId: json['teacher_id']?.toString() ?? '',
      classCode: json['class_code'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      location: json['location'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'teacher_id': teacherId,
      'class_code': classCode,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
    };
  }
}
