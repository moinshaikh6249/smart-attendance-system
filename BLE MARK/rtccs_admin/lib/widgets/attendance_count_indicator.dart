import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';

class AttendanceCountIndicator extends StatelessWidget {
  const AttendanceCountIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final count = context.watch<AttendanceProvider>().liveCount;
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Live Attendance Count', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('$count', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
} 