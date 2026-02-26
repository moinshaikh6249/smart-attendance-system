import 'package:excel/excel.dart';
import '../models/attendance_record.dart';
import '../models/student.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ExcelService {
  static final ExcelService _instance = ExcelService._internal();
  factory ExcelService() => _instance;
  ExcelService._internal();

  /// Check and request storage permission
  Future<bool> _checkStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we don't need WRITE_EXTERNAL_STORAGE
      // For Android 10-12, scoped storage is used
      // For Android 9 and below, we need permission
      if (await Permission.storage.isGranted) {
        return true;
      }
      
      // Request permission
      final status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      }
      
      // For Android 11+, try manageExternalStorage if storage is denied
      if (status.isDenied || status.isPermanentlyDenied) {
        final manageStatus = await Permission.manageExternalStorage.request();
        return manageStatus.isGranted;
      }
      
      return false;
    }
    return true; // iOS doesn't need permission for app Documents folder
  }

  /// Generate a unique file name with timestamp
  String _generateFileName({
    String? className,
    String? subjectName,
  }) {
    final now = DateTime.now();
    final dateTimeStr = DateFormat('yyyy-MM-dd_HH-mm').format(now);
    
    String baseName = 'Attendance';
    if (className != null && className.isNotEmpty) {
      baseName += '_$className';
    }
    if (subjectName != null && subjectName.isNotEmpty) {
      baseName += '_$subjectName';
    }
    
    return '${baseName}_$dateTimeStr.xlsx';
  }

  /// Get the Downloads directory path
  Future<Directory?> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // Try to get Downloads folder
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        return directory;
      }
      
      // Fallback to external storage
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        // Create Downloads folder in app's external directory
        final downloadsDir = Directory('${externalDir.path}/Downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        return downloadsDir;
      }
    }
    
    // For iOS or fallback
    return await getApplicationDocumentsDirectory();
  }

  /// Export attendance records to Excel file and save to Downloads
  Future<ExportResult> exportAttendanceToExcel(
    List<AttendanceRecord> records,
    String baseFileName, {
    String? className,
    String? subjectName,
    List<Student>? studentsList,
    String? adminName,
    String? instituteName,
  }) async {
    try {
      // Check storage permission
      final hasPermission = await _checkStoragePermission();
      if (!hasPermission) {
        return ExportResult(
          success: false,
          errorMessage: 'Cannot save file without storage permission.',
        );
      }

      // Create Excel workbook
      final excel = Excel.createExcel();
      
      // Delete default sheet
      excel.delete('Sheet1');
      
      // Get package info for version
      String appVersion = '1.0.0';
      String deviceModel = Platform.isAndroid ? 'Android Device' : Platform.isIOS ? 'iOS Device' : 'Desktop';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = packageInfo.version;
      } catch (e) {
        // Fallback if package_info fails
      }
      
      // Group records by student to calculate summary
      final studentRecordsMap = <String, List<AttendanceRecord>>{};
      for (final record in records) {
        studentRecordsMap.putIfAbsent(record.studentUUID, () => []).add(record);
      }
      
      // Create sheets in order
      _createSummarySheet(excel, studentRecordsMap, studentsList, className, subjectName);
      _createDetailedAttendanceSheet(excel, records, studentsList, className, subjectName);
      _createStudentListSheet(excel, studentsList);
      _createExportInfoSheet(
        excel,
        adminName: adminName,
        instituteName: instituteName,
        className: className,
        subjectName: subjectName,
        appVersion: appVersion,
        deviceModel: deviceModel,
        recordCount: records.length,
        records: records,
      );

      // Generate file name
      final fileName = _generateFileName(
        className: className,
        subjectName: subjectName,
      );

      // Get Downloads directory
      final dir = await _getDownloadsDirectory();
      if (dir == null) {
        return ExportResult(
          success: false,
          errorMessage: 'Could not access storage directory.',
        );
      }

      // Save file
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      
      // Check if file already exists and add suffix if needed
      String finalPath = filePath;
      int counter = 1;
      while (await File(finalPath).exists()) {
        final nameWithoutExt = fileName.replaceAll('.xlsx', '');
        finalPath = '${dir.path}/${nameWithoutExt}_$counter.xlsx';
        counter++;
      }

      // Write file
      final bytes = excel.save();
      if (bytes == null) {
        return ExportResult(
          success: false,
          errorMessage: 'Failed to generate Excel file.',
        );
      }
      
      await File(finalPath).writeAsBytes(bytes);

      return ExportResult(
        success: true,
        filePath: finalPath,
        fileName: finalPath.split('/').last,
      );
    } catch (e) {
      return ExportResult(
        success: false,
        errorMessage: 'Couldn\'t save the file. Please check storage permission and free space. Error: $e',
      );
    }
  }

  /// Create Summary Sheet (Sheet 1)
  void _createSummarySheet(
    Excel excel,
    Map<String, List<AttendanceRecord>> studentRecordsMap,
    List<Student>? studentsList,
    String? className,
    String? subjectName,
  ) {
    final sheet = excel['Summary'];
    
    // Style definitions
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#E5E7EB',
      fontColorHex: '#000000',
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Headers
    final headers = [
      'Student ID',
      'Roll No',
      'Student Name',
      'Class',
      'Subject',
      'Total Sessions',
      'Present Count',
      'Absent Count',
      'Attendance %',
    ];

    sheet.appendRow(headers);

    // Apply header style and set column widths
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = headerStyle;
    }

    // Set column widths
    sheet.setColWidth(0, 20); // Student ID
    sheet.setColWidth(1, 10); // Roll No
    sheet.setColWidth(2, 25); // Student Name
    sheet.setColWidth(3, 20); // Class
    sheet.setColWidth(4, 25); // Subject
    sheet.setColWidth(5, 15); // Total Sessions
    sheet.setColWidth(6, 15); // Present Count
    sheet.setColWidth(7, 15); // Absent Count
    sheet.setColWidth(8, 15); // Attendance %

    // Data rows - sorted by student UUID
    final sortedStudentIds = studentRecordsMap.keys.toList()..sort();
    
    int rowIndex = 1;
    for (final studentId in sortedStudentIds) {
      final studentRecords = studentRecordsMap[studentId]!;
      final student = studentsList?.firstWhere(
        (s) => s.uuid == studentId,
        orElse: () => Student(uuid: studentId, name: 'Unknown'),
      );
      
      final totalSessions = studentRecords.length;
      final presentCount = studentRecords.where((r) => 
        r.method.toLowerCase() == 'ble' || 
        r.method.toLowerCase() == 'qr' || 
        r.method.toLowerCase() == 'manual'
      ).length;
      final absentCount = totalSessions - presentCount;
      
      // Add data row
      sheet.appendRow([
        student?.uuid ?? studentId,
        '', // Roll No - not available in current model
        student?.name ?? 'Unknown',
        className ?? 'All Classes',
        subjectName ?? 'All Subjects',
        totalSessions,
        presentCount,
        absentCount,
        '', // Placeholder for formula
      ]);
      
      // Set formula for percentage column
      final percentCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex));
      percentCell.value = '=IF(F${rowIndex + 1}>0,G${rowIndex + 1}/F${rowIndex + 1}*100,0)';
      
      rowIndex++;
    }
  }

  /// Create Detailed Attendance Sheet (Sheet 2)
  void _createDetailedAttendanceSheet(
    Excel excel,
    List<AttendanceRecord> records,
    List<Student>? studentsList,
    String? className,
    String? subjectName,
  ) {
    final sheet = excel['Detailed Attendance'];
    
    // Header style
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#1F2937',
      fontColorHex: '#FFFFFF',
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Headers
    final headers = [
      'Date',
      'Day',
      'Start Time',
      'Class',
      'Subject',
      'Session ID',
      'Student ID',
      'Roll No',
      'Student Name',
      'Status',
      'Marking Mode',
      'Marked At',
      'Device Identifier',
    ];

    sheet.appendRow(headers);

    // Apply header style
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = headerStyle;
    }

    // Set column widths
    sheet.setColWidth(0, 15); // Date
    sheet.setColWidth(1, 10); // Day
    sheet.setColWidth(2, 12); // Start Time
    sheet.setColWidth(3, 20); // Class
    sheet.setColWidth(4, 25); // Subject
    sheet.setColWidth(5, 20); // Session ID
    sheet.setColWidth(6, 20); // Student ID
    sheet.setColWidth(7, 10); // Roll No
    sheet.setColWidth(8, 25); // Student Name
    sheet.setColWidth(9, 12); // Status
    sheet.setColWidth(10, 15); // Marking Mode
    sheet.setColWidth(11, 20); // Marked At
    sheet.setColWidth(12, 20); // Device Identifier

    // Sort records by timestamp
    final sortedRecords = List<AttendanceRecord>.from(records)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Conditional formatting styles
    final presentStyle = CellStyle(backgroundColorHex: '#D1FAE5'); // Light green
    final absentStyle = CellStyle(backgroundColorHex: '#FEE2E2'); // Light red

    // Data rows
    int rowIndex = 1;
    for (final record in sortedRecords) {
      final student = studentsList?.firstWhere(
        (s) => s.uuid == record.studentUUID,
        orElse: () => Student(uuid: record.studentUUID, name: 'Unknown'),
      );
      
      final dateTime = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
      final dateStr = DateFormat('dd-MMM-yyyy').format(dateTime);
      final dayStr = DateFormat('EEE').format(dateTime);
      final timeStr = DateFormat('hh:mm a').format(dateTime);
      final markedAtStr = DateFormat('dd-MMM-yyyy hh:mm a').format(dateTime);
      
      final status = record.method.toLowerCase() != 'absent' ? 'Present' : 'Absent';
      
      sheet.appendRow([
        dateStr,
        dayStr,
        timeStr,
        className ?? 'N/A',
        subjectName ?? 'N/A',
        record.date, // Using date as session ID
        record.studentUUID,
        '', // Roll No
        student?.name ?? 'Unknown',
        status,
        record.method.toUpperCase(),
        markedAtStr,
        record.schoolID, // Using schoolID as device identifier
      ]);
      
      // Apply conditional formatting for status column
      final statusCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex));
      statusCell.cellStyle = status == 'Present' ? presentStyle : absentStyle;
      
      rowIndex++;
    }
  }

  /// Create Student List Sheet (Sheet 3)
  void _createStudentListSheet(
    Excel excel,
    List<Student>? studentsList,
  ) {
    final sheet = excel['Student List'];
    
    // Header style
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#E5E7EB',
      fontColorHex: '#000000',
      horizontalAlign: HorizontalAlign.Center,
    );

    // Headers
    final headers = [
      'Student ID',
      'Roll No',
      'Student Name',
      'Class',
      'Division / Batch',
      'UUID / BLE Identifier',
      'Registered Status',
    ];

    sheet.appendRow(headers);

    // Apply header style
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = headerStyle;
    }

    // Set column widths
    sheet.setColWidth(0, 20);
    sheet.setColWidth(1, 10);
    sheet.setColWidth(2, 25);
    sheet.setColWidth(3, 20);
    sheet.setColWidth(4, 20);
    sheet.setColWidth(5, 40);
    sheet.setColWidth(6, 20);

    if (studentsList != null && studentsList.isNotEmpty) {
      // Sort by UUID
      final sortedStudents = List<Student>.from(studentsList)..sort((a, b) => a.uuid.compareTo(b.uuid));
      
      for (final student in sortedStudents) {
        sheet.appendRow([
          student.uuid,
          '', // Roll No
          student.name,
          student.classId ?? 'N/A',
          '', // Division/Batch
          student.uuid, // BLE Identifier
          'Registered',
        ]);
      }
    }
  }

  /// Create Export Info Sheet (Sheet 4)
  void _createExportInfoSheet(
    Excel excel, {
    String? adminName,
    String? instituteName,
    String? className,
    String? subjectName,
    required String appVersion,
    required String deviceModel,
    required int recordCount,
    required List<AttendanceRecord> records,
  }) {
    final sheet = excel['Export Info'];
    
    // Key-value style
    final keyStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#F3F4F6',
    );

    final now = DateTime.now();
    final exportDateTime = DateFormat('dd-MMM-yyyy hh:mm a').format(now);
    
    // Find date range
    String dateRange = 'N/A';
    if (records.isNotEmpty) {
      final sortedRecords = List<AttendanceRecord>.from(records)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final startDate = DateTime.fromMillisecondsSinceEpoch(sortedRecords.first.timestamp);
      final endDate = DateTime.fromMillisecondsSinceEpoch(sortedRecords.last.timestamp);
      dateRange = '${DateFormat('dd-MMM-yyyy').format(startDate)} to ${DateFormat('dd-MMM-yyyy').format(endDate)}';
    }

    // Set column widths
    sheet.setColWidth(0, 30);
    sheet.setColWidth(1, 50);

    // Data rows
    final data = [
      ['Exported By', adminName ?? 'Admin'],
      ['Export Date & Time', exportDateTime],
      ['Institute / College', instituteName ?? 'N/A'],
      ['Class Filter', className ?? 'All Classes'],
      ['Subject Filter', subjectName ?? 'All Subjects'],
      ['Date Range', dateRange],
      ['Total Records', recordCount.toString()],
      ['Generated From App Version', appVersion],
      ['Generated On Device', deviceModel],
      ['Notes', 'Data exported from BLE Mark Admin – Smart Attendance System.'],
    ];

    int rowIndex = 0;
    for (final row in data) {
      sheet.appendRow([
        row[0],
        row[1],
      ]);
      
      // Apply key style to first column
      final keyCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      keyCell.cellStyle = keyStyle;
      
      // Alternate row shading
      if (rowIndex % 2 == 0) {
        final valueCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
        valueCell.cellStyle = CellStyle(backgroundColorHex: '#F9FAFB');
      }
      
      rowIndex++;
    }
  }
}

/// Result of export operation
class ExportResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final String? errorMessage;

  ExportResult({
    required this.success,
    this.filePath,
    this.fileName,
    this.errorMessage,
  });
} 