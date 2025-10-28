import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_models.dart';
import 'mock_api_service.dart';
import 'user_session.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.10.9:8000/api/v1';
  // static const String baseUrl = 'http://10.0.2.2:8000'; //old address

  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP client
  final http.Client _client = http.Client();

  // Common headers
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Login endpoint
  Future<ApiResponse<LoginResponse>> login(LoginRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(data);
        return ApiResponse.success(loginResponse, message: 'Login successful');
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // Fallback to mock data when API is not available
      print('API not available, using mock data: ${e.toString()}');
      return MockApiService.mockLogin(request.email, request.password);
    }
  }

  // Get all students
  Future<ApiResponse<List<Student>>> getStudents() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/students/'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final students = data.map((json) => Student.fromJson(json)).toList();
        return ApiResponse.success(students);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to fetch students',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // Fallback to mock data
      print('API not available, using mock students data: ${e.toString()}');
      return ApiResponse.success(MockApiService.mockStudents);
    }
  }

  // Get student by ID
  Future<ApiResponse<Student>> getStudent(String studentId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/students/$studentId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final student = Student.fromJson(data);
        return ApiResponse.success(student);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Student not found',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // Fallback to mock data
      print('API not available, using mock student data: ${e.toString()}');
      final mockStudent = MockApiService.mockStudents
          .where((s) => s.id == studentId)
          .firstOrNull;
      if (mockStudent != null) {
        return ApiResponse.success(mockStudent);
      }
      return ApiResponse.error('Student not found');
    }
  }

  // Create student
  Future<ApiResponse<Student>> createStudent(Student student) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/students/'),
        headers: _headers,
        body: jsonEncode(student.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final createdStudent = Student.fromJson(data);
        return ApiResponse.success(createdStudent, message: 'Student created successfully');
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
  Future<ApiResponse<Student>> updateStudent(String studentId, Student student) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/students/$studentId'),
        headers: _headers,
        body: jsonEncode(student.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedStudent = Student.fromJson(data);
        return ApiResponse.success(updatedStudent, message: 'Student updated successfully');
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
        Uri.parse('$baseUrl/students/$studentId'),
        headers: _headers,
      );

      if (response.statusCode == 204) {
        return ApiResponse.success(null, message: 'Student deleted successfully');
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

  // Get all teachers
  Future<ApiResponse<List<Teacher>>> getTeachers() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/teachers/'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));

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
      print('API not available, using mock teachers data: ${e.toString()}');
      return ApiResponse.success(MockApiService.mockTeachers);
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
      print('API not available, using mock teacher data: ${e.toString()}');
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
        Uri.parse('$baseUrl/teachers/'),
        headers: _headers,
        body: jsonEncode(teacher.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final createdTeacher = Teacher.fromJson(data);
        return ApiResponse.success(createdTeacher, message: 'Teacher created successfully');
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
  Future<ApiResponse<Teacher>> updateTeacher(String teacherId, Teacher teacher) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/teachers/$teacherId'),
        headers: _headers,
        body: jsonEncode(teacher.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedTeacher = Teacher.fromJson(data);
        return ApiResponse.success(updatedTeacher, message: 'Teacher updated successfully');
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
        Uri.parse('$baseUrl/teachers/$teacherId'),
        headers: _headers,
      );

      if (response.statusCode == 204) {
        return ApiResponse.success(null, message: 'Teacher deleted successfully');
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

  // Get all subjects
  Future<ApiResponse<List<Subject>>> getSubjects() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/subjects/'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));

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
      print('API not available, using mock subjects data: ${e.toString()}');
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
      print('API not available, using mock subject data: ${e.toString()}');
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
        return ApiResponse.success(createdSubject, message: 'Subject created successfully');
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
  Future<ApiResponse<Subject>> updateSubject(String subjectId, Subject subject) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/subjects/$subjectId'),
        headers: _headers,
        body: jsonEncode(subject.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedSubject = Subject.fromJson(data);
        return ApiResponse.success(updatedSubject, message: 'Subject updated successfully');
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
        return ApiResponse.success(null, message: 'Subject deleted successfully');
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

  // Get all teaching sessions
  Future<ApiResponse<List<TeachingSession>>> getTeachingSessions() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/sessions/'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final sessions = data.map((json) => TeachingSession.fromJson(json)).toList();
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
      print('API not available, using mock sessions data: ${e.toString()}');
      return ApiResponse.success(MockApiService.mockTeachingSessions);
    }
  }

  // Get teaching session by ID
  Future<ApiResponse<TeachingSession>> getTeachingSession(String sessionId) async {
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
      print('API not available, using mock session data: ${e.toString()}');
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
  Future<ApiResponse<TeachingSession>> createTeachingSession(Map<String, dynamic> sessionData) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/sessions/'),
        headers: _headers,
        body: jsonEncode(sessionData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final session = TeachingSession.fromJson(data);
        return ApiResponse.success(session, message: 'Teaching session created successfully');
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to create teaching session',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to create teaching session: ${e.toString()}');
    }
  }

  // Update teaching session
  Future<ApiResponse<TeachingSession>> updateTeachingSession(String sessionId, Map<String, dynamic> sessionData) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/sessions/$sessionId'),
        headers: _headers,
        body: jsonEncode(sessionData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final session = TeachingSession.fromJson(data);
        return ApiResponse.success(session, message: 'Teaching session updated successfully');
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to update teaching session',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to update teaching session: ${e.toString()}');
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
        return ApiResponse.success(null, message: 'Teaching session deleted successfully');
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(
          error['detail'] ?? 'Failed to delete teaching session',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to delete teaching session: ${e.toString()}');
    }
  }

  // Cleanup method
  void dispose() {
    _client.close();
  }
}
