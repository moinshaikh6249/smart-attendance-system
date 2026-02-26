import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/optional/exam_timetable_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/module_availability_service.dart';
import '../../services/module_error_handler.dart';

class ExamTimetableScreen extends StatelessWidget {
  const ExamTimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final schoolId = profileProvider.student?.schoolId;

    return ModuleAvailabilityService.moduleGuard(
      moduleName: 'examTimetable',
      schoolId: schoolId,
      child: const _ExamTimetableContent(),
    );
  }
}

class _ExamTimetableContent extends StatefulWidget {
  const _ExamTimetableContent();

  @override
  State<_ExamTimetableContent> createState() => _ExamTimetableContentState();
}

class _ExamTimetableContentState extends State<_ExamTimetableContent> {
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, upcoming, theory, practical, viva
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final timetableProvider = Provider.of<ExamTimetableProvider>(context, listen: false);

    final student = profileProvider.student;
    if (student == null || student.schoolId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    await timetableProvider.fetchExamTimetable(
      schoolId: student.schoolId!,
      studentUUID: student.uuid,
      program: student.program,
      semester: student.semester,
      showLoading: showLoading,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadTimetable(showLoading: false);
  }

  List<ExamEntry> _getFilteredExams(ExamTimetableProvider provider) {
    List<ExamEntry> exams = provider.exams;

    // Apply filter
    switch (_selectedFilter) {
      case 'upcoming':
        exams = provider.upcomingExams;
        break;
      case 'theory':
      case 'practical':
      case 'viva':
        exams = provider.getExamsByType(_selectedFilter);
        break;
      default:
        exams = provider.exams;
    }

    // Apply date range if set
    if (_startDate != null && _endDate != null) {
      exams = exams.where((e) {
        return e.examDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
            e.examDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    return exams;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F3A),
      appBar: AppBar(
        title: Text('Exam Timetable', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              _buildFilterMenuItem('All Exams', 'all'),
              _buildFilterMenuItem('Upcoming Only', 'upcoming'),
              const PopupMenuDivider(),
              _buildFilterMenuItem('Theory', 'theory'),
              _buildFilterMenuItem('Practical', 'practical'),
              _buildFilterMenuItem('Viva', 'viva'),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? ModuleErrorHandler.buildLoadingState(message: 'Loading exam timetable...')
          : Consumer<ExamTimetableProvider>(
              builder: (context, provider, child) {
                // Handle errors
                if (provider.error != null && provider.exams.isEmpty) {
                  final errorMsg = provider.error!;
                  if (errorMsg.contains('timeout') || errorMsg.contains('network')) {
                    return ModuleErrorHandler.buildErrorState(
                      moduleName: 'examTimetable',
                      error: 'Unable to load exam timetable. Please try again later.',
                      onRetry: _loadTimetable,
                    );
                  }
                  return ModuleErrorHandler.buildErrorState(
                    moduleName: 'examTimetable',
                    error: provider.error!,
                    onRetry: _loadTimetable,
                  );
                }

                // Handle empty state
                if (provider.exams.isEmpty) {
                  return ModuleErrorHandler.buildEmptyState(
                    moduleName: 'examTimetable',
                    icon: Icons.event_note,
                    message: 'No exam timetable available right now.',
                  );
                }

                final filteredExams = _getFilteredExams(provider);

                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: Colors.white,
                  backgroundColor: Colors.blue.shade700,
                  child: CustomScrollView(
                    slivers: [
                      // Cache/offline indicator
                      if (provider.isFromCache || (provider.error != null && provider.exams.isNotEmpty))
                        SliverToBoxAdapter(
                          child: Container(
                            color: Colors.orange.shade900.withOpacity(0.3),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.wifi_off, size: 16, color: Colors.orange.shade300),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    provider.error ?? 'Showing cached timetable. Pull to refresh.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.orange.shade200,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Next exam summary
                      if (provider.nextExam != null && _selectedFilter == 'all')
                        SliverToBoxAdapter(
                          child: _buildNextExamCard(provider.nextExam!),
                        ),

                      // Active filter indicator
                      if (_selectedFilter != 'all')
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade700.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.filter_alt, color: Colors.blue.shade300, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Filter: ${_getFilterLabel(_selectedFilter)} (${filteredExams.length})',
                                  style: GoogleFonts.poppins(
                                    color: Colors.blue.shade200,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => setState(() => _selectedFilter = 'all'),
                                  child: Icon(Icons.close, color: Colors.blue.shade300, size: 20),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Exam list
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: filteredExams.isEmpty
                            ? SliverToBoxAdapter(
                                child: _buildNoExamsForFilter(),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final exam = filteredExams[index];
                                    final showDateHeader = index == 0 ||
                                        !_isSameDay(filteredExams[index - 1].examDate, exam.examDate);
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (showDateHeader) _buildDateHeader(exam.examDate),
                                        _buildExamCard(exam),
                                      ],
                                    );
                                  },
                                  childCount: filteredExams.length,
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  PopupMenuItem<String> _buildFilterMenuItem(String label, String value) {
    final isSelected = _selectedFilter == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            size: 20,
            color: isSelected ? Colors.blue : null,
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isSelected ? Colors.blue : null)),
        ],
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'upcoming':
        return 'Upcoming Only';
      case 'theory':
        return 'Theory';
      case 'practical':
        return 'Practical';
      case 'viva':
        return 'Viva';
      default:
        return 'All Exams';
    }
  }

  Widget _buildNextExamCard(ExamEntry exam) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade900],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upcoming, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                'Next Exam',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            exam.subjectName,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, MMM dd, yyyy').format(exam.examDate),
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                '${exam.startTime} - ${exam.endTime}',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final isToday = _isSameDay(date, DateTime.now());
    final isTomorrow = _isSameDay(date, DateTime.now().add(const Duration(days: 1)));

    String label;
    if (isToday) {
      label = 'Today';
    } else if (isTomorrow) {
      label = 'Tomorrow';
    } else {
      label = DateFormat('EEEE, MMMM dd, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.blue.shade300,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildExamCard(ExamEntry exam) {
    final isUpcoming = exam.isUpcoming;
    final borderColor = isUpcoming ? Colors.blue.shade700 : Colors.grey.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF242B3D),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject name and type badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exam.subjectName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildTypeBadge(exam.examType),
                ],
              ),
              if (exam.subjectCode.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  exam.subjectCode,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              
              // Exam name
              Text(
                exam.examName,
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade300,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),

              // Time
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.blue.shade300, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${exam.startTime} - ${exam.endTime}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Room/Center (if available)
              if (exam.roomOrCenter != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.orange.shade300, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        exam.roomOrCenter!,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade300,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Seat number (if available)
              if (exam.seatNumber != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.event_seat, color: Colors.green.shade300, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Seat: ${exam.seatNumber}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade300,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color color;
    IconData icon;

    switch (type.toLowerCase()) {
      case 'practical':
        color = Colors.orange.shade700;
        icon = Icons.science;
        break;
      case 'viva':
        color = Colors.purple.shade700;
        icon = Icons.mic;
        break;
      default: // Theory
        color = Colors.blue.shade700;
        icon = Icons.menu_book;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            type,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoExamsForFilter() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF242B3D),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.filter_alt_off,
              size: 64,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'No exams match this filter',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different filter option.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
