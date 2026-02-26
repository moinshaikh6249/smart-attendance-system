import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/optional/results_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/module_availability_service.dart';
import '../../services/module_error_handler.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final schoolId = profileProvider.student?.schoolId;

    return ModuleAvailabilityService.moduleGuard(
      moduleName: 'result',
      schoolId: schoolId,
      child: const _ResultsContent(),
    );
  }
}

class _ResultsContent extends StatefulWidget {
  const _ResultsContent();

  @override
  State<_ResultsContent> createState() => _ResultsContentState();
}

class _ResultsContentState extends State<_ResultsContent> {
  bool _isLoading = true;
  String? _selectedSemester;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final resultsProvider = Provider.of<ResultsProvider>(context, listen: false);
    
    final student = profileProvider.student;
    if (student == null || student.schoolId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    await resultsProvider.fetchResults(
      schoolId: student.schoolId!,
      classId: student.classId ?? '',
      studentUUID: student.uuid,
      showLoading: showLoading,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadResults(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F3A),
      appBar: AppBar(
        title: Text('Results', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: _isLoading
          ? ModuleErrorHandler.buildLoadingState(message: 'Loading results...')
          : Consumer<ResultsProvider>(
              builder: (context, provider, child) {
                // Handle errors
                if (provider.error != null && provider.results.isEmpty) {
                  final errorMsg = provider.error!;
                  if (errorMsg.contains('timeout') || errorMsg.contains('network')) {
                    return ModuleErrorHandler.buildErrorState(
                      moduleName: 'result',
                      error: 'No internet connection and no results cached yet.',
                      onRetry: _loadResults,
                    );
                  }
                  return ModuleErrorHandler.buildErrorState(
                    moduleName: 'result',
                    error: provider.error!,
                    onRetry: _loadResults,
                  );
                }

                // Handle empty state
                if (provider.results.isEmpty) {
                  return ModuleErrorHandler.buildEmptyState(
                    moduleName: 'result',
                    icon: Icons.grade,
                    message: 'No Results Available',
                  );
                }

                final publishedResults = provider.publishedResults;
                
                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: Colors.white,
                  backgroundColor: Colors.blue.shade700,
                  child: CustomScrollView(
                    slivers: [
                      // Cache/offline indicator
                      if (provider.isFromCache || (provider.error != null && provider.results.isNotEmpty))
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
                                    provider.error ?? 'Showing cached results. Pull to refresh.',
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

                      // CGPA Summary (if available)
                      if (publishedResults.isNotEmpty && publishedResults.last.cgpa != null)
                        SliverToBoxAdapter(
                          child: _buildCGPASummary(publishedResults.last),
                        ),

                      // Results list
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: publishedResults.isEmpty
                            ? SliverToBoxAdapter(
                                child: _buildNoPublishedResults(),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final result = publishedResults[index];
                                    return _buildResultCard(result);
                                  },
                                  childCount: publishedResults.length,
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

  Widget _buildCGPASummary(ExamResult latestResult) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.purple.shade900],
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
          Text(
            'Academic Performance',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (latestResult.cgpa != null)
                _buildPerformanceItem('CGPA', latestResult.cgpa!.toStringAsFixed(2), Icons.school),
              if (latestResult.totalCreditsEarned != null)
                _buildPerformanceItem('Credits', latestResult.totalCreditsEarned.toString(), Icons.workspace_premium),
              if (latestResult.sgpa != null)
                _buildPerformanceItem('Latest SGPA', latestResult.sgpa!.toStringAsFixed(2), Icons.trending_up),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildNoPublishedResults() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF242B3D),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.schedule,
              size: 64,
              color: Colors.orange.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Results Not Published Yet',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your exam results are being processed and will be published soon.',
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

  Widget _buildResultCard(ExamResult result) {
    final isExpanded = _selectedSemester == result.examName;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF242B3D),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _selectedSemester = isExpanded ? null : result.examName;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.examName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (result.semesterCode != null)
                          Text(
                            'Semester: ${result.semesterCode}',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        if (result.academicYear != null)
                          Text(
                            'AY: ${result.academicYear}',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (result.sgpa != null)
                        Text(
                          'SGPA: ${result.sgpa!.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            color: _getSGPAColor(result.sgpa!),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (result.totalCreditsEarned != null)
                        Text(
                          '${result.totalCreditsEarned} Credits',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(color: Colors.grey, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatChip(
                        'Passed',
                        result.passedSubjects.toString(),
                        Colors.green.shade700,
                        Icons.check_circle,
                      ),
                      _buildStatChip(
                        'Failed',
                        result.failedSubjects.toString(),
                        Colors.red.shade700,
                        Icons.cancel,
                      ),
                      _buildStatChip(
                        'Total',
                        result.subjects.length.toString(),
                        Colors.blue.shade700,
                        Icons.subject,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Subject results
                  Text(
                    'Subject-wise Results',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...result.subjects.entries.map((entry) => _buildSubjectRow(entry.value)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectRow(SubjectResult subject) {
    final isPassed = subject.resultStatus?.toUpperCase() == 'PASS';
    final isAbsent = subject.resultStatus?.toUpperCase() == 'ABSENT';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAbsent
              ? Colors.orange.shade700.withOpacity(0.3)
              : isPassed
                  ? Colors.green.shade700.withOpacity(0.3)
                  : Colors.red.shade700.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.subjectName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subject.subjectCode != null)
                  Text(
                    subject.subjectCode!,
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  if (subject.credits != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${subject.credits} Cr',
                        style: GoogleFonts.poppins(
                          color: Colors.blue.shade300,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    subject.grade,
                    style: GoogleFonts.poppins(
                      color: _getGradeColor(subject.grade),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (subject.gradePoints != null)
                Text(
                  'GP: ${subject.gradePoints!.toStringAsFixed(1)}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                  ),
                ),
              if (subject.resultStatus != null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isAbsent
                        ? Colors.orange.shade900.withOpacity(0.3)
                        : isPassed
                            ? Colors.green.shade900.withOpacity(0.3)
                            : Colors.red.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    subject.resultStatus!,
                    style: GoogleFonts.poppins(
                      color: isAbsent
                          ? Colors.orange.shade300
                          : isPassed
                              ? Colors.green.shade300
                              : Colors.red.shade300,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSGPAColor(double sgpa) {
    if (sgpa >= 8.5) return Colors.green.shade400;
    if (sgpa >= 7.0) return Colors.blue.shade400;
    if (sgpa >= 6.0) return Colors.orange.shade400;
    if (sgpa >= 5.0) return Colors.orange.shade600;
    return Colors.red.shade400;
  }

  Color _getGradeColor(String grade) {
    final upperGrade = grade.toUpperCase();
    if (upperGrade == 'A+' || upperGrade == 'O') return Colors.green.shade400;
    if (upperGrade == 'A' || upperGrade == 'A-') return Colors.blue.shade400;
    if (upperGrade.startsWith('B')) return Colors.orange.shade400;
    if (upperGrade.startsWith('C')) return Colors.orange.shade600;
    return Colors.red.shade400;
  }
}
