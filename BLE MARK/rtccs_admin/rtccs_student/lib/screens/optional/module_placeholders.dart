import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Generic placeholder screen for optional modules
class ModulePlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;
  final String? description;

  const ModulePlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F3A),
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 100, color: Colors.grey.shade600),
              const SizedBox(height: 32),
              Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (description != null) ...[
                const SizedBox(height: 16),
                Text(
                  description!,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Specific placeholder screens
class HostelAttendanceScreen extends StatelessWidget {
  const HostelAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderScreen(
      title: 'Hostel Attendance',
      icon: Icons.hotel,
      message: 'Hostel Attendance',
      description: 'View your hostel attendance records and late entry logs',
    );
  }
}

class ITLEScreen extends StatelessWidget {
  const ITLEScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderScreen(
      title: 'ITLE / LMS',
      icon: Icons.school,
      message: 'Learning Management System',
      description: 'Access online study materials, assignments, and e-learning resources',
    );
  }
}

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderScreen(
      title: 'Certificates',
      icon: Icons.card_membership,
      message: 'Certificates',
      description: 'Download bonafide, transfer certificate, and other academic certificates',
    );
  }
}

class HallTicketScreen extends StatelessWidget {
  const HallTicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderScreen(
      title: 'Hall Ticket',
      icon: Icons.confirmation_number,
      message: 'Exam Hall Ticket',
      description: 'View and download your examination hall ticket / admit card',
    );
  }
}

class ExamTimeTableScreen extends StatelessWidget {
  const ExamTimeTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderScreen(
      title: 'Exam Time Table',
      icon: Icons.event_note,
      message: 'Examination Schedule',
      description: 'View upcoming examination dates, timings, and venue details',
    );
  }
}

class RegisterSubjectScreen extends StatelessWidget {
  const RegisterSubjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderScreen(
      title: 'Register Subject',
      icon: Icons.app_registration,
      message: 'Subject Registration',
      description: 'Register for subjects and view your current semester enrollments',
    );
  }
}

class InternalMarkScreen extends StatelessWidget {
  const InternalMarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderScreen(
      title: 'Internal Marks',
      icon: Icons.assignment,
      message: 'Internal Assessment Marks',
      description: 'View your continuous assessment and internal examination marks',
    );
  }
}

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderScreen(
      title: 'Results',
      icon: Icons.assessment,
      message: 'Examination Results',
      description: 'View your semester results, grades, and academic performance',
    );
  }
}

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderScreen(
      title: 'Academic Calendar',
      icon: Icons.calendar_month,
      message: 'Academic Calendar',
      description: 'View academic calendar including holidays, events, and important dates',
    );
  }
}

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderScreen(
      title: 'Feedback',
      icon: Icons.feedback,
      message: 'Student Feedback',
      description: 'Share your feedback, suggestions, or concerns with the administration',
    );
  }
}
