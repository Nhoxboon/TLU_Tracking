import 'user.dart';
import '../utils/id_generator.dart';

class Teacher extends User {
  final String hometown;
  final String phoneNumber;
  final DateTime dateOfBirth;

  Teacher({
    required String email, // Email is also the username for teachers
    required String password,
    required String fullName,
    required this.hometown,
    required this.phoneNumber,
    required this.dateOfBirth,
  }) : super(
         id: IdGenerator.generateId('teacher'),
         username: email, // Email is used as username
         password: password,
         email: email,
         fullName: fullName,
         role: UserRole.teacher,
       );

  @override
  bool authenticate(String username, String password) {
    // In a real app, this would check against a database and use hashing
    return username == email && this.password == password;
  }
}
