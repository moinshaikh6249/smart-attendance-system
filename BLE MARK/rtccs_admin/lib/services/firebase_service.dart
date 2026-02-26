import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/school.dart';
import '../models/classroom.dart';
import '../models/subject.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import '../models/teacher.dart';
import '../models/pending_attendance_request.dart';
import '../models/admin_profile.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth
  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  Future<void> signOut() async => _auth.signOut();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Schools
  Future<List<School>> fetchSchools() async {
    final snapshot = await _db.ref('schools').get();
    print('Schools snapshot:  [32m${snapshot.value} [0m'); // DEBUG
    if (snapshot.exists) {
      return (snapshot.value as Map).entries.map((e) => School.fromMap({...e.value, 'id': e.key})).toList();
    }
    return [];
  }

  // Classes
  Future<List<Classroom>> fetchClasses(String schoolId) async {
    final snapshot = await _db.ref('classes/$schoolId').get();
    if (snapshot.exists) {
      return (snapshot.value as Map).entries.map((e) => Classroom.fromMap({...e.value, 'id': e.key, 'schoolId': schoolId})).toList();
    }
    return [];
  }

  // Subjects
  Future<List<Subject>> fetchSubjects(String schoolId, String classId) async {
    final snapshot = await _db.ref('subjects/$schoolId/$classId').get();
    if (snapshot.exists) {
      return (snapshot.value as Map).entries.map((e) => Subject.fromMap({...e.value, 'id': e.key, 'classId': classId})).toList();
    }
    return [];
  }

  // Students - Updated to work with new structure
  Future<List<Student>> fetchStudents(String schoolId, String classId) async {
    try {
      // First try to get students from the specific path structure
      final snapshot = await _db.ref('students/$schoolId/$classId').get();
      if (snapshot.exists) {
        List<Student> students = [];
        final data = snapshot.value as Map;
        
        // Iterate through subjects and their students
        for (final subjectEntry in data.entries) {
          final subjectStudents = subjectEntry.value as Map;
          for (final studentEntry in subjectStudents.entries) {
            final studentData = studentEntry.value as Map;
            students.add(Student.fromMap({
              ...studentData,
              'uuid': studentEntry.key,
            }));
          }
        }
        return students;
      }
      
      // If no students found in specific path, try general students path
      final generalSnapshot = await _db.ref('students').get();
      if (generalSnapshot.exists) {
        List<Student> students = [];
        final data = generalSnapshot.value as Map;
        
        for (final entry in data.entries) {
          final studentData = entry.value as Map;
          // Filter students by school and class
          if (studentData['schoolId'] == schoolId && studentData['classId'] == classId) {
            students.add(Student.fromMap({
              ...studentData,
              'uuid': entry.key,
            }));
          }
        }
        return students;
      }
      
      return [];
    } catch (e) {
      print('Error fetching students: $e');
      return [];
    }
  }

  // Fetch all students (for admin dashboard)
  Future<List<Student>> fetchAllStudents() async {
    try {
      final snapshot = await _db.ref('students').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        final Set<String> seenUuids = {};
        final List<Student> students = [];
        
        // Extract students from the data structure
        // Students can be at students/$uuid (flat) or students/$schoolId/$classId/$subjectId/$uuid (nested)
        _extractStudentsFromData(data, seenUuids, students);
        
        return students;
      }
      return [];
    } catch (e) {
      print('Error fetching all students: $e');
      return [];
    }
  }
  
  // Helper method to extract students from data structure (handles both flat and nested)
  void _extractStudentsFromData(dynamic data, Set<String> seenUuids, List<Student> students) {
    if (data is! Map) return;
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is Map) {
        // Check if this is a student record (has 'uuid' or 'name' field)
        if (value.containsKey('uuid') || value.containsKey('name')) {
          final studentData = Map<String, dynamic>.from(value);
          final uuid = studentData['uuid'] as String? ?? key;
          
          // Only add if we haven't seen this UUID before (avoid duplicates)
          if (!seenUuids.contains(uuid) && studentData.containsKey('name')) {
            students.add(Student.fromMap({
              ...studentData,
              'uuid': uuid,
            }));
            seenUuids.add(uuid);
          }
        } else {
          // This might be a nested structure, continue recursively
          _extractStudentsFromData(value, seenUuids, students);
        }
      }
    }
  }

  // Attendance
  Future<void> saveAttendance(AttendanceRecord record) async {
    await _db.ref('attendance/${record.schoolID}/${record.classID}/${record.subjectID}/${record.date}/${record.studentUUID}').set(record.toMap());
  }

  // Fetch attendance records
  Future<List<AttendanceRecord>> fetchAttendanceRecords(String schoolId, String classId, String subjectId, String date) async {
    try {
      final snapshot = await _db.ref('attendance/$schoolId/$classId/$subjectId/$date').get();
      if (snapshot.exists) {
        return (snapshot.value as Map).entries.map((e) => AttendanceRecord.fromMap({...e.value, 'studentUUID': e.key})).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching attendance records: $e');
      return [];
    }
  }

  // Fetch pending approvals
  Future<List<Student>> fetchPendingApprovals() async {
    try {
      final snapshot = await _db.ref('pending_approvals').get();
      if (snapshot.exists) {
        return (snapshot.value as Map).entries.map((e) {
          final studentData = e.value as Map;
          return Student.fromMap({
            ...studentData,
            'uuid': e.key,
          });
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching pending approvals: $e');
      return [];
    }
  }

  // Approve student
  Future<void> approveStudent(String uuid) async {
    try {
      // Get student data from pending approvals
      final snapshot = await _db.ref('pending_approvals/$uuid').get();
      if (snapshot.exists) {
        final studentData = Map<String, dynamic>.from(snapshot.value as Map);
        final schoolId = studentData['schoolId'] as String?;
        final classId = studentData['classId'] as String?;
        final subjectId = studentData['subjectId'] as String?;
        
        if (schoolId == null || classId == null || subjectId == null) {
          throw Exception('Missing school, class, or subject information');
        }
        
        // Remove status field before saving
        studentData.remove('status');
        
        // Save to the proper location: students/schoolId/classId/subjectId/uuid
        await _db.ref('students/$schoolId/$classId/$subjectId/$uuid').set(studentData);
        
        // Also save under general students path for easy lookup
        await _db.ref('students/$uuid').set(studentData);
        
        // Remove from pending approvals
        await _db.ref('pending_approvals/$uuid').remove();
      }
    } catch (e) {
      print('Error approving student: $e');
      throw e;
    }
  }

  // Upload face photo
  Future<String> uploadFacePhoto(File file, String studentUUID, String date) async {
    final ref = _storage.ref('face_photos/$studentUUID/$date.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // Attendance QR Session APIs
  Future<void> startAttendanceSession({
    required String schoolId,
    required String classId,
    required String subjectId,
    required String token,
    required int expiresAtMs,
  }) async {
    final path = 'qr_sessions/$schoolId/$classId/$subjectId/current';
    await _db.ref(path).set({
      'token': token,
      'active': true,
      'createdAt': ServerValue.timestamp,
      'expiresAt': expiresAtMs,
    });
  }

  Future<void> updateAttendanceSessionToken({
    required String schoolId,
    required String classId,
    required String subjectId,
    required String token,
    required int expiresAtMs,
  }) async {
    final path = 'qr_sessions/$schoolId/$classId/$subjectId/current';
    await _db.ref(path).update({
      'token': token,
      'expiresAt': expiresAtMs,
    });
  }

  Future<void> endAttendanceSession({
    required String schoolId,
    required String classId,
    required String subjectId,
  }) async {
    final path = 'qr_sessions/$schoolId/$classId/$subjectId/current';
    await _db.ref(path).update({'active': false});
  }

  // ========== TEACHER MANAGEMENT ==========
  
  /// Get or create teacher record with permanent BLE UUID
  Future<Teacher> getOrCreateTeacher(String userId, String email, String name) async {
    try {
      final snapshot = await _db.ref('teachers/$userId').get();
      if (snapshot.exists) {
        return Teacher.fromMap({
          ...Map<String, dynamic>.from(snapshot.value as Map),
          'id': userId,
        });
      }
      
      // Create new teacher with UUID v4
      final uuid = const Uuid();
      final bleUuid = uuid.v4();
      final teacher = Teacher(
        id: userId,
        email: email,
        name: name,
        bleUuid: bleUuid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _db.ref('teachers/$userId').set(teacher.toMap());
      return teacher;
    } catch (e) {
      print('Error getting/creating teacher: $e');
      rethrow;
    }
  }

  /// Get teacher by ID
  Future<Teacher?> getTeacher(String userId) async {
    try {
      final snapshot = await _db.ref('teachers/$userId').get();
      if (snapshot.exists) {
        return Teacher.fromMap({
          ...Map<String, dynamic>.from(snapshot.value as Map),
          'id': userId,
        });
      }
      return null;
    } catch (e) {
      print('Error getting teacher: $e');
      return null;
    }
  }

  /// Get teacher by BLE UUID
  Future<Teacher?> getTeacherByBleUuid(String bleUuid) async {
    try {
      final snapshot = await _db.ref('teachers').get();
      if (snapshot.exists) {
        final teachers = snapshot.value as Map;
        for (final entry in teachers.entries) {
          final teacherData = entry.value as Map;
          if (teacherData['bleUuid'] == bleUuid) {
            return Teacher.fromMap({
              ...teacherData,
              'id': entry.key,
            });
          }
        }
      }
      return null;
    } catch (e) {
      print('Error getting teacher by BLE UUID: $e');
      return null;
    }
  }

  /// Get all teachers for a subject (for student app to know which UUIDs to scan for)
  Future<List<Teacher>> getTeachersForSubject(String schoolId, String classId, String subjectId) async {
    try {
      // In a real system, you'd have a mapping of teachers to subjects
      // For now, we'll fetch all teachers and let the student app filter
      // You can enhance this with a teachers_subjects mapping table
      final snapshot = await _db.ref('teachers').get();
      if (snapshot.exists) {
        return (snapshot.value as Map).entries.map((e) {
          return Teacher.fromMap({
            ...Map<String, dynamic>.from(e.value as Map),
            'id': e.key,
          });
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting teachers for subject: $e');
      return [];
    }
  }

  // ========== PENDING ATTENDANCE REQUESTS ==========
  
  /// Create a pending attendance request from student
  Future<String> createPendingAttendanceRequest({
    required String studentUUID,
    required String studentName,
    required String teacherId,
    required String teacherName,
    required String schoolID,
    required String classID,
    required String subjectID,
    required String date,
  }) async {
    try {
      final requestId = const Uuid().v4();
      final request = PendingAttendanceRequest(
        requestId: requestId,
        studentUUID: studentUUID,
        studentName: studentName,
        teacherId: teacherId,
        teacherName: teacherName,
        schoolID: schoolID,
        classID: classID,
        subjectID: subjectID,
        date: date,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        status: 'pending',
      );
      
      // Store under teacher's pending requests
      await _db.ref('pending_attendance_requests/$teacherId/$requestId').set(request.toMap());
      
      // Also store under student's requests for history
      await _db.ref('student_attendance_requests/$studentUUID/$requestId').set(request.toMap());
      
      return requestId;
    } catch (e) {
      print('Error creating pending attendance request: $e');
      rethrow;
    }
  }

  /// Get pending attendance requests for a teacher
  Future<List<PendingAttendanceRequest>> getPendingAttendanceRequests(String teacherId) async {
    try {
      final snapshot = await _db.ref('pending_attendance_requests/$teacherId').get();
      if (snapshot.exists) {
        return (snapshot.value as Map).entries.map((e) {
          return PendingAttendanceRequest.fromMap({
            ...Map<String, dynamic>.from(e.value as Map),
            'requestId': e.key,
          });
        }).where((req) => req.status == 'pending').toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
      }
      return [];
    } catch (e) {
      print('Error getting pending attendance requests: $e');
      return [];
    }
  }

  /// Stream of pending attendance requests for real-time updates
  Stream<List<PendingAttendanceRequest>> watchPendingAttendanceRequests(String teacherId) {
    return _db.ref('pending_attendance_requests/$teacherId').onValue.map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).entries.map((e) {
          return PendingAttendanceRequest.fromMap({
            ...Map<String, dynamic>.from(e.value as Map),
            'requestId': e.key,
          });
        }).where((req) => req.status == 'pending').toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      return <PendingAttendanceRequest>[];
    });
  }

  /// Approve a pending attendance request
  Future<void> approveAttendanceRequest({
    required String teacherId,
    required String requestId,
    required PendingAttendanceRequest request,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Update request status
      await _db.ref('pending_attendance_requests/$teacherId/$requestId').update({
        'status': 'approved',
        'approvedAt': now,
      });
      
      // Update student's request
      await _db.ref('student_attendance_requests/${request.studentUUID}/$requestId').update({
        'status': 'approved',
        'approvedAt': now,
      });
      
      // Create final attendance record
      final attendanceRecord = AttendanceRecord(
        studentUUID: request.studentUUID,
        schoolID: request.schoolID,
        classID: request.classID,
        subjectID: request.subjectID,
        date: request.date,
        method: 'BLE',
        timestamp: now,
      );
      
      await saveAttendance(attendanceRecord);
      
      // Also save to attendance_logs
      await _db.ref('attendance_logs/${request.studentUUID}/${requestId}').set(attendanceRecord.toMap());
    } catch (e) {
      print('Error approving attendance request: $e');
      rethrow;
    }
  }

  /// Approve all pending requests for a teacher's current session
  Future<int> approveAllPendingRequests({
    required String teacherId,
    required String schoolID,
    required String classID,
    required String subjectID,
    required String date,
  }) async {
    try {
      final requests = await getPendingAttendanceRequests(teacherId);
      final matchingRequests = requests.where((req) =>
        req.schoolID == schoolID &&
        req.classID == classID &&
        req.subjectID == subjectID &&
        req.date == date
      ).toList();
      
      int approvedCount = 0;
      for (final request in matchingRequests) {
        await approveAttendanceRequest(
          teacherId: teacherId,
          requestId: request.requestId,
          request: request,
        );
        approvedCount++;
      }
      
      return approvedCount;
    } catch (e) {
      print('Error approving all requests: $e');
      rethrow;
    }
  }

  /// Reject a pending attendance request
  Future<void> rejectAttendanceRequest({
    required String teacherId,
    required String requestId,
    required String studentUUID,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      await _db.ref('pending_attendance_requests/$teacherId/$requestId').update({
        'status': 'rejected',
        'rejectedAt': now,
      });
      
      await _db.ref('student_attendance_requests/$studentUUID/$requestId').update({
        'status': 'rejected',
        'rejectedAt': now,
      });
    } catch (e) {
      print('Error rejecting attendance request: $e');
      rethrow;
    }
  }

  // ========== ADMIN PROFILE MANAGEMENT ==========
  
  /// Fetch admin profile from Firebase
  Future<AdminProfile> fetchAdminProfile(String userId) async {
    try {
      // Try to get from admins collection
      final snapshot = await _db.ref('admins/$userId').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return AdminProfile.fromMap({
          ...data,
          'id': userId,
        });
      }
      
      // Fallback: get from auth user if admin record doesn't exist
      final user = _auth.currentUser;
      if (user != null && user.uid == userId) {
        // Create basic profile from auth data
        final basicProfile = AdminProfile(
          id: userId,
          email: user.email ?? '',
          fullName: user.displayName ?? 'Admin User',
          role: 'Admin',
          lastLoginTime: DateTime.now(),
        );
        
        // Save to database for future use
        await _db.ref('admins/$userId').set(basicProfile.toMap());
        return basicProfile;
      }
      
      throw Exception('Admin profile not found');
    } catch (e) {
      print('Error fetching admin profile: $e');
      rethrow;
    }
  }
  
  /// Update admin profile details
  Future<bool> updateAdminProfile({
    required String userId,
    required String fullName,
    String? mobileNumber,
    String? profilePhotoUrl,
  }) async {
    try {
      final updates = {
        'fullName': fullName,
        'mobileNumber': mobileNumber,
        'updatedAt': ServerValue.timestamp,
      };
      
      if (profilePhotoUrl != null) {
        updates['profilePhotoUrl'] = profilePhotoUrl;
      }
      
      await _db.ref('admins/$userId').update(updates);
      return true;
    } catch (e) {
      print('Error updating admin profile: $e');
      return false;
    }
  }
  
  /// Upload admin profile photo
  Future<String> uploadAdminProfilePhoto(String userId, File file) async {
    try {
      final ref = _storage.ref('admin_profiles/$userId/profile.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading admin profile photo: $e');
      rethrow;
    }
  }
  
  /// Change admin password
  Future<bool> changeAdminPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Re-authenticate with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      
      return true;
    } catch (e) {
      print('Error changing admin password: $e');
      return false;
    }
  }
  
  /// Update last login time
  Future<void> updateAdminLastLogin(String userId) async {
    try {
      await _db.ref('admins/$userId').update({
        'lastLoginTime': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error updating last login time: $e');
    }
  }
  
  /// Fetch admin login activity (basic implementation)
  Future<List<Map<String, dynamic>>> fetchAdminLoginActivity(String userId) async {
    try {
      final snapshot = await _db.ref('admin_login_logs/$userId').orderByChild('timestamp').limitToLast(20).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data.entries.map((e) {
          return {
            'id': e.key,
            ...Map<String, dynamic>.from(e.value),
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching login activity: $e');
      return [];
    }
  }
  
  /// Log admin login event
  Future<void> logAdminLogin(String userId, {String? deviceInfo, String? ipAddress}) async {
    try {
      final loginLog = {
        'timestamp': ServerValue.timestamp,
        'deviceInfo': deviceInfo ?? 'Unknown Device',
        'ipAddress': ipAddress ?? 'Unknown',
      };
      
      await _db.ref('admin_login_logs/$userId').push().set(loginLog);
    } catch (e) {
      print('Error logging admin login: $e');
    }
  }
} 