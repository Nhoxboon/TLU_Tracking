import '../models/api_models.dart';

class MockApiService {
  // Mock login responses for different users
  static final Map<String, Map<String, dynamic>> mockUsers = {
    'admin@tlu.edu.vn': {
      'user_type': 'admin',
      'user': {
        'id': '1',
        'full_name': 'Admin TLU',
        'email': 'admin@tlu.edu.vn',
        'phone_number': '0123456789',
      }
    },
    'teacher@tlu.edu.vn': {
      'user_type': 'teacher',
      'user': {
        'id': '1',
        'teacher_id': 'GV001',
        'full_name': 'Nguyễn Văn Giảng',
        'email': 'teacher@tlu.edu.vn',
        'phone_number': '0987654321',
        'department': 'Công nghệ thông tin',
      }
    },
    'student@tlu.edu.vn': {
      'user_type': 'student',
      'user': {
        'id': '1',
        'student_id': 'SV001',
        'full_name': 'Nguyễn Văn Sinh Viên',
        'email': 'student@tlu.edu.vn',
        'phone_number': '0123987456',
        'address': 'Hà Nội',
      }
    },
  };

  static ApiResponse<LoginResponse> mockLogin(String email, String password) {
    // Simple mock validation
    if (password != '123456') {
      return ApiResponse.error('Mật khẩu không đúng');
    }

    final userData = mockUsers[email];
    if (userData == null) {
      return ApiResponse.error('Tài khoản không tồn tại');
    }

    final loginResponse = LoginResponse(
      message: 'Đăng nhập thành công',
      role: UserRole.fromString(userData['user_type']),
      user: userData['user'],
    );

    return ApiResponse.success(loginResponse);
  }

  static List<Student> mockStudents = [
    Student(
      id: '1',
      studentId: 'SV001',
      fullName: 'Nguyễn Văn A',
      email: 'svA@tlu.edu.vn',
      phoneNumber: '0123456789',
      address: 'Hà Nội',
    ),
    Student(
      id: '2',
      studentId: 'SV002',
      fullName: 'Trần Thị B',
      email: 'svB@tlu.edu.vn',
      phoneNumber: '0987654321',
      address: 'Hải Dương',
    ),
    Student(
      id: '3',
      studentId: 'SV003',
      fullName: 'Lê Văn C',
      email: 'svC@tlu.edu.vn',
      phoneNumber: '0456789123',
      address: 'Hà Nam',
    ),
  ];

  static List<Teacher> mockTeachers = [
    Teacher(
      id: '1',
      teacherId: 'GV001',
      fullName: 'PGS.TS Nguyễn Văn Giảng',
      email: 'gvA@tlu.edu.vn',
      phoneNumber: '0123456789',
      department: 'Công nghệ thông tin',
    ),
    Teacher(
      id: '2',
      teacherId: 'GV002',
      fullName: 'TS. Trần Thị Dạy',
      email: 'gvB@tlu.edu.vn',
      phoneNumber: '0987654321',
      department: 'Khoa học máy tính',
    ),
  ];

  static List<Subject> mockSubjects = [
    Subject(
      id: '1',
      name: 'Lập trình di động',
      code: 'IT4785',
      credits: 3,
    ),
    Subject(
      id: '2',
      name: 'Cơ sở dữ liệu',
      code: 'IT4440',
      credits: 3,
    ),
    Subject(
      id: '3',
      name: 'Mạng máy tính',
      code: 'IT4560',
      credits: 3,
    ),
  ];

  static List<TeachingSession> mockTeachingSessions = [
    TeachingSession(
      id: '1',
      subjectId: '1',
      teacherId: '1',
      classCode: 'IT4785.01',
      startTime: DateTime.now().add(const Duration(hours: 1)),
      endTime: DateTime.now().add(const Duration(hours: 3)),
      location: 'Phòng 301 - C2',
    ),
    TeachingSession(
      id: '2',
      subjectId: '2',
      teacherId: '1',
      classCode: 'IT4440.01',
      startTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      endTime: DateTime.now().add(const Duration(days: 1, hours: 4)),
      location: 'Phòng 205 - C1',
    ),
  ];
}
