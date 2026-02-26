class AdminProfile {
  final String id; // Firebase Auth UID
  final String email;
  final String fullName;
  final String? mobileNumber;
  final String role; // e.g., "Super Admin", "Admin"
  final String? instituteName;
  final String? profilePhotoUrl;
  final DateTime? lastLoginTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.mobileNumber,
    required this.role,
    this.instituteName,
    this.profilePhotoUrl,
    this.lastLoginTime,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminProfile.fromMap(Map<String, dynamic> map) {
    return AdminProfile(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? map['name'] ?? '',
      mobileNumber: map['mobileNumber'],
      role: map['role'] ?? 'Admin',
      instituteName: map['instituteName'] ?? map['institute'],
      profilePhotoUrl: map['profilePhotoUrl'],
      lastLoginTime: map['lastLoginTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLoginTime'])
          : null,
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
      'fullName': fullName,
      'mobileNumber': mobileNumber,
      'role': role,
      'instituteName': instituteName,
      'profilePhotoUrl': profilePhotoUrl,
      'lastLoginTime': lastLoginTime?.millisecondsSinceEpoch,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  AdminProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? mobileNumber,
    String? role,
    String? instituteName,
    String? profilePhotoUrl,
    DateTime? lastLoginTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      role: role ?? this.role,
      instituteName: instituteName ?? this.instituteName,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get initials {
    if (fullName.isEmpty) return 'AD';
    final names = fullName.split(' ');
    if (names.length == 1) {
      return names[0].substring(0, 1).toUpperCase();
    }
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }
}
