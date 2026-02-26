class Student {
  final String uuid;
  final String name;
  final String? profilePhotoUrl;
  final String? schoolId;
  final String? classId;
  final String? email;
  final String? enrollmentNo;
  final String? prn;
  final String? program;
  final String? semester;
  final String? year;
  final String? division;
  final String? className;
  final String? schoolName;
  final String? mobile;
  final String? alternateEmail;

  Student({
    required this.uuid,
    required this.name,
    this.profilePhotoUrl,
    this.schoolId,
    this.classId,
    this.email,
    this.enrollmentNo,
    this.prn,
    this.program,
    this.semester,
    this.year,
    this.division,
    this.className,
    this.schoolName,
    this.mobile,
    this.alternateEmail,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      uuid: map['uuid'] ?? '',
      name: map['name'] ?? '',
      profilePhotoUrl: map['profilePhotoUrl'],
      schoolId: map['schoolId'],
      classId: map['classId'],
      email: map['email'],
      enrollmentNo: map['enrollmentNo'],
      prn: map['prn'],
      program: map['program'],
      semester: map['semester'],
      year: map['year'],
      division: map['division'],
      className: map['className'],
      schoolName: map['schoolName'],
      mobile: map['mobile'],
      alternateEmail: map['alternateEmail'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'name': name,
      'profilePhotoUrl': profilePhotoUrl,
      'schoolId': schoolId,
      'classId': classId,
      'email': email,
      'enrollmentNo': enrollmentNo,
      'prn': prn,
      'program': program,
      'semester': semester,
      'year': year,
      'division': division,
      'className': className,
      'schoolName': schoolName,
      'mobile': mobile,
      'alternateEmail': alternateEmail,
    };
  }

  Student copyWith({
    String? uuid,
    String? name,
    String? profilePhotoUrl,
    String? schoolId,
    String? classId,
    String? email,
    String? enrollmentNo,
    String? prn,
    String? program,
    String? semester,
    String? year,
    String? division,
    String? className,
    String? schoolName,
    String? mobile,
    String? alternateEmail,
  }) {
    return Student(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      schoolId: schoolId ?? this.schoolId,
      classId: classId ?? this.classId,
      email: email ?? this.email,
      enrollmentNo: enrollmentNo ?? this.enrollmentNo,
      prn: prn ?? this.prn,
      program: program ?? this.program,
      semester: semester ?? this.semester,
      year: year ?? this.year,
      division: division ?? this.division,
      className: className ?? this.className,
      schoolName: schoolName ?? this.schoolName,
      mobile: mobile ?? this.mobile,
      alternateEmail: alternateEmail ?? this.alternateEmail,
    );
  }
} 