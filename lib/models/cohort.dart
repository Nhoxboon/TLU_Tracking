class Cohort {
  final int? id;
  final String name;
  final int startYear;
  final int endYear;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Cohort({
    this.id,
    required this.name,
    required this.startYear,
    required this.endYear,
    this.createdAt,
    this.updatedAt,
  });

  factory Cohort.fromJson(Map<String, dynamic> json) {
    return Cohort(
      id: json['id'] as int?,
      name: json['name'] as String,
      startYear: json['start_year'] as int,
      endYear: json['end_year'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'start_year': startYear,
      'end_year': endYear,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // For creating new cohort (without id)
  Map<String, dynamic> toCreateJson() {
    return {'name': name, 'start_year': startYear, 'end_year': endYear};
  }

  // For updating cohort (without id, created_at, updated_at)
  Map<String, dynamic> toUpdateJson() {
    return {'name': name, 'start_year': startYear, 'end_year': endYear};
  }

  @override
  String toString() {
    return 'Cohort{id: $id, name: $name, startYear: $startYear, endYear: $endYear, createdAt: $createdAt, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cohort &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          startYear == other.startYear &&
          endYear == other.endYear;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ startYear.hashCode ^ endYear.hashCode;

  Cohort copyWith({
    int? id,
    String? name,
    int? startYear,
    int? endYear,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cohort(
      id: id ?? this.id,
      name: name ?? this.name,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
