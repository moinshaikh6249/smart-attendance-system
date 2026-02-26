import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/school.dart';
import '../models/classroom.dart';
import '../models/subject.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';
import 'dart:io';

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

  // Student Registration - Now saves to pending_approvals for admin approval
  Future<void> registerStudent({
    required String uuid,
    required String name,
    required String phoneNumber,
    required String schoolId,
    required String classId,
    required String subjectId,
  }) async {
    final studentData = {
      'uuid': uuid,
      'name': name,
      'phoneNumber': phoneNumber,
      'schoolId': schoolId,
      'classId': classId,
      'subjectId': subjectId,
      'registrationDate': DateTime.now().toIso8601String(),
      'status': 'pending',
    };

    // Save to pending_approvals for admin approval
    await _db.ref('pending_approvals/$uuid').set(studentData);
  }

  // Student Recovery
  Future<Student?> recoverStudentUUID({
    required String name,
    required String phoneNumber,
    required String schoolId,
    required String classId,
    required String subjectId,
  }) async {
    try {
      // Query the specific path
      final snapshot = await _db.ref('students/$schoolId/$classId/$subjectId').get();
      
      if (snapshot.exists) {
        final students = snapshot.value as Map;
        
        for (final entry in students.entries) {
          final studentData = entry.value as Map;
          if (studentData['name'] == name && studentData['phoneNumber'] == phoneNumber) {
            return Student.fromMap({
              ...studentData,
              'uuid': entry.key,
            });
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error recovering student UUID: $e');
      return null;
    }
  }

  // Student
  Future<Student?> fetchStudentByUUID(String uuid) async {
    final snapshot = await _db.ref('students').child(uuid).get();
    if (snapshot.exists) {
      return Student.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
    }
    return null;
  }

  // Attendance
  Future<void> saveAttendance(AttendanceRecord record) async {
    await _db.ref('attendance/${record.schoolID}/${record.classID}/${record.subjectID}/${record.date}/${record.studentUUID}').set(record.toMap());
  }

  Future<List<AttendanceRecord>> fetchAttendanceLogs(String uuid) async {
    try {
      // Try to fetch from the main attendance structure
      final List<AttendanceRecord> records = [];
      
      // Query attendance records for this student
      final snapshot = await _db.ref('attendance').get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        
        // Iterate through schools -> classes -> subjects -> dates -> students
        for (final schoolEntry in data.entries) {
          final schoolId = schoolEntry.key;
          final schoolData = schoolEntry.value as Map;
          
          for (final classEntry in schoolData.entries) {
            final classId = classEntry.key;
            final classData = classEntry.value as Map;
            
            for (final subjectEntry in classData.entries) {
              final subjectId = subjectEntry.key;
              final subjectData = subjectEntry.value as Map;
              
              for (final dateEntry in subjectData.entries) {
                final date = dateEntry.key;
                final dateData = dateEntry.value as Map;
                
                if (dateData.containsKey(uuid)) {
                  final recordData = Map<String, dynamic>.from(dateData[uuid] as Map);
                  recordData['studentUUID'] = uuid;
                  recordData['schoolID'] = schoolId;
                  recordData['classID'] = classId;
                  recordData['subjectID'] = subjectId;
                  recordData['date'] = date;
                  
                  records.add(AttendanceRecord.fromMap(recordData));
                }
              }
            }
          }
        }
      }
      
      return records;
    } catch (e) {
      print('[FirebaseService] Error fetching attendance: $e');
      return [];
    }
  }

  // Upload profile photo
  Future<String> uploadProfilePhoto(File file, String uuid) async {
    final ref = _storage.ref('profile_photos/$uuid.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  /// Update student profile (mobile, alternateEmail, profilePhotoUrl)
  Future<void> updateStudentProfile({
    required String uuid,
    String? mobile,
    String? alternateEmail,
    String? profilePhotoUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (mobile != null) {
        updates['mobile'] = mobile;
      }
      if (alternateEmail != null) {
        updates['alternateEmail'] = alternateEmail;
      }
      if (profilePhotoUrl != null) {
        updates['profilePhotoUrl'] = profilePhotoUrl;
      }

      if (updates.isNotEmpty) {
        await _db.ref('students/$uuid').update(updates);
        print('[FirebaseService] Updated student profile: $uuid');
      }
    } catch (e) {
      print('Error updating student profile: $e');
      rethrow;
    }
  }

  // ========== TEACHER LOOKUP (for BLE scanning) ==========
  
  /// Get teacher by BLE UUID (used when student detects a teacher's BLE broadcast)
  Future<Map<String, dynamic>?> getTeacherByBleUuid(String bleUuid) async {
    try {
      final snapshot = await _db.ref('teachers').get();
      if (snapshot.exists) {
        final teachers = snapshot.value as Map;
        for (final entry in teachers.entries) {
          final teacherData = entry.value as Map;
          if (teacherData['bleUuid'] == bleUuid) {
            return {
              'id': entry.key,
              'name': teacherData['name'] ?? 'Unknown Teacher',
              'email': teacherData['email'] ?? '',
              'bleUuid': bleUuid,
            };
          }
        }
      }
      return null;
    } catch (e) {
      print('Error getting teacher by BLE UUID: $e');
      return null;
    }
  }

  /// Get all teacher UUIDs for a subject (to know which UUIDs to scan for)
  /// This helps the student app filter BLE advertisements
  Future<Set<String>> getTeacherUuidsForSubject(String schoolId, String classId, String subjectId) async {
    try {
      // In a real system, you'd query a teachers_subjects mapping
      // For now, we'll fetch all teachers and return their UUIDs
      // You can enhance this with proper subject-teacher relationships
      final snapshot = await _db.ref('teachers').get();
      final uuids = <String>{};
      
      if (snapshot.exists) {
        final teachers = snapshot.value as Map;
        for (final entry in teachers.entries) {
          final teacherData = entry.value as Map;
          final bleUuid = teacherData['bleUuid'];
          if (bleUuid != null && bleUuid.isNotEmpty) {
            uuids.add(bleUuid);
          }
        }
      }
      
      print('[FirebaseService] Found ${uuids.length} teacher UUIDs to scan for');
      return uuids;
    } catch (e) {
      print('Error getting teacher UUIDs: $e');
      return {};
    }
  }

  // ========== PENDING ATTENDANCE REQUESTS ==========
  
  /// Create a pending attendance request when student detects teacher
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
      final requestId = DateTime.now().millisecondsSinceEpoch.toString();
      final requestData = {
        'requestId': requestId,
        'studentUUID': studentUUID,
        'studentName': studentName,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'schoolID': schoolID,
        'classID': classID,
        'subjectID': subjectID,
        'date': date,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'status': 'pending',
      };
      
      // Store under teacher's pending requests
      await _db.ref('pending_attendance_requests/$teacherId/$requestId').set(requestData);
      
      // Also store under student's requests for history
      await _db.ref('student_attendance_requests/$studentUUID/$requestId').set(requestData);
      
      print('[FirebaseService] Created pending attendance request: $requestId');
      return requestId;
    } catch (e) {
      print('Error creating pending attendance request: $e');
      rethrow;
    }
  }
} 