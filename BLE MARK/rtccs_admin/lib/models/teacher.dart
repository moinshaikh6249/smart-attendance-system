class Teacher {
  final String id; // Firebase Auth UID or custom ID
  final String email;
  final String name;
  final String bleUuid; // Permanent 128-bit UUID (version 4)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Teacher({
    required this.id,
    required this.email,
    required this.name,
    required this.bleUuid,
    this.createdAt,
    this.updatedAt,
  });

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      bleUuid: map['bleUuid'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'bleUuid': bleUuid,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }
}

