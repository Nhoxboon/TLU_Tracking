class Department {
  final int id;
  final String code;
  final String name;
  final int? facultyId;
  final String? facultyName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Department({
    required this.id,
    required this.code,
    required this.name,
    this.facultyId,
    this.facultyName,
    this.createdAt,
    this.updatedAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      facultyId: json['faculty_id'],
      facultyName: json['faculty_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'faculty_id': facultyId,
      'faculty_name': facultyName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Department copyWith({
    int? id,
    String? code,
    String? name,
    int? facultyId,
    String? facultyName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Department(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      facultyId: facultyId ?? this.facultyId,
      facultyName: facultyName ?? this.facultyName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Department{id: $id, code: $code, name: $name, facultyId: $facultyId, facultyName: $facultyName}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Department && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
