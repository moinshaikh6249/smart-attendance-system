class Classroom {
  final String id;
  final String name;
  final String schoolId;

  Classroom({required this.id, required this.name, required this.schoolId});

  factory Classroom.fromMap(Map<String, dynamic> map) {
    return Classroom(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      schoolId: map['schoolId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'schoolId': schoolId,
    };
  }
} 