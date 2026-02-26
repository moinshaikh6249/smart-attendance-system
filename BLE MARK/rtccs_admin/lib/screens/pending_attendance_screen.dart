import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import '../providers/school_provider.dart';
import '../models/pending_attendance_request.dart';
import 'package:intl/intl.dart';

class PendingAttendanceScreen extends StatefulWidget {
  const PendingAttendanceScreen({super.key});

  @override
  State<PendingAttendanceScreen> createState() => _PendingAttendanceScreenState();
}

class _PendingAttendanceScreenState extends State<PendingAttendanceScreen> {
  late FirebaseService _firebaseService;
  List<PendingAttendanceRequest> _pendingRequests = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseService();
    _loadPendingRequests();
    _startRealtimeUpdates();
  }

  Future<void> _loadPendingRequests() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) {
      setState(() {
        _error = 'Please log in first.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final requests = await _firebaseService.getPendingAttendanceRequests(user.uid);
      setState(() {
        _pendingRequests = requests;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading requests: $e';
        _loading = false;
      });
    }
  }

  void _startRealtimeUpdates() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) return;

    // Listen to real-time updates
    _firebaseService.watchPendingAttendanceRequests(user.uid).listen((requests) {
      if (mounted) {
        setState(() {
          _pendingRequests = requests;
        });
      }
    });
  }

  Future<void> _approveRequest(PendingAttendanceRequest request) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) return;

    try {
      await _firebaseService.approveAttendanceRequest(
        teacherId: user.uid,
        requestId: request.requestId,
        request: request,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approved attendance for ${request.studentName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(PendingAttendanceRequest request) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) return;

    try {
      await _firebaseService.rejectAttendanceRequest(
        teacherId: user.uid,
        requestId: request.requestId,
        studentUUID: request.studentUUID,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rejected attendance request from ${request.studentName}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveAllForCurrentSession() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final schoolProvider = Provider.of<SchoolProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) return;

    final school = schoolProvider.selectedSchool;
    final classroom = schoolProvider.selectedClass;
    final subject = schoolProvider.selectedSubject;

    if (school == null || classroom == null || subject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select school, class, and subject first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve All'),
        content: Text(
          'Approve all pending attendance requests for ${classroom.name} - ${subject.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Approve All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final count = await _firebaseService.approveAllPendingRequests(
        teacherId: user.uid,
        schoolID: school.id,
        classID: classroom.id,
        subjectID: subject.id,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approved $count attendance request(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolProvider = Provider.of<SchoolProvider>(context);
    final school = schoolProvider.selectedSchool;
    final classroom = schoolProvider.selectedClass;
    final subject = schoolProvider.selectedSubject;

    // Filter requests for current session
    final currentSessionRequests = _pendingRequests.where((req) {
      if (school == null || classroom == null || subject == null) return false;
      return req.schoolID == school.id &&
          req.classID == classroom.id &&
          req.subjectID == subject.id &&
          req.date == DateFormat('yyyy-MM-dd').format(DateTime.now());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Attendance'),
        actions: [
          if (currentSessionRequests.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Approve All',
              onPressed: _approveAllForCurrentSession,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : currentSessionRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No pending requests',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          if (school == null || classroom == null || subject == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Select school, class, and subject to see requests',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPendingRequests,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: currentSessionRequests.length,
                        itemBuilder: (context, index) {
                          final request = currentSessionRequests[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(request.studentName[0].toUpperCase()),
                              ),
                              title: Text(
                                request.studentName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('UUID: ${request.studentUUID}'),
                                  Text(
                                    'Detected: ${DateFormat('HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(request.timestamp))}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    tooltip: 'Approve',
                                    onPressed: () => _approveRequest(request),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    tooltip: 'Reject',
                                    onPressed: () => _rejectRequest(request),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

