import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../models/api_models.dart';
import 'mock_api_service.dart';
import 'user_session.dart';

class ApiService {
  // static const String baseUrl = 'http://192.168.10.2:8000/api/v1';
  // static const String baseUrl = 'http://localhost:8000/api/v1';
  static const String baseUrl = 'http://tlutracking.duckdns.org/api/v1';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP client
  final http.Client _client = http.Client();

  // Common headers
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = UserSession().accessToken;
    final type = UserSession().tokenType ?? 'Bearer';
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = '$type $token';
    }
    return headers;
  }

  // Login endpoint
  Future<ApiResponse<LoginResponse>> login(LoginRequest request) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _headers,
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(data);
        // Persist session
        UserSession().setUser(
          role: loginResponse.role,
          userData: loginResponse.user,
          username: loginResponse.user['email'] ?? '',
          email: loginResponse.user['email'] as String?,
          accessToken: loginResponse.accessToken,
          tokenType: loginResponse.tokenType,
        );
        return ApiResponse.success(
          loginResponse,
          message: 'Đăng nhập thành công',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // Fallback to mock data when API is not available
      return MockApiService.mockLogin(request.email, request.password);
    }
  }

  // Get current user (requires Authorization)
  Future<ApiResponse<Map<String, dynamic>>> getCurrentUser() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/auth/me'), headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // backend may return data directly or wrapped
        final extracted = (data['data'] is Map<String, dynamic>)
            ? (data['data'] as Map<String, dynamic>)
            : data;
        return ApiResponse.success(extracted);
      }
      final error = jsonDecode(response.body);
      return ApiResponse.error(
        error['detail'] ?? 'Failed to fetch current user',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(
        'Lỗi khi lấy thông tin người dùng hiện tại: ${e.toString()}',
      );
    }
  }

  // Get all students (old method - keeping for backward compatibility)
  Future<ApiResponse<List<StudentModel>>> getStudents() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/users/students'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        final students = data
            .map((json) => StudentModel.fromJson(json))
            .toList();
        return ApiResponse.success(students);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch students',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Lỗi khi lấy danh sách sinh viên: ${e.toString()}',
      );
    }
  }

  // Get students with pagination and filters (new method)
  Future<ApiResponse<PaginatedResponse>> getStudentsPaginated({
    int page = 1,
    int limit = 10,
    int? facultyId,
    int? majorId,
    int? cohortId,
    String? className,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (facultyId != null) queryParams['faculty_id'] = facultyId;
      if (majorId != null) queryParams['major_id'] = majorId;
      if (cohortId != null) queryParams['cohort_id'] = cohortId;
      if (className != null && className.isNotEmpty) {
        queryParams['class_name'] = className;
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrl/users/students').replace(
        queryParameters: queryParams.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if response has the expected structure
        if (responseData is Map<String, dynamic>) {
          // Try different possible response structures
          if (responseData.containsKey('data') &&
              responseData['data'] is Map<String, dynamic>) {
            // Structure: { "data": { "items": [...], "total": ..., ... } }
            return ApiResponse.success(
              PaginatedResponse.fromJson(responseData['data']),
            );
          } else if (responseData.containsKey('items') &&
              responseData['items'] is List) {
            // Structure: { "items": [...], "total": ..., ... }
            return ApiResponse.success(
              PaginatedResponse.fromJson(responseData),
            );
          } else {
            // Fallback: treat entire response as paginated data
            // Create a safe structure for PaginatedResponse
            final safeData = {
              'items': responseData['items'] ?? [],
              'total': responseData['total'] ?? 0,
              'page': responseData['page'] ?? page,
              'limit': responseData['limit'] ?? limit,
              'total_pages':
                  responseData['total_pages'] ??
                  responseData['totalPages'] ??
                  ((responseData['total'] ?? 0) / limit).ceil(),
            };
            return ApiResponse.success(PaginatedResponse.fromJson(safeData));
          }
        } else if (responseData is List) {
          // Direct array response - convert to paginated structure
          final itemsList = responseData.cast<Map<String, dynamic>>();
          final safeData = {
            'items': itemsList,
            'total': itemsList.length,
            'page': page,
            'limit': limit,
            'total_pages': (itemsList.length / limit).ceil(),
          };
          return ApiResponse.success(PaginatedResponse.fromJson(safeData));
        } else {
          return ApiResponse.error(
            'Invalid response format from server',
            statusCode: response.statusCode,
          );
        }
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch students',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Lỗi khi lấy danh sách sinh viên: ${e.toString()}',
      );
    }
  }

  // Get student by ID
  Future<ApiResponse<StudentModel>> getStudent(String studentId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/students/$studentId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final student = StudentModel.fromJson(responseData['data']);
        return ApiResponse.success(student);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Student not found',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch student: ${e.toString()}');
    }
  }

  // Get student by code
  Future<ApiResponse<StudentModel>> getStudentByCode(String studentCode) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/students/code/$studentCode'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final student = StudentModel.fromJson(responseData['data']);
        return ApiResponse.success(student);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Student not found',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch student: ${e.toString()}');
    }
  }

  // Create student
  Future<ApiResponse<StudentModel>> createStudent(StudentModel student) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/users/students'),
        headers: _headers,
        body: jsonEncode(student.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return ApiResponse.success(
            student,
            message: responseData['message'] ?? 'Tạo sinh viên thành công',
          );
        } else {
          return ApiResponse.error(
            responseData['message'] ?? 'Lỗi khi tạo sinh viên',
          );
        }
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to create student',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to create student: ${e.toString()}');
    }
  }

  // Create student with Map data (for forms)
  Future<ApiResponse<Map<String, dynamic>>> createStudentData(
    Map<String, dynamic> studentData,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/users/students'),
        headers: _headers,
        body: jsonEncode(studentData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ApiResponse.success(responseData);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to create student',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to create student: ${e.toString()}');
    }
  }

  // Update student
  Future<ApiResponse<StudentModel>> updateStudent(
    String studentId,
    StudentModel student,
  ) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/users/students/$studentId'),
        headers: _headers,
        body: jsonEncode(student.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return ApiResponse.success(
            student,
            message: responseData['message'] ?? 'Cập nhật sinh viên thành công',
          );
        } else {
          return ApiResponse.error(
            responseData['message'] ?? 'Lỗi khi cập nhật sinh viên',
          );
        }
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to update student',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to update student: ${e.toString()}');
    }
  }

  // Update student with Map data (for forms)
  Future<ApiResponse<Map<String, dynamic>>> updateStudentData(
    int studentId,
    Map<String, dynamic> studentData,
  ) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/users/students/$studentId'),
        headers: _headers,
        body: jsonEncode(studentData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ApiResponse.success(responseData);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to update student',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to update student: ${e.toString()}');
    }
  }

  // Delete student
  Future<ApiResponse<void>> deleteStudent(String studentId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/users/students/$studentId'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // For 204 No Content, there's no response body
        if (response.statusCode == 204) {
          return ApiResponse.success(null, message: 'Xóa sinh viên thành công');
        }

        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return ApiResponse.success(
            null,
            message: responseData['message'] ?? 'Xóa sinh viên thành công',
          );
        } else {
          return ApiResponse.error(
            responseData['message'] ?? 'Lỗi khi xóa sinh viên',
          );
        }
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to delete student',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to delete student: ${e.toString()}');
    }
  }

  // Delete student by int ID
  Future<ApiResponse<void>> deleteStudentById(int studentId) async {
    return deleteStudent(studentId.toString());
  }

  // Get all teachers (old method - keeping for backward compatibility)
  Future<ApiResponse<List<Teacher>>> getTeachers() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/teachers/'), headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final teachers = data.map((json) => Teacher.fromJson(json)).toList();
        return ApiResponse.success(teachers);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch teachers',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // Fallback to mock data
      return ApiResponse.success(MockApiService.mockTeachers);
    }
  }

  // Get teachers with pagination and filters (new method)
  Future<ApiResponse<PaginatedResponse>> getTeachersPaginated({
    int page = 1,
    int limit = 10,
    int? facultyId,
    int? departmentId,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (facultyId != null) {
        queryParams['faculty_id'] = facultyId.toString();
      }
      if (departmentId != null) {
        queryParams['department_id'] = departmentId.toString();
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(
        '$baseUrl/users/teachers',
      ).replace(queryParameters: queryParams);

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final paginatedResponse = PaginatedResponse.fromJson(data);
        return ApiResponse.success(paginatedResponse);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch teachers',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch teachers: ${e.toString()}');
    }
  }

  // Get teacher by ID
  Future<ApiResponse<Teacher>> getTeacher(String teacherId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/teachers/$teacherId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final teacher = Teacher.fromJson(data);
        return ApiResponse.success(teacher);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Teacher not found',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // Fallback to mock data
      final mockTeacher = MockApiService.mockTeachers
          .where((t) => t.id == teacherId)
          .firstOrNull;
      if (mockTeacher != null) {
        return ApiResponse.success(mockTeacher);
      }
      return ApiResponse.error('Teacher not found');
    }
  }

  // Create teacher
  Future<ApiResponse<Teacher>> createTeacher(Teacher teacher) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/users/teachers'),
        headers: _headers,
        body: jsonEncode(teacher.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final createdTeacher = Teacher.fromJson(data);
        return ApiResponse.success(
          createdTeacher,
          message: 'Tạo giáo viên thành công',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to create teacher',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to create teacher: ${e.toString()}');
    }
  }

  // Create teacher with Map data (for forms)
  Future<ApiResponse<Map<String, dynamic>>> createTeacherData(
    Map<String, dynamic> teacherData,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/users/teachers'),
        headers: _headers,
        body: jsonEncode(teacherData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to create teacher',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to create teacher: ${e.toString()}');
    }
  }

  // Update teacher
  Future<ApiResponse<Teacher>> updateTeacher(
    String teacherId,
    Teacher teacher,
  ) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/users/teachers/$teacherId'),
        headers: _headers,
        body: jsonEncode(teacher.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedTeacher = Teacher.fromJson(data);
        return ApiResponse.success(
          updatedTeacher,
          message: 'Cập nhật giáo viên thành công',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to update teacher',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to update teacher: ${e.toString()}');
    }
  }

  // Update teacher with Map data (for forms)
  Future<ApiResponse<Map<String, dynamic>>> updateTeacherData(
    int teacherId,
    Map<String, dynamic> teacherData,
  ) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/users/teachers/$teacherId'),
        headers: _headers,
        body: jsonEncode(teacherData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to update teacher',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to update teacher: ${e.toString()}');
    }
  }

  // Delete teacher
  Future<ApiResponse<void>> deleteTeacher(String teacherId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/users/teachers/$teacherId'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(null, message: 'Xóa giáo viên thành công');
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to delete teacher',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to delete teacher: ${e.toString()}');
    }
  }

  // Delete teacher by int ID
  Future<ApiResponse<void>> deleteTeacherById(int teacherId) async {
    return deleteTeacher(teacherId.toString());
  }

  // Get department by ID
  Future<ApiResponse<Map<String, dynamic>>> getDepartment(
    int departmentId,
  ) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/academic/departments/$departmentId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Department not found',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch department: ${e.toString()}');
    }
  }

  // Get all subjects
  Future<ApiResponse<List<Subject>>> getSubjects() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/subjects/'), headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final subjects = data.map((json) => Subject.fromJson(json)).toList();
        return ApiResponse.success(subjects);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch subjects',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // Fallback to mock data
      return ApiResponse.success(MockApiService.mockSubjects);
    }
  }

  // Get subject by ID
  Future<ApiResponse<Subject>> getSubject(String subjectId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/subjects/$subjectId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final subject = Subject.fromJson(data);
        return ApiResponse.success(subject);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Subject not found',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // Fallback to mock data
      final mockSubject = MockApiService.mockSubjects
          .where((s) => s.id == subjectId)
          .firstOrNull;
      if (mockSubject != null) {
        return ApiResponse.success(mockSubject);
      }
      return ApiResponse.error('Subject not found');
    }
  }

  // Create subject
  Future<ApiResponse<Subject>> createSubject(Subject subject) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/subjects/'),
        headers: _headers,
        body: jsonEncode(subject.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final createdSubject = Subject.fromJson(data);
        return ApiResponse.success(
          createdSubject,
          message: 'Tạo môn học thành công',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to create subject',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to create subject: ${e.toString()}');
    }
  }

  // Update subject
  Future<ApiResponse<Subject>> updateSubject(
    String subjectId,
    Subject subject,
  ) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/subjects/$subjectId'),
        headers: _headers,
        body: jsonEncode(subject.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedSubject = Subject.fromJson(data);
        return ApiResponse.success(
          updatedSubject,
          message: 'Cập nhật môn học thành công',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to update subject',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to update subject: ${e.toString()}');
    }
  }

  // Delete subject
  Future<ApiResponse<void>> deleteSubject(String subjectId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/subjects/$subjectId'),
        headers: _headers,
      );

      if (response.statusCode == 204) {
        return ApiResponse.success(null, message: 'Xóa môn học thành công');
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to delete subject',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to delete subject: ${e.toString()}');
    }
  }

  // Create subject with Map data (for forms)
  Future<ApiResponse<Map<String, dynamic>>> createSubjectData(
    Map<String, dynamic> subjectData,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/academic/subjects'),
        headers: _headers,
        body: jsonEncode(subjectData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data, message: 'Tạo môn học thành công');
      } else {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {};
        return ApiResponse.error(
          errorData['detail'] ??
              errorData['message'] ??
              'Failed to create subject (Status: ${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to create subject: ${e.toString()}');
    }
  }

  // Update subject with Map data (for forms)
  Future<ApiResponse<Map<String, dynamic>>> updateSubjectData(
    String subjectId,
    Map<String, dynamic> subjectData,
  ) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/academic/subjects/$subjectId'),
        headers: _headers,
        body: jsonEncode(subjectData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(
          data,
          message: 'Cập nhật môn học thành công',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to update subject',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to update subject: ${e.toString()}');
    }
  }

  // Delete subject by int ID
  Future<ApiResponse<void>> deleteSubjectById(int subjectId) async {
    return deleteSubject(subjectId.toString());
  }

  // Get all teaching sessions
  Future<ApiResponse<List<TeachingSession>>> getTeachingSessions() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/sessions/'), headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final sessions = data
            .map((json) => TeachingSession.fromJson(json))
            .toList();
        return ApiResponse.success(sessions);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch teaching sessions',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // Fallback to mock data
      return ApiResponse.success(MockApiService.mockTeachingSessions);
    }
  }

  // Get teaching session by ID
  Future<ApiResponse<TeachingSession>> getTeachingSession(
    String sessionId,
  ) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/sessions/$sessionId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final session = TeachingSession.fromJson(data);
        return ApiResponse.success(session);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Teaching session not found',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // Fallback to mock data
      final mockSession = MockApiService.mockTeachingSessions
          .where((s) => s.id == sessionId)
          .firstOrNull;
      if (mockSession != null) {
        return ApiResponse.success(mockSession);
      }
      return ApiResponse.error('Teaching session not found');
    }
  }

  // Create teaching session
  Future<ApiResponse<TeachingSession>> createTeachingSession(
    Map<String, dynamic> sessionData,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/sessions/'),
        headers: _headers,
        body: jsonEncode(sessionData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final session = TeachingSession.fromJson(data);
        return ApiResponse.success(session, message: 'Tạo buổi học thành công');
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to create teaching session',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to create teaching session: ${e.toString()}',
      );
    }
  }

  // Update teaching session
  Future<ApiResponse<TeachingSession>> updateTeachingSession(
    String sessionId,
    Map<String, dynamic> sessionData,
  ) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/sessions/$sessionId'),
        headers: _headers,
        body: jsonEncode(sessionData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final session = TeachingSession.fromJson(data);
        return ApiResponse.success(
          session,
          message: 'Cập nhật buổi học thành công',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to update teaching session',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to update teaching session: ${e.toString()}',
      );
    }
  }

  // Delete teaching session
  Future<ApiResponse<void>> deleteTeachingSession(String sessionId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/sessions/$sessionId'),
        headers: _headers,
      );

      if (response.statusCode == 204) {
        return ApiResponse.success(null, message: 'Xóa buổi học thành công');
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to delete teaching session',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to delete teaching session: ${e.toString()}',
      );
    }
  }

  // Password Reset endpoints
  Future<ApiResponse<Map<String, dynamic>>> passwordReset(String email) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/password-reset'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(
          data,
          message: 'Mã OTP đã được gửi thành công',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Không thể gửi email đặt lại mật khẩu',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Lỗi gửi email đặt lại mật khẩu: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> verifyOtp(
    String email,
    String otp,
  ) async {
    try {
      final requestBody = jsonEncode({'email': email, 'token': otp});

      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/verify-otp'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data, message: 'Xác thực OTP thành công');
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Mã OTP không hợp lệ',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Lỗi xác thực OTP: ${e.toString()}');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updatePassword(
    String token,
    String newPassword,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/update-password'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'new_password': newPassword}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(
          data,
          message: 'Mật khẩu đã được cập nhật thành công',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Không thể cập nhật mật khẩu',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Lỗi cập nhật mật khẩu: ${e.toString()}');
    }
  }

  // Get faculties with pagination
  Future<ApiResponse<PaginatedResponse>> getFacultiesPaginated({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      final uri = Uri.parse(
        '$baseUrl/academic/faculties',
      ).replace(queryParameters: queryParams);

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final paginatedResponse = PaginatedResponse(
          items: List<Map<String, dynamic>>.from(data['items']),
          total: data['total'],
          page: data['page'],
          limit: data['limit'],
          totalPages: data['total_pages'],
        );
        return ApiResponse.success(paginatedResponse);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch faculties',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch faculties: ${e.toString()}');
    }
  }

  // Get departments with pagination and optional faculty filter
  Future<ApiResponse<PaginatedResponse>> getDepartmentsPaginated({
    int page = 1,
    int limit = 100,
    int? facultyId,
    String? search,
  }) async {
    try {
      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      if (facultyId != null) {
        queryParams['faculty_id'] = facultyId.toString();
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(
        '$baseUrl/academic/departments',
      ).replace(queryParameters: queryParams);

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final paginatedResponse = PaginatedResponse(
          items: List<Map<String, dynamic>>.from(data['items']),
          total: data['total'],
          page: data['page'],
          limit: data['limit'],
          totalPages: data['total_pages'],
        );
        return ApiResponse.success(paginatedResponse);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch departments',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch departments: ${e.toString()}');
    }
  }

  // Download teacher sample Excel file
  Future<ApiResponse<void>> downloadTeacherSampleExcel() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/users/teachers/sample-excel'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // For web, we'll create a download link
        final bytes = response.bodyBytes;
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement()
          ..href = url
          ..style.display = 'none'
          ..download = 'teacher_sample.xlsx';
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);

        return ApiResponse.success(null);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to download sample file',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to download sample file: ${e.toString()}',
      );
    }
  }

  // Bulk import teachers from Excel file
  Future<ApiResponse<Map<String, dynamic>>> bulkImportTeachers(
    html.File file,
  ) async {
    try {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final bytes = reader.result as List<int>;

      // Create multipart request
      final uri = Uri.parse('$baseUrl/users/teachers/bulk-import');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      final token = UserSession().accessToken;
      final type = UserSession().tokenType ?? 'Bearer';
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = '$type $token';
      }

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: file.name),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Try to decode response safely
        try {
          final data = jsonDecode(response.body);

          // Check if the response contains error information even with 200 status
          if (data is Map<String, dynamic>) {
            // Check for explicit error indicators in the response
            if (data.containsKey('error') ||
                data.containsKey('errors') ||
                (data.containsKey('success') && data['success'] == false)) {
              return ApiResponse.error(
                data['error'] ??
                    data['message'] ??
                    'Import completed with errors',
                statusCode: response.statusCode,
              );
            }

            // Check for partial failures - if there are failed counts but no successful ones
            final successCount =
                data['successful_count'] ?? data['success_count'] ?? 0;
            final failedCount =
                data['failed_count'] ?? data['error_count'] ?? 0;

            if (failedCount > 0 && successCount == 0) {
              return ApiResponse.error(
                'Tất cả giáo viên import thất bại. ${data['message'] ?? 'Vui lòng kiểm tra định dạng dữ liệu và thử lại.'}',
                statusCode: response.statusCode,
              );
            }
          }

          return ApiResponse.success(data);
        } catch (decodeError) {
          // Check if response body contains error keywords even if JSON parsing fails
          final bodyLower = response.body.toLowerCase();
          if (bodyLower.contains('error') ||
              bodyLower.contains('failed') ||
              bodyLower.contains('exception')) {
            return ApiResponse.error(
              'Teacher import failed. Response parsing error: $decodeError',
              statusCode: response.statusCode,
            );
          }

          // If no error keywords found, assume success but with parsing issues
          return ApiResponse.success({
            'message':
                'Teacher import may have completed, but response format was unexpected',
            'status': 'partial_success',
            'raw_response': response.body.length > 500
                ? '${response.body.substring(0, 500)}...'
                : response.body,
          });
        }
      } else {
        // Try to parse error response, fallback if parsing fails
        try {
          final error = jsonDecode(response.body);
          return ApiResponse.error(
            error['detail'] ?? error['message'] ?? 'Failed to import teachers',
            statusCode: response.statusCode,
          );
        } catch (parseError) {
          return ApiResponse.error(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      return ApiResponse.error('Failed to import teachers: ${e.toString()}');
    }
  }

  // Download student sample Excel file
  Future<ApiResponse<void>> downloadStudentSampleExcel() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/students/sample-excel'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        // Create download link
        final bytes = response.bodyBytes;
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = 'student_sample.xlsx';
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);

        return ApiResponse.success(null, message: 'Tải file mẫu thành công');
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to download sample file',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to download sample file: ${e.toString()}',
      );
    }
  }

  // Bulk import students from Excel file
  Future<ApiResponse<Map<String, dynamic>>> bulkImportStudents(
    html.File file,
  ) async {
    try {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final bytes = reader.result as List<int>;

      // Create multipart request
      final uri = Uri.parse('$baseUrl/users/students/bulk-import');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      final token = UserSession().accessToken;
      final type = UserSession().tokenType ?? 'Bearer';
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = '$type $token';
      }

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: file.name),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(responseBody);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to import students',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to import students: ${e.toString()}');
    }
  }

  // Get majors with pagination (for student forms)
  Future<ApiResponse<PaginatedResponse>> getMajorsPaginated({
    int page = 1,
    int limit = 100,
    int? facultyId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (facultyId != null) queryParams['faculty_id'] = facultyId;

      final uri = Uri.parse('$baseUrl/academic/majors').replace(
        queryParameters: queryParams.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if response has the expected structure
        if (responseData is Map<String, dynamic>) {
          // Try different possible response structures
          if (responseData.containsKey('data') &&
              responseData['data'] is Map<String, dynamic>) {
            // Structure: { "data": { "items": [...], "total": ..., ... } }
            return ApiResponse.success(
              PaginatedResponse.fromJson(responseData['data']),
            );
          } else if (responseData.containsKey('items') &&
              responseData['items'] is List) {
            // Structure: { "items": [...], "total": ..., ... }
            return ApiResponse.success(
              PaginatedResponse.fromJson(responseData),
            );
          } else {
            // Fallback: treat entire response as paginated data
            // Create a safe structure for PaginatedResponse
            final safeData = {
              'items': responseData['items'] ?? [],
              'total': responseData['total'] ?? 0,
              'page': responseData['page'] ?? 1,
              'limit': responseData['limit'] ?? limit,
              'total_pages':
                  responseData['total_pages'] ??
                  responseData['totalPages'] ??
                  ((responseData['total'] ?? 0) / limit).ceil(),
            };
            return ApiResponse.success(PaginatedResponse.fromJson(safeData));
          }
        } else if (responseData is List) {
          // Direct array response - convert to paginated structure
          final itemsList = responseData.cast<Map<String, dynamic>>();
          final safeData = {
            'items': itemsList,
            'total': itemsList.length,
            'page': 1,
            'limit': limit,
            'total_pages': (itemsList.length / limit).ceil(),
          };
          return ApiResponse.success(PaginatedResponse.fromJson(safeData));
        } else {
          return ApiResponse.error(
            'Invalid response format from server',
            statusCode: response.statusCode,
          );
        }
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch majors',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch majors: ${e.toString()}');
    }
  }

  // Get cohorts with pagination (for student forms)
  Future<ApiResponse<PaginatedResponse>> getCohortsPaginated({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      final uri = Uri.parse('$baseUrl/academic/cohorts').replace(
        queryParameters: queryParams.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if response has the expected structure
        if (responseData is Map<String, dynamic>) {
          // Try different possible response structures
          if (responseData.containsKey('data') &&
              responseData['data'] is Map<String, dynamic>) {
            // Structure: { "data": { "items": [...], "total": ..., ... } }
            return ApiResponse.success(
              PaginatedResponse.fromJson(responseData['data']),
            );
          } else if (responseData.containsKey('items') &&
              responseData['items'] is List) {
            // Structure: { "items": [...], "total": ..., ... }
            return ApiResponse.success(
              PaginatedResponse.fromJson(responseData),
            );
          } else {
            // Fallback: treat entire response as paginated data
            // Create a safe structure for PaginatedResponse
            final safeData = {
              'items': responseData['items'] ?? [],
              'total': responseData['total'] ?? 0,
              'page': responseData['page'] ?? 1,
              'limit': responseData['limit'] ?? limit,
              'total_pages':
                  responseData['total_pages'] ??
                  responseData['totalPages'] ??
                  ((responseData['total'] ?? 0) / limit).ceil(),
            };
            return ApiResponse.success(PaginatedResponse.fromJson(safeData));
          }
        } else if (responseData is List) {
          // Direct array response - convert to paginated structure
          final itemsList = responseData.cast<Map<String, dynamic>>();
          final safeData = {
            'items': itemsList,
            'total': itemsList.length,
            'page': 1,
            'limit': limit,
            'total_pages': (itemsList.length / limit).ceil(),
          };
          return ApiResponse.success(PaginatedResponse.fromJson(safeData));
        } else {
          return ApiResponse.error(
            'Invalid response format from server',
            statusCode: response.statusCode,
          );
        }
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch cohorts',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch cohorts: ${e.toString()}');
    }
  }

  // Get major by ID
  Future<ApiResponse<Map<String, dynamic>>> getMajor(int majorId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/academic/majors/$majorId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch major',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch major: ${e.toString()}');
    }
  }

  // Create major with Map data (for forms)
  Future<ApiResponse<Map<String, dynamic>>> createMajorData(
    Map<String, dynamic> majorData,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/academic/majors'),
            headers: _headers,
            body: jsonEncode(majorData),
          )
          .timeout(const Duration(seconds: 10));

      // Chấp nhận cả 200 và 201 cho success
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return ApiResponse.success(data);
        } catch (e) {
          // Nếu không parse được JSON, nhưng status code thành công thì vẫn coi là success
          return ApiResponse.success({'message': 'Tạo ngành học thành công'});
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          return ApiResponse.error(
            error['detail'] ?? 'Failed to create major',
            statusCode: response.statusCode,
          );
        } catch (e) {
          return ApiResponse.error(
            'Failed to create major - Status: ${response.statusCode}',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      return ApiResponse.error('Failed to create major: ${e.toString()}');
    }
  }

  // Update major with Map data (for forms)
  Future<ApiResponse<Map<String, dynamic>>> updateMajorData(
    int majorId,
    Map<String, dynamic> majorData,
  ) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/academic/majors/$majorId'),
            headers: _headers,
            body: jsonEncode(majorData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to update major',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to update major: ${e.toString()}');
    }
  }

  // Delete major by int ID
  Future<ApiResponse<void>> deleteMajorById(int majorId) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/academic/majors/$majorId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(null);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to delete major',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to delete major: ${e.toString()}');
    }
  }

  // Get faculty by ID
  Future<ApiResponse<Map<String, dynamic>>> getFaculty(int facultyId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/academic/faculties/$facultyId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch faculty',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch faculty: ${e.toString()}');
    }
  }

  // Create faculty
  Future<ApiResponse<Map<String, dynamic>>> createFacultyData(
    Map<String, dynamic> facultyData,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/academic/faculties'),
        headers: _headers,
        body: jsonEncode(facultyData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ??
              'Failed to create faculty (Status: ${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to create faculty: ${e.toString()}');
    }
  }

  // Update faculty
  Future<ApiResponse<Map<String, dynamic>>> updateFacultyData(
    int facultyId,
    Map<String, dynamic> facultyData,
  ) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/academic/faculties/$facultyId'),
        headers: _headers,
        body: jsonEncode(facultyData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to update faculty',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to update faculty: ${e.toString()}');
    }
  }

  // Delete faculty by ID
  Future<ApiResponse<void>> deleteFacultyById(int facultyId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/academic/faculties/$facultyId'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(null);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to delete faculty',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to delete faculty: ${e.toString()}');
    }
  }

  // Get cohort by ID
  Future<ApiResponse<Map<String, dynamic>>> getCohort(int cohortId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/academic/cohorts/$cohortId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch cohort',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch cohort: ${e.toString()}');
    }
  }

  // Get classes with pagination and filters
  Future<ApiResponse<PaginatedResponse>> getClassesPaginated({
    int page = 1,
    int limit = 10,
    int? teacherId,
    int? subjectId,
    int? semesterId,
    int? facultyId,
    int? departmentId,
    int? majorId,
    int? cohortId,
    int? academicYearId,
    int? studyPhaseId,
    bool? activeOnly,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (teacherId != null) queryParams['teacher_id'] = teacherId.toString();
      if (subjectId != null) queryParams['subject_id'] = subjectId.toString();
      if (semesterId != null) {
        queryParams['semester_id'] = semesterId.toString();
      }
      if (facultyId != null) queryParams['faculty_id'] = facultyId.toString();
      if (departmentId != null) {
        queryParams['department_id'] = departmentId.toString();
      }
      if (majorId != null) queryParams['major_id'] = majorId.toString();
      if (cohortId != null) queryParams['cohort_id'] = cohortId.toString();
      if (academicYearId != null) {
        queryParams['academic_year_id'] = academicYearId.toString();
      }
      if (studyPhaseId != null) {
        queryParams['study_phase_id'] = studyPhaseId.toString();
      }
      if (activeOnly != null) {
        queryParams['active_only'] = activeOnly.toString();
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse(
        '$baseUrl/classes',
      ).replace(queryParameters: queryParams);

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final paginatedResponse = PaginatedResponse.fromJson(data);
        return ApiResponse.success(paginatedResponse);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch classes',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch classes: ${e.toString()}');
    }
  }

  // Get class by ID
  Future<ApiResponse<Map<String, dynamic>>> getClass(int classId) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/classes/$classId'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch class',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch class: ${e.toString()}');
    }
  }

  // Get subject by ID
  Future<ApiResponse<Map<String, dynamic>>> getSubjectById(
    int subjectId,
  ) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/academic/subjects/$subjectId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch subject',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch subject: ${e.toString()}');
    }
  }

  // Get teacher by ID
  Future<ApiResponse<Map<String, dynamic>>> getTeacherById(
    int teacherId,
  ) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/users/teachers/$teacherId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch teacher',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch teacher: ${e.toString()}');
    }
  }

  // Delete class by ID
  Future<ApiResponse<void>> deleteClass(int classId) async {
    try {
      final response = await _client
          .delete(Uri.parse('$baseUrl/classes/$classId'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(null);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to delete class',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to delete class: ${e.toString()}');
    }
  }

  // Create class with Map data (for forms)
  Future<ApiResponse<Map<String, dynamic>>> createClassData(
    Map<String, dynamic> classData,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/classes'),
            headers: _headers,
            body: jsonEncode(classData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(responseData);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to create class',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to create class: ${e.toString()}');
    }
  }

  // Update class with Map data (for forms)
  Future<ApiResponse<Map<String, dynamic>>> updateClassData(
    int classId,
    Map<String, dynamic> classData,
  ) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/classes/$classId'),
            headers: _headers,
            body: jsonEncode(classData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(responseData);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to update class',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to update class: ${e.toString()}');
    }
  }

  // Get subjects with pagination and optional filters
  Future<ApiResponse<PaginatedResponse>> getSubjectsPaginated({
    int page = 1,
    int limit = 100,
    int? departmentId,
    int? facultyId,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (departmentId != null) {
        queryParams['department_id'] = departmentId.toString();
      }
      if (facultyId != null) queryParams['faculty_id'] = facultyId.toString();

      final uri = Uri.parse(
        '$baseUrl/academic/subjects',
      ).replace(queryParameters: queryParams);

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final paginatedResponse = PaginatedResponse.fromJson(data);
        return ApiResponse.success(paginatedResponse);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch subjects',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch subjects: ${e.toString()}');
    }
  }

  // Get study phases with pagination and optional filters
  Future<ApiResponse<PaginatedResponse>> getStudyPhasesPaginated({
    int page = 1,
    int limit = 100,
    int? semesterId,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (semesterId != null) {
        queryParams['semester_id'] = semesterId.toString();
      }

      final uri = Uri.parse(
        '$baseUrl/academic/study-phases',
      ).replace(queryParameters: queryParams);

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final paginatedResponse = PaginatedResponse.fromJson(data);
        return ApiResponse.success(paginatedResponse);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch study phases',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch study phases: ${e.toString()}');
    }
  }

  // Get a study phase by ID
  Future<ApiResponse<Map<String, dynamic>>> getStudyPhase(
    int studyPhaseId,
  ) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/academic/study-phases/$studyPhaseId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch study phase',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch study phase: ${e.toString()}');
    }
  }

  // Create a study phase
  Future<ApiResponse<Map<String, dynamic>>> createStudyPhase(
    Map<String, dynamic> studyPhaseData,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/academic/study-phases'),
            headers: _headers,
            body: jsonEncode(studyPhaseData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to create study phase',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to create study phase: ${e.toString()}');
    }
  }

  // Update a study phase
  Future<ApiResponse<Map<String, dynamic>>> updateStudyPhase(
    int studyPhaseId,
    Map<String, dynamic> studyPhaseData,
  ) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/academic/study-phases/$studyPhaseId'),
            headers: _headers,
            body: jsonEncode(studyPhaseData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to update study phase',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to update study phase: ${e.toString()}');
    }
  }

  // Delete a study phase
  Future<ApiResponse<void>> deleteStudyPhase(int studyPhaseId) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/academic/study-phases/$studyPhaseId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ApiResponse.success(null);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to delete study phase',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to delete study phase: ${e.toString()}');
    }
  }

  // Get semesters with pagination and optional filters
  Future<ApiResponse<PaginatedResponse>> getSemestersPaginated({
    int page = 1,
    int limit = 100,
    int? academicYearId,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (academicYearId != null) {
        queryParams['academic_year_id'] = academicYearId.toString();
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse(
        '$baseUrl/academic/semesters',
      ).replace(queryParameters: queryParams);

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final paginatedResponse = PaginatedResponse.fromJson(data);
        return ApiResponse.success(paginatedResponse);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch semesters',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch semesters: ${e.toString()}');
    }
  }

  // ==================== SEMESTER ENDPOINTS ====================

  // Get a semester by ID
  Future<ApiResponse<Map<String, dynamic>>> getSemester(int semesterId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/academic/semesters/$semesterId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch semester',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch semester: ${e.toString()}');
    }
  }

  // Create a semester
  Future<ApiResponse<Map<String, dynamic>>> createSemester(
    Map<String, dynamic> semesterData,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/academic/semesters'),
            headers: _headers,
            body: jsonEncode(semesterData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to create semester',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to create semester: ${e.toString()}');
    }
  }

  // Update a semester
  Future<ApiResponse<Map<String, dynamic>>> updateSemester(
    int semesterId,
    Map<String, dynamic> semesterData,
  ) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/academic/semesters/$semesterId'),
            headers: _headers,
            body: jsonEncode(semesterData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to update semester',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to update semester: ${e.toString()}');
    }
  }

  // Delete a semester
  Future<ApiResponse<void>> deleteSemester(int semesterId) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/academic/semesters/$semesterId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ApiResponse.success(null);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to delete semester',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to delete semester: ${e.toString()}');
    }
  }

  // Get academic years with pagination
  Future<ApiResponse<PaginatedResponse>> getAcademicYearsPaginated({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/academic/academic-years',
      ).replace(queryParameters: queryParams);

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final paginatedResponse = PaginatedResponse.fromJson(data);
        return ApiResponse.success(paginatedResponse);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch academic years',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to fetch academic years: ${e.toString()}',
      );
    }
  }

  // Get students in a class
  Future<ApiResponse<List<Map<String, dynamic>>>> getClassStudents(
    int classId, {
    bool activeOnly = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (!activeOnly) {
        queryParams['active_only'] = false;
      }

      final uri = Uri.parse('$baseUrl/classes/$classId/students').replace(
        queryParameters: queryParams.isNotEmpty
            ? queryParams.map((key, value) => MapEntry(key, value.toString()))
            : null,
      );

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Map<String, dynamic>> students = data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        return ApiResponse.success(students);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch class students',
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to fetch class students: ${e.toString()}',
      );
    }
  }

  // Remove student from class
  Future<ApiResponse<void>> removeStudentFromClass(
    int classId,
    int studentId,
  ) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/classes/$classId/students/$studentId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(
          null,
          message: 'Xóa sinh viên khỏi lớp thành công',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to remove student from class',
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to remove student from class: ${e.toString()}',
      );
    }
  }

  // Add student to class
  Future<ApiResponse<Map<String, dynamic>>> addStudentToClass(
    int classId,
    int studentId,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/classes/$classId/students'),
        headers: _headers,
        body: jsonEncode({'student_id': studentId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(
          data,
          message: 'Thêm sinh viên vào lớp thành công',
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to add student to class',
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to add student to class: ${e.toString()}',
      );
    }
  }

  // ==================== ACADEMIC YEAR ENDPOINTS ====================

  // Get academic year by ID
  Future<ApiResponse<Map<String, dynamic>>> getAcademicYear(
    int academicYearId,
  ) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/academic/academic-years/$academicYearId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final error = json.decode(response.body);
        return ApiResponse.error(
          error['detail'] ??
              'Failed to get academic year: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Create academic year with Map data
  Future<ApiResponse<Map<String, dynamic>>> createAcademicYear(
    Map<String, dynamic> academicYearData,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/academic/academic-years'),
            headers: _headers,
            body: json.encode(academicYearData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final error = json.decode(response.body);
        return ApiResponse.error(
          error['detail'] ??
              'Failed to create academic year: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Update academic year with Map data
  Future<ApiResponse<Map<String, dynamic>>> updateAcademicYear(
    int academicYearId,
    Map<String, dynamic> academicYearData,
  ) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/academic/academic-years/$academicYearId'),
            headers: _headers,
            body: json.encode(academicYearData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final error = json.decode(response.body);
        return ApiResponse.error(
          error['detail'] ??
              'Failed to update academic year: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Delete academic year by ID
  Future<ApiResponse<void>> deleteAcademicYear(int academicYearId) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/academic/academic-years/$academicYearId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ApiResponse.success(null);
      } else {
        final error = json.decode(response.body);
        return ApiResponse.error(
          error['detail'] ??
              'Failed to delete academic year: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Delete multiple academic years by IDs
  Future<ApiResponse<void>> deleteAcademicYears(
    List<int> academicYearIds,
  ) async {
    try {
      final List<Future<ApiResponse<void>>> futures = academicYearIds
          .map((id) => deleteAcademicYear(id))
          .toList();

      final results = await Future.wait(futures);

      // Check if all deletions were successful
      final failedDeletions = results
          .where((result) => !result.success)
          .toList();

      if (failedDeletions.isEmpty) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error('Some academic years could not be deleted');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // ===================== COHORT MANAGEMENT METHODS =====================

  // Create cohort with Map data
  Future<ApiResponse<Map<String, dynamic>>> createCohort(
    Map<String, dynamic> cohortData,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/academic/cohorts'),
            headers: _headers,
            body: json.encode(cohortData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final error = json.decode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to create cohort: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Update cohort with Map data
  Future<ApiResponse<Map<String, dynamic>>> updateCohort(
    int cohortId,
    Map<String, dynamic> cohortData,
  ) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/academic/cohorts/$cohortId'),
            headers: _headers,
            body: json.encode(cohortData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final error = json.decode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to update cohort: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Delete cohort by ID
  Future<ApiResponse<void>> deleteCohort(int cohortId) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/academic/cohorts/$cohortId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ApiResponse.success(null);
      } else {
        final error = json.decode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to delete cohort: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Delete multiple cohorts by IDs
  Future<ApiResponse<void>> deleteCohorts(List<int> cohortIds) async {
    try {
      final List<Future<ApiResponse<void>>> futures = cohortIds
          .map((id) => deleteCohort(id))
          .toList();

      final results = await Future.wait(futures);

      // Check if all deletions were successful
      final failedDeletions = results
          .where((result) => !result.success)
          .toList();

      if (failedDeletions.isEmpty) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error('Some cohorts could not be deleted');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Create department with Map data (for forms)
  Future<ApiResponse<Map<String, dynamic>>> createDepartmentData(
    Map<String, dynamic> departmentData,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/academic/departments'),
            headers: _headers,
            body: jsonEncode(departmentData),
          )
          .timeout(const Duration(seconds: 10));

      // Accept both 200 and 201 for success
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return ApiResponse.success(data);
        } catch (e) {
          return ApiResponse.success(<String, dynamic>{
            'message': 'Tạo khoa thành công',
          });
        }
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to create department',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to create department: ${e.toString()}');
    }
  }

  // Update department with Map data (for forms)
  Future<ApiResponse<Map<String, dynamic>>> updateDepartmentData(
    int departmentId,
    Map<String, dynamic> departmentData,
  ) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/academic/departments/$departmentId'),
            headers: _headers,
            body: jsonEncode(departmentData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return ApiResponse.success(data);
        } catch (e) {
          return ApiResponse.success(<String, dynamic>{
            'message': 'Cập nhật khoa thành công',
          });
        }
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to update department',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to update department: ${e.toString()}');
    }
  }

  // Delete department by ID
  Future<ApiResponse<void>> deleteDepartment(int departmentId) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/academic/departments/$departmentId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ApiResponse.success(null);
      } else {
        final error = json.decode(response.body);
        return ApiResponse.error(
          error['detail'] ??
              'Failed to delete department: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Delete multiple departments by IDs
  Future<ApiResponse<void>> deleteDepartments(List<int> departmentIds) async {
    try {
      final List<Future<ApiResponse<void>>> futures = departmentIds
          .map((id) => deleteDepartment(id))
          .toList();

      final results = await Future.wait(futures);

      // Check if all deletions were successful
      final failedDeletions = results
          .where((result) => !result.success)
          .toList();

      if (failedDeletions.isEmpty) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error('Some departments could not be deleted');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Cleanup method
  void dispose() {
    _client.close();
  }
}
