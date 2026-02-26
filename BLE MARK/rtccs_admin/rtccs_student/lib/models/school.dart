class School {
  final String id;
  final String name;

  School({required this.id, required this.name});

  factory School.fromMap(Map<String, dynamic> map) {
    return School(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
} 