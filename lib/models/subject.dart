import '../widgets/common/data_table_row.dart';

class Subject {
  final String id;
  final String code;
  final String name;
  final String description;
  final int credits;
  final String department;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subject({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.credits,
    required this.department,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      credits: json['credits'] ?? 0,
      department: json['department'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'credits': credits,
      'department': department,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// Simple subject data class for table display
class SubjectData implements TableRowData {
  @override
  final int id;
  @override
  final String code;
  @override
  final String name;
  final String department;
  final int credits;

  // Additional fields for API operations
  final int? departmentId;
  final String apiId; // Store original API ID for operations

  // Required fields from TableRowData interface - not used for subjects
  @override
  String get phone => '';
  @override
  String get email => '';
  @override
  String get birthDate => '';

  SubjectData({
    required this.id,
    required this.code,
    required this.name,
    required this.department,
    required this.credits,
    this.departmentId,
    required this.apiId,
  });

  factory SubjectData.fromJson(Map<String, dynamic> json) {
    return SubjectData(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      department: json['department'] ?? '',
      credits: json['credits'] ?? 0,
      departmentId: json['department_id'],
      apiId: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'department': department,
      'credits': credits,
    };
  }

  factory SubjectData.fromSubject(Subject subject, int tableId) {
    return SubjectData(
      id: tableId,
      code: subject.code,
      name: subject.name,
      department: subject.department,
      credits: subject.credits,
      apiId: subject.id,
    );
  }
}
