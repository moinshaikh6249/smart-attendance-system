class AttendanceRecord {
  final String studentUUID;
  final String schoolID;
  final String classID;
  final String subjectID;
  final String date;
  final String method; // e.g. 'BLE', 'QR', 'Manual'
  final String? facePhotoUrl;
  final int timestamp;

  AttendanceRecord({
    required this.studentUUID,
    required this.schoolID,
    required this.classID,
    required this.subjectID,
    required this.date,
    required this.method,
    this.facePhotoUrl,
    required this.timestamp,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      studentUUID: map['studentUUID'] ?? '',
      schoolID: map['schoolID'] ?? '',
      classID: map['classID'] ?? '',
      subjectID: map['subjectID'] ?? '',
      date: map['date'] ?? '',
      method: map['method'] ?? '',
      facePhotoUrl: map['facePhotoUrl'],
      timestamp: map['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentUUID': studentUUID,
      'schoolID': schoolID,
      'classID': classID,
      'subjectID': subjectID,
      'date': date,
      'method': method,
      'facePhotoUrl': facePhotoUrl,
      'timestamp': timestamp,
    };
  }
}
