class PendingAttendanceRequest {
  final String requestId; // Auto-generated ID
  final String studentUUID;
  final String studentName;
  final String teacherId;
  final String teacherName;
  final String schoolID;
  final String classID;
  final String subjectID;
  final String date;
  final int timestamp; // When student detected the teacher
  final String status; // 'pending', 'approved', 'rejected'
  final int? approvedAt;
  final int? rejectedAt;

  PendingAttendanceRequest({
    required this.requestId,
    required this.studentUUID,
    required this.studentName,
    required this.teacherId,
    required this.teacherName,
    required this.schoolID,
    required this.classID,
    required this.subjectID,
    required this.date,
    required this.timestamp,
    this.status = 'pending',
    this.approvedAt,
    this.rejectedAt,
  });

  factory PendingAttendanceRequest.fromMap(Map<String, dynamic> map) {
    return PendingAttendanceRequest(
      requestId: map['requestId'] ?? '',
      studentUUID: map['studentUUID'] ?? '',
      studentName: map['studentName'] ?? '',
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      schoolID: map['schoolID'] ?? '',
      classID: map['classID'] ?? '',
      subjectID: map['subjectID'] ?? '',
      date: map['date'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      status: map['status'] ?? 'pending',
      approvedAt: map['approvedAt'],
      rejectedAt: map['rejectedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'studentUUID': studentUUID,
      'studentName': studentName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'schoolID': schoolID,
      'classID': classID,
      'subjectID': subjectID,
      'date': date,
      'timestamp': timestamp,
      'status': status,
      'approvedAt': approvedAt,
      'rejectedAt': rejectedAt,
    };
  }
}

