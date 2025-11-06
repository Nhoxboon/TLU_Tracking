class Major {
  final int id;
  final String majorCode;
  final String majorName;
  final int facultyId;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Major({
    required this.id,
    required this.majorCode,
    required this.majorName,
    required this.facultyId,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Major.fromJson(Map<String, dynamic> json) {
    return Major(
      id: json['id'] ?? 0,
      majorCode:
          json['code'] ?? '', // API trả về 'code' không phải 'major_code'
      majorName:
          json['name'] ?? '', // API trả về 'name' không phải 'major_name'
      facultyId: json['faculty_id'] ?? 0,
      description: json['description'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'major_code': majorCode,
      'major_name': majorName,
      'faculty_id': facultyId,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'code': majorCode, // API mong đợi 'code'
      'name': majorName, // API mong đợi 'name'
      'faculty_id': facultyId,
    };
  }

  Major copyWith({
    int? id,
    String? majorCode,
    String? majorName,
    int? facultyId,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Major(
      id: id ?? this.id,
      majorCode: majorCode ?? this.majorCode,
      majorName: majorName ?? this.majorName,
      facultyId: facultyId ?? this.facultyId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
