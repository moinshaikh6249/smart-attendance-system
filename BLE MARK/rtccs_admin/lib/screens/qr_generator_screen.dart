import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../providers/school_provider.dart';
import '../services/firebase_service.dart';
import '../theme.dart';
import '../utils/ui_helpers.dart';

class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> with UIHelpers, SingleTickerProviderStateMixin {
  final FirebaseService _firebase = FirebaseService();
  final Uuid _uuid = const Uuid();
  Timer? _timer;
  Timer? _countdownTimer;
  String? _currentToken;
  String? _currentQrPayload;
  int _ttlSeconds = 30;
  int _countdown = 30;
  DateTime? _expiresAt;
  bool _active = false;
  String? _error;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    final schoolProvider = context.read<SchoolProvider>();
    final school = schoolProvider.selectedSchool;
    final classroom = schoolProvider.selectedClass;
    final subject = schoolProvider.selectedSubject;
    if (school == null || classroom == null || subject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select school, class, and subject first.'),
          backgroundColor: kChartOrange,
        ),
      );
      Navigator.of(context).pop();
      return;
    }
    try {
      setState(() {
        _active = true;
        _error = null;
      });
      await _rotateToken(initial: true);
      if (!mounted) return;
      _timer = Timer.periodic(Duration(seconds: _ttlSeconds), (_) => _rotateToken());
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _countdown = _expiresAt == null
                ? 0
                : _expiresAt!.difference(DateTime.now()).inSeconds.clamp(0, _ttlSeconds);
          });
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _active = false;
      });
    }
  }

  Future<void> _rotateToken({bool initial = false}) async {
    final schoolProvider = context.read<SchoolProvider>();
    final school = schoolProvider.selectedSchool!;
    final classroom = schoolProvider.selectedClass!;
    final subject = schoolProvider.selectedSubject!;

    final token = _uuid.v4();
    final expiresAt = DateTime.now().add(Duration(seconds: _ttlSeconds));
    final expiresAtMs = expiresAt.millisecondsSinceEpoch;
    try {
      if (initial) {
        await _firebase.startAttendanceSession(
          schoolId: school.id,
          classId: classroom.id,
          subjectId: subject.id,
          token: token,
          expiresAtMs: expiresAtMs,
        );
      } else {
        await _firebase.updateAttendanceSessionToken(
          schoolId: school.id,
          classId: classroom.id,
          subjectId: subject.id,
          token: token,
          expiresAtMs: expiresAtMs,
        );
      }
      if (!mounted) return;
      setState(() {
        _currentToken = token;
        _expiresAt = expiresAt;
        _countdown = _ttlSeconds;
        _error = null;
        // Encode context into QR payload so student app can validate without guesswork
        _currentQrPayload =
            '{"t":"$token","s":"${school.id}","c":"${classroom.id}","sub":"${subject.id}","e":$expiresAtMs}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _endSession() async {
    final schoolProvider = context.read<SchoolProvider>();
    final school = schoolProvider.selectedSchool!;
    final classroom = schoolProvider.selectedClass!;
    final subject = schoolProvider.selectedSubject!;
    await _firebase.endAttendanceSession(
      schoolId: school.id,
      classId: classroom.id,
      subjectId: subject.id,
    );
    _timer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _active = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final schoolProvider = context.watch<SchoolProvider>();
    final school = schoolProvider.selectedSchool;
    final classroom = schoolProvider.selectedClass;
    final subject = schoolProvider.selectedSubject;

    return Container(
      decoration: const BoxDecoration(gradient: kPrimaryGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Live QR Attendance'),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kHeaderNavy, kHeaderNavy.withOpacity(0.8)],
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Session Info Card
              StyledCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: kGradientBottom, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Session Info',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('School', school?.name ?? 'N/A', Icons.school),
                    const SizedBox(height: 8),
                    _buildInfoRow('Class', classroom?.name ?? 'N/A', Icons.class_),
                    const SizedBox(height: 8),
                    _buildInfoRow('Subject', subject?.name ?? 'N/A', Icons.book),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Error Message
              if (_error != null) ...[
                buildErrorMessage(_error!),
                const SizedBox(height: 20),
              ],

              // QR Code Card
              StyledCard(
                child: Column(
                  children: [
                    if (_currentQrPayload != null) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kWhiteText,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: _currentQrPayload!,
                          version: QrVersions.auto,
                          size: 280.0,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: kHeaderNavy,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: kHeaderNavy,
                          ),
                        ),
                      ),
                    ] else
                      const SizedBox(
                        height: 320.0,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(kGradientBottom),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Countdown Card
              StyledCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        RotationTransition(
                          turns: _rotateController,
                          child: const Icon(Icons.refresh, color: kGradientBottom, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Auto-Rotation',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Rotates every $_ttlSeconds seconds',
                      style: TextStyle(
                        color: kWhiteText.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer, color: kChartOrange, size: 32),
                        const SizedBox(width: 12),
                        Text(
                          '$_countdown',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: _countdown < 10 ? kChartOrange : kGradientBottom,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'seconds left',
                          style: TextStyle(
                            color: kWhiteText.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _countdown / _ttlSeconds,
                        backgroundColor: kWhiteText.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _countdown < 10 ? kChartOrange : kGradientBottom,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // End Session Button
              StyledButton(
                text: 'End Session',
                icon: Icons.stop_circle,
                onPressed: _active ? _endSession : null,
              ),
              const SizedBox(height: 16),

              // Instructions Card
              StyledCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: kGradientBottom, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'How it works',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInstruction('QR code refreshes automatically for security'),
                    _buildInstruction('Students scan the QR to mark attendance'),
                    _buildInstruction('Each code is valid for $_ttlSeconds seconds only'),
                    _buildInstruction('Keep this screen open during the session'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: kGradientBottom, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: kWhiteText.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: kWhiteText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              color: kGradientBottom,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: kWhiteText.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


