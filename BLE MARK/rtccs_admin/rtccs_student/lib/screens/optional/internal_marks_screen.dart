import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/optional/internal_marks_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/module_availability_service.dart';
import '../../services/module_error_handler.dart';

class InternalMarksScreen extends StatelessWidget {
  const InternalMarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final schoolId = profileProvider.student?.schoolId;

    return ModuleAvailabilityService.moduleGuard(
      moduleName: 'internalMark',
      schoolId: schoolId,
      child: const _InternalMarksContent(),
    );
  }
}

class _InternalMarksContent extends StatefulWidget {
  const _InternalMarksContent();

  @override
  State<_InternalMarksContent> createState() => _InternalMarksContentState();
}

class _InternalMarksContentState extends State<_InternalMarksContent> {
  bool _isLoading = true;
  bool _groupBySubject = true; // true = by subject, false = by component

  @override
  void initState() {
    super.initState();
    _loadMarks();
  }

  Future<void> _loadMarks({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final marksProvider = Provider.of<InternalMarksProvider>(context, listen: false);
    
    final student = profileProvider.student;
    if (student == null || student.schoolId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    await marksProvider.fetchMarks(
      schoolId: student.schoolId!,
      studentUUID: student.uuid,
      showLoading: showLoading,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadMarks(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F3A),
      appBar: AppBar(
        title: Text('Internal Marks', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          PopupMenuButton<bool>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _groupBySubject = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: true,
                child: Row(
                  children: [
                    Icon(
                      _groupBySubject ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Group by Subject'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: false,
                child: Row(
                  children: [
                    Icon(
                      !_groupBySubject ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Group by Component'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? ModuleErrorHandler.buildLoadingState(message: 'Loading internal marks...')
          : Consumer<InternalMarksProvider>(
              builder: (context, provider, child) {
                // Handle errors
                if (provider.error != null && provider.marks.isEmpty) {
                  final errorMsg = provider.error!;
                  if (errorMsg.contains('timeout') || errorMsg.contains('network')) {
                    return ModuleErrorHandler.buildErrorState(
                      moduleName: 'internalMark',
                      error: 'No internet connection and no marks data cached yet.',
                      onRetry: _loadMarks,
                    );
                  }
                  return ModuleErrorHandler.buildErrorState(
                    moduleName: 'internalMark',
                    error: provider.error!,
                    onRetry: _loadMarks,
                  );
                }

                // Handle empty state
                if (provider.marks.isEmpty) {
                  return ModuleErrorHandler.buildEmptyState(
                    moduleName: 'internalMark',
                    icon: Icons.assignment,
                    message: 'No Internal Marks Available',
                  );
                }

                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: Colors.white,
                  backgroundColor: Colors.blue.shade700,
                  child: CustomScrollView(
                    slivers: [
                      // Cache/offline indicator
                      if (provider.isFromCache || (provider.error != null && provider.marks.isNotEmpty))
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
                                    provider.error ?? 'Showing cached marks. Pull to refresh.',
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

                      // Overall summary
                      SliverToBoxAdapter(
                        child: _buildOverallSummary(provider),
                      ),

                      // Marks list
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _groupBySubject
                              ? _buildSubjectGroupedView(provider)
                              : _buildComponentGroupedView(provider),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildOverallSummary(InternalMarksProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
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
          Text(
            'Overall Performance',
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
              _buildSummaryItem(
                'Total Marks',
                '${provider.totalMarksObtained.toStringAsFixed(0)}/${provider.totalMaxMarks.toStringAsFixed(0)}',
                Icons.assessment,
              ),
              _buildSummaryItem(
                'Percentage',
                '${provider.overallPercentage.toStringAsFixed(1)}%',
                Icons.percent,
              ),
              _buildSummaryItem(
                'Subjects',
                provider.getMarksBySubject().length.toString(),
                Icons.book,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
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

  Widget _buildSubjectGroupedView(InternalMarksProvider provider) {
    final subjectMarks = provider.getMarksBySubject();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: subjectMarks.entries.map((entry) {
        final subjectData = entry.value;
        return _buildSubjectCard(subjectData);
      }).toList(),
    );
  }

  Widget _buildSubjectCard(SubjectInternalMarks subjectData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF242B3D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade700.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectData.subjectName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subjectData.subjectCode.isNotEmpty)
                        Text(
                          subjectData.subjectCode,
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
                    Text(
                      '${subjectData.totalMarksObtained.toStringAsFixed(0)}/${subjectData.totalMaxMarks.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${subjectData.percentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        color: _getPercentageColor(subjectData.percentage),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Component marks
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: subjectData.marks.map((mark) => _buildMarkRow(mark)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentGroupedView(InternalMarksProvider provider) {
    final componentMarks = provider.getMarksByComponent();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: componentMarks.entries.map((entry) {
        return _buildComponentSection(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildComponentSection(String component, List<InternalMarkEntry> marks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            component,
            style: GoogleFonts.poppins(
              color: Colors.blue.shade300,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...marks.map((mark) => _buildMarkCard(mark)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMarkCard(InternalMarkEntry mark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF242B3D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildMarkRow(mark),
      ),
    );
  }

  Widget _buildMarkRow(InternalMarkEntry mark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mark.examComponent,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade300,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (mark.weightage != null)
                  Text(
                    'Weightage: ${mark.weightage}%',
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
              Text(
                '${mark.marksObtained.toStringAsFixed(0)}/${mark.maxMarks.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${mark.percentage.toStringAsFixed(1)}%',
                style: GoogleFonts.poppins(
                  color: _getPercentageColor(mark.percentage),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 75) return Colors.green.shade400;
    if (percentage >= 60) return Colors.blue.shade400;
    if (percentage >= 50) return Colors.orange.shade400;
    if (percentage >= 40) return Colors.orange.shade600;
    return Colors.red.shade400;
  }
}
