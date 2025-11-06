// API Models based on OpenAPI specification

// Export models for easier access
export 'student.dart' show StudentModel;
export 'teacher.dart';
export 'subject.dart';
export 'teaching_session.dart';
export 'cohort.dart';

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

class LoginResponse {
  final String accessToken;
  final String tokenType;
  final UserRole role;
  final Map<String, dynamic> user;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.role,
    required this.user,
    required String message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>? ?? {};
    return LoginResponse(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      role: UserRole.fromString(userMap['user_type'] ?? 'student'),
      user: userMap,
      message: '',
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

  factory ApiResponse.success(T data, {String message = 'Thành công'}) {
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

class BaseResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  BaseResponse({required this.success, required this.message, this.data});

  factory BaseResponse.fromJson(Map<String, dynamic> json) => BaseResponse(
    success: json['success'] ?? true,
    message: json['message'] ?? 'Thực hiện thành công',
    data: json['data'] is Map<String, dynamic>
        ? (json['data'] as Map<String, dynamic>)
        : null,
  );
}

class PaginatedResponse {
  final List<Map<String, dynamic>> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedResponse(
      items: (json['items'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['total_pages'] as int,
    );
  }
}

class Faculty {
  final int id;
  final String name;
  final String code;
  final String? createdAt;
  final String? updatedAt;

  Faculty({
    required this.id,
    required this.name,
    required this.code,
    this.createdAt,
    this.updatedAt,
  });

  factory Faculty.fromJson(Map<String, dynamic> json) => Faculty(
    id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
    name: json['name'] ?? '',
    code: json['code'] ?? '',
    createdAt: json['created_at'],
    updatedAt: json['updated_at'],
  );
}

class FacultyPage {
  final List<Faculty> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  FacultyPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory FacultyPage.fromJson(Map<String, dynamic> json) => FacultyPage(
    items: (json['items'] as List<dynamic>? ?? const [])
        .map((e) => Faculty.fromJson(e as Map<String, dynamic>))
        .toList(),
    total: json['total'] ?? 0,
    page: json['page'] ?? 1,
    limit: json['limit'] ?? 10,
    totalPages: json['total_pages'] ?? 1,
  );
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
    return {'id': id, 'name': name, 'code': code, 'credits': credits};
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

class ClassCreate {
  final String name;
  final String code;
  final int? subjectId;
  final int? teacherId;
  final int? facultyId;
  final int? departmentId;
  final int? majorId;
  final int? cohortId;
  final int? academicYearId;
  final int? semesterId;
  final int? studyPhaseId;

  ClassCreate({
    required this.name,
    required this.code,
    this.subjectId,
    this.teacherId,
    this.facultyId,
    this.departmentId,
    this.majorId,
    this.cohortId,
    this.academicYearId,
    this.semesterId,
    this.studyPhaseId,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'subject_id': subjectId,
    'teacher_id': teacherId,
    'faculty_id': facultyId,
    'department_id': departmentId,
    'major_id': majorId,
    'cohort_id': cohortId,
    'academic_year_id': academicYearId,
    'semester_id': semesterId,
    'study_phase_id': studyPhaseId,
  };
}

class ClassItem {
  final int id;
  final String name;
  final String code;
  final int? subjectId;
  final int? teacherId;
  final int? facultyId;
  final int? departmentId;
  final int? majorId;
  final int? cohortId;
  final int? academicYearId;
  final int? semesterId;
  final int? studyPhaseId;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  ClassItem({
    required this.id,
    required this.name,
    required this.code,
    this.subjectId,
    this.teacherId,
    this.facultyId,
    this.departmentId,
    this.majorId,
    this.cohortId,
    this.academicYearId,
    this.semesterId,
    this.studyPhaseId,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory ClassItem.fromJson(Map<String, dynamic> json) => ClassItem(
    id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
    name: json['name'] ?? '',
    code: json['code'] ?? '',
    subjectId: json['subject_id'],
    teacherId: json['teacher_id'],
    facultyId: json['faculty_id'],
    departmentId: json['department_id'],
    majorId: json['major_id'],
    cohortId: json['cohort_id'],
    academicYearId: json['academic_year_id'],
    semesterId: json['semester_id'],
    studyPhaseId: json['study_phase_id'],
    status: json['status'],
    createdAt: json['created_at'],
    updatedAt: json['updated_at'],
  );
}

class ClassPage {
  final List<ClassItem> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  ClassPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory ClassPage.fromJson(Map<String, dynamic> json) => ClassPage(
    items: (json['items'] as List<dynamic>? ?? const [])
        .map((e) => ClassItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    total: json['total'] ?? 0,
    page: json['page'] ?? 1,
    limit: json['limit'] ?? 10,
    totalPages: json['total_pages'] ?? 1,
  );
}
