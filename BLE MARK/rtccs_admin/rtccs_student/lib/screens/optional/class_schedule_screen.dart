import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/optional/schedule_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/module_availability_service.dart';
import '../../services/module_error_handler.dart';

class ClassScheduleScreen extends StatelessWidget {
  const ClassScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final schoolId = profileProvider.student?.schoolId;

    return ModuleAvailabilityService.moduleGuard(
      moduleName: 'classSchedule',
      schoolId: schoolId,
      child: const _ClassScheduleContent(),
    );
  }
}

class _ClassScheduleContent extends StatefulWidget {
  const _ClassScheduleContent();

  @override
  State<_ClassScheduleContent> createState() => _ClassScheduleContentState();
}

class _ClassScheduleContentState extends State<_ClassScheduleContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _showTodaySection = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    
    // Set initial tab to today
    final today = DateTime.now().weekday - 1; // Monday = 0
    _tabController.index = today < 7 ? today : 0;
    
    _loadSchedule();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    
    final student = profileProvider.student;
    if (student == null || student.schoolId == null || student.classId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    await scheduleProvider.fetchSchedule(
      schoolId: student.schoolId!,
      classId: student.classId!,
      showLoading: showLoading,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadSchedule(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F3A),
      appBar: AppBar(
        title: Text('Class Schedule', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: _isLoading
          ? ModuleErrorHandler.buildLoadingState(message: 'Loading schedule...')
          : Consumer<ScheduleProvider>(
              builder: (context, provider, child) {
                // Handle no internet and no cache
                if (provider.error != null && provider.schedule.isEmpty) {
                  final errorMsg = provider.error!;
                  if (errorMsg.contains('timeout') || errorMsg.contains('network')) {
                    return ModuleErrorHandler.buildErrorState(
                      moduleName: 'classSchedule',
                      error: 'No internet connection and no timetable data cached yet.',
                      onRetry: _loadSchedule,
                    );
                  }
                  return ModuleErrorHandler.buildErrorState(
                    moduleName: 'classSchedule',
                    error: provider.error!,
                    onRetry: _loadSchedule,
                  );
                }

                if (provider.schedule.isEmpty) {
                  return ModuleErrorHandler.buildEmptyState(
                    moduleName: 'classSchedule',
                    icon: Icons.calendar_today,
                    message: 'No Schedule Available',
                  );
                }

                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: Colors.white,
                  backgroundColor: Colors.blue.shade700,
                  child: CustomScrollView(
                    slivers: [
                      // Cache/offline indicator
                      if (provider.isFromCache || (provider.error != null && provider.schedule.isNotEmpty))
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
                                if (provider.lastUpdated != null)
                                  Text(
                                    'Updated: ${DateFormat('MMM dd, hh:mm a').format(provider.lastUpdated!)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.orange.shade300,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                      // Today's Schedule Section
                      SliverToBoxAdapter(
                        child: _buildTodaySection(provider),
                      ),

                      // Week View Tabs
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.blue.shade700,
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            indicatorColor: Colors.white,
                            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
                            tabs: const [
                              Tab(text: 'Mon'),
                              Tab(text: 'Tue'),
                              Tab(text: 'Wed'),
                              Tab(text: 'Thu'),
                              Tab(text: 'Fri'),
                              Tab(text: 'Sat'),
                              Tab(text: 'Sun'),
                            ],
                          ),
                        ),
                      ),

                      // Week View Content
                      SliverFillRemaining(
                        child: TabBarView(
                          controller: _tabController,
                          children: List.generate(7, (index) {
                            final daySchedule = provider.getScheduleForDay(index + 1);
                            return _buildDaySchedule(daySchedule);
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTodaySection(ScheduleProvider provider) {
    final todaySchedule = provider.getTodaySchedule();
    
    return Container(
      color: const Color(0xFF242B3D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.today, color: Colors.blue.shade300, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Schedule',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('EEE, MMM dd').format(DateTime.now()),
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          if (todaySchedule.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey.shade600),
                    const SizedBox(height: 8),
                    Text(
                      'No classes scheduled for today',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...todaySchedule.asMap().entries.map((entry) {
              final index = entry.key;
              final scheduleEntry = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: _buildScheduleCard(scheduleEntry, index, isCompact: true),
              );
            }),

          const SizedBox(height: 8),
          const Divider(color: Color(0xFF3A4050), height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(
              child: Text(
                'FULL WEEK TIMETABLE',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(List<ScheduleEntry> schedule) {
    if (schedule.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'No classes scheduled',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedule.length,
      itemBuilder: (context, index) {
        final entry = schedule[index];
        return _buildScheduleCard(entry, index);
      },
    );
  }

  Widget _buildScheduleCard(ScheduleEntry entry, int index, {bool isCompact = false}) {
    return Card(
      margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isCompact ? 12 : 16)),
      color: const Color(0xFF242B3D),
      elevation: isCompact ? 2 : 4,
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Row(
          children: [
            // Time indicator
            Container(
              width: 4,
              height: isCompact ? 50 : 60,
              decoration: BoxDecoration(
                color: _getColorForIndex(index),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            
            // Time slot
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.startTime,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  entry.endTime,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: isCompact ? 12 : 14,
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 20),
            
            // Class details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.subject,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (entry.subjectCode.isNotEmpty && !isCompact)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        entry.subjectCode,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: isCompact ? 12 : 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          entry.teacher,
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade400,
                            fontSize: isCompact ? 11 : 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: isCompact ? 12 : 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        entry.room,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade400,
                          fontSize: isCompact ? 11 : 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.pink.shade400,
      Colors.indigo.shade400,
    ];
    return colors[index % colors.length];
  }
}
