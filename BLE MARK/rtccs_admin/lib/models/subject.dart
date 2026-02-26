class Subject {
  final String id;
  final String name;
  final String classId;

  Subject({required this.id, required this.name, required this.classId});

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      classId: map['classId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'classId': classId,
    };
  }
} 