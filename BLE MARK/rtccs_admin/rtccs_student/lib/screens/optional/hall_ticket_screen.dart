import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../providers/optional/hall_ticket_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/module_availability_service.dart';
import '../../services/module_error_handler.dart';

class HallTicketScreen extends StatelessWidget {
  const HallTicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final schoolId = profileProvider.student?.schoolId;

    return ModuleAvailabilityService.moduleGuard(
      moduleName: 'hallTicket',
      schoolId: schoolId,
      child: const _HallTicketContent(),
    );
  }
}

class _HallTicketContent extends StatefulWidget {
  const _HallTicketContent();

  @override
  State<_HallTicketContent> createState() => _HallTicketContentState();
}

class _HallTicketContentState extends State<_HallTicketContent> {
  bool _isLoading = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadHallTicket();
  }

  Future<void> _loadHallTicket({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final hallTicketProvider = Provider.of<HallTicketProvider>(context, listen: false);

    final student = profileProvider.student;
    if (student == null || student.schoolId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    await hallTicketProvider.fetchHallTicket(
      schoolId: student.schoolId!,
      studentUUID: student.uuid,
      showLoading: showLoading,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadHallTicket(showLoading: false);
  }

  Future<void> _handleDownload(String url) async {
    setState(() => _isDownloading = true);

    try {
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          _showError('Unable to open hall ticket. Please try again later.');
        }
      }
    } catch (e) {
      debugPrint('Error opening hall ticket: $e');
      if (mounted) {
        _showError('Failed to open hall ticket: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F3A),
      appBar: AppBar(
        title: Text('Hall Ticket', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: _isLoading
          ? ModuleErrorHandler.buildLoadingState(message: 'Loading hall ticket...')
          : Consumer<HallTicketProvider>(
              builder: (context, provider, child) {
                // Handle errors
                if (provider.error != null && !provider.hasHallTicket) {
                  final errorMsg = provider.error!;
                  if (errorMsg.contains('timeout') || errorMsg.contains('network')) {
                    return ModuleErrorHandler.buildErrorState(
                      moduleName: 'hallTicket',
                      error: 'Unable to load hall ticket. Please try again later.',
                      onRetry: _loadHallTicket,
                    );
                  }
                  return ModuleErrorHandler.buildErrorState(
                    moduleName: 'hallTicket',
                    error: provider.error!,
                    onRetry: _loadHallTicket,
                  );
                }

                // Handle hall ticket not available
                if (!provider.hasHallTicket) {
                  return _buildNotReleasedState();
                }

                final hallTicket = provider.hallTicket!;

                // Handle not released yet
                if (!hallTicket.isReleased) {
                  return _buildNotReleasedState();
                }

                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: Colors.white,
                  backgroundColor: Colors.blue.shade700,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Cache/offline indicator
                        if (provider.isFromCache || (provider.error != null && provider.hasHallTicket))
                          Container(
                            color: Colors.orange.shade900.withOpacity(0.3),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.wifi_off, size: 16, color: Colors.orange.shade300),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    provider.error ?? 'Showing cached hall ticket. Pull to refresh.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.orange.shade200,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Header card
                              _buildHeaderCard(hallTicket),
                              const SizedBox(height: 16),

                              // Student details
                              _buildDetailsCard(hallTicket),
                              const SizedBox(height: 16),

                              // Exam details
                              _buildExamDetailsCard(hallTicket),
                              const SizedBox(height: 16),

                              // Download button
                              if (hallTicket.hasDownloadableContent)
                                _buildDownloadButton(hallTicket, provider),
                              
                              // Cached PDF info
                              if (provider.cachedPdfPath != null) ...[
                                const SizedBox(height: 16),
                                _buildCachedInfo(),
                              ],

                              const SizedBox(height: 24),
                              
                              // Instructions
                              _buildInstructions(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildNotReleasedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: const Color(0xFF242B3D),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 80,
                  color: Colors.orange.shade300,
                ),
                const SizedBox(height: 24),
                Text(
                  'Hall Ticket Not Yet Released',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your examination hall ticket / admit card has not been released yet. Please check again later.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _handleRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(HallTicket hallTicket) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.confirmation_number, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(
            'HALL TICKET',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hallTicket.examName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(HallTicket hallTicket) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF242B3D),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Details',
              style: GoogleFonts.poppins(
                color: Colors.blue.shade300,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Name', hallTicket.studentName, Icons.person),
            _buildDetailRow('Enrollment No.', hallTicket.enrollmentNo, Icons.badge),
            if (hallTicket.prn != null)
              _buildDetailRow('PRN', hallTicket.prn!, Icons.fingerprint),
            _buildDetailRow('Seat Number', hallTicket.seatNumber, Icons.event_seat),
            _buildDetailRow('Program', hallTicket.program, Icons.school),
            _buildDetailRow('Semester', hallTicket.semester, Icons.class_),
          ],
        ),
      ),
    );
  }

  Widget _buildExamDetailsCard(HallTicket hallTicket) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF242B3D),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exam Details',
              style: GoogleFonts.poppins(
                color: Colors.blue.shade300,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Exam Name', hallTicket.examName, Icons.description),
            _buildDetailRow('Exam Center', hallTicket.examCenterName, Icons.location_on),
            if (hallTicket.centerCode != null)
              _buildDetailRow('Center Code', hallTicket.centerCode!, Icons.qr_code),
            _buildDetailRow('Exam Dates', hallTicket.formattedExamDates, Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(HallTicket hallTicket, HallTicketProvider provider) {
    final url = hallTicket.pdfUrl ?? hallTicket.imageUrl;
    if (url == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isDownloading ? null : () => _handleDownload(url),
        icon: _isDownloading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.download),
        label: Text(
          _isDownloading ? 'Opening...' : 'View / Download Hall Ticket',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildCachedInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade900.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade700.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hall ticket is available offline',
              style: GoogleFonts.poppins(
                color: Colors.green.shade300,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF242B3D),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade300, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Important Instructions',
                  style: GoogleFonts.poppins(
                    color: Colors.blue.shade300,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstructionPoint('Carry a printed copy of this hall ticket to the examination center.'),
            _buildInstructionPoint('Bring a valid photo ID (College ID / Aadhaar / Passport).'),
            _buildInstructionPoint('Report to the exam center at least 30 minutes before the exam starts.'),
            _buildInstructionPoint('Mobile phones and electronic devices are not allowed in the exam hall.'),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade400,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
