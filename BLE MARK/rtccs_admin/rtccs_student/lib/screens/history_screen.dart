import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/profile_provider.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final student = profileProvider.student;
    final logs = attendanceProvider.attendance;

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance History')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        itemBuilder: (context, i) {
          final record = logs[i];
          return Card(
            child: ListTile(
              leading: Icon(record.method == 'BLE' ? Icons.bluetooth : Icons.qr_code),
              title: Text('Subject: ${record.subjectID}'),
              subtitle: Text('Date: ${record.date}\nMethod: ${record.method}'),
              trailing: Text(DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(record.timestamp))),
            ),
          );
        },
      ),
    );
  }
} 