class Student {
  final String uuid;
  final String name;
  final String? profilePhotoUrl;
  final String? schoolId;
  final String? classId;
  final String? subjectId;
  final String? email;
  final String? phoneNumber;

  Student({
    required this.uuid,
    required this.name,
    this.profilePhotoUrl,
    this.schoolId,
    this.classId,
    this.subjectId,
    this.email,
    this.phoneNumber,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      uuid: map['uuid'] ?? '',
      name: map['name'] ?? '',
      profilePhotoUrl: map['profilePhotoUrl'],
      schoolId: map['schoolId'],
      classId: map['classId'],
      subjectId: map['subjectId'],
      email: map['email'],
      phoneNumber: map['phoneNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'name': name,
      'profilePhotoUrl': profilePhotoUrl,
      'schoolId': schoolId,
      'classId': classId,
      'subjectId': subjectId,
      'email': email,
      'phoneNumber': phoneNumber,
    };
  }
} 