import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/optional/academic_calendar_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/module_availability_service.dart';
import '../../services/module_error_handler.dart';

class AcademicCalendarScreen extends StatelessWidget {
  const AcademicCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final schoolId = profileProvider.student?.schoolId;

    return ModuleAvailabilityService.moduleGuard(
      moduleName: 'calendar',
      schoolId: schoolId,
      child: const _AcademicCalendarContent(),
    );
  }
}

class _AcademicCalendarContent extends StatefulWidget {
  const _AcademicCalendarContent();

  @override
  State<_AcademicCalendarContent> createState() => _AcademicCalendarContentState();
}

class _AcademicCalendarContentState extends State<_AcademicCalendarContent> {
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _loadCalendar();
  }

  Future<void> _loadCalendar({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final calendarProvider = Provider.of<AcademicCalendarProvider>(context, listen: false);

    final student = profileProvider.student;
    if (student == null || student.schoolId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    await calendarProvider.fetchCalendarEvents(
      schoolId: student.schoolId!,
      studentUUID: student.uuid,
      program: student.program,
      year: student.year,
      showLoading: showLoading,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadCalendar(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F3A),
      appBar: AppBar(
        title: Text('Academic Calendar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              final provider = Provider.of<AcademicCalendarProvider>(context, listen: false);
              provider.setFilter(value);
            },
            itemBuilder: (context) => [
              _buildFilterMenuItem('All Events', 'all'),
              _buildFilterMenuItem('Holidays', 'holidays'),
              _buildFilterMenuItem('Exams', 'exams'),
              _buildFilterMenuItem('College Events', 'events'),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? ModuleErrorHandler.buildLoadingState(message: 'Loading calendar...')
          : Consumer<AcademicCalendarProvider>(
              builder: (context, provider, child) {
                // Handle errors
                if (provider.error != null && provider.events.isEmpty) {
                  final errorMsg = provider.error!;
                  if (errorMsg.contains('timeout') || errorMsg.contains('network')) {
                    return ModuleErrorHandler.buildErrorState(
                      moduleName: 'calendar',
                      error: 'Unable to load calendar. Please connect to the internet.',
                      onRetry: _loadCalendar,
                    );
                  }
                  return ModuleErrorHandler.buildErrorState(
                    moduleName: 'calendar',
                    error: provider.error!,
                    onRetry: _loadCalendar,
                  );
                }

                // Handle empty state
                if (provider.events.isEmpty) {
                  return ModuleErrorHandler.buildEmptyState(
                    moduleName: 'calendar',
                    icon: Icons.calendar_today,
                    message: 'No calendar events available',
                  );
                }

                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: Colors.white,
                  backgroundColor: Colors.blue.shade700,
                  child: CustomScrollView(
                    slivers: [
                      // Cache/offline indicator
                      if (provider.isFromCache || (provider.error != null && provider.events.isNotEmpty))
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
                                    provider.error ?? 'Showing last updated calendar.',
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

                      // Active filter indicator
                      if (provider.selectedFilter != 'all')
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
                                  'Filter: ${_getFilterLabel(provider.selectedFilter)} (${provider.filteredEvents.length})',
                                  style: GoogleFonts.poppins(
                                    color: Colors.blue.shade200,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => provider.setFilter('all'),
                                  child: Icon(Icons.close, color: Colors.blue.shade300, size: 20),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Calendar
                      SliverToBoxAdapter(
                        child: _buildCalendar(provider),
                      ),

                      // Events for selected date
                      SliverToBoxAdapter(
                        child: _buildEventsForSelectedDate(provider),
                      ),

                      // All events list
                      SliverToBoxAdapter(
                        child: _buildEventsList(provider),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  PopupMenuItem<String> _buildFilterMenuItem(String label, String value) {
    return PopupMenuItem(
      value: value,
      child: Consumer<AcademicCalendarProvider>(
        builder: (context, provider, child) {
          final isSelected = provider.selectedFilter == value;
          return Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 20,
                color: isSelected ? Colors.blue : null,
              ),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.blue : null)),
            ],
          );
        },
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'holidays':
        return 'Holidays';
      case 'exams':
        return 'Exams';
      case 'events':
        return 'College Events';
      default:
        return 'All Events';
    }
  }

  Widget _buildCalendar(AcademicCalendarProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF242B3D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(provider.selectedDate, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
          provider.setSelectedDate(selectedDay);
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        eventLoader: (day) => provider.getEventsForDate(day),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.blue.shade700,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.green.shade700,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.orange.shade400,
            shape: BoxShape.circle,
          ),
          weekendTextStyle: GoogleFonts.poppins(color: Colors.red.shade300),
          defaultTextStyle: GoogleFonts.poppins(color: Colors.white),
          outsideTextStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: Colors.blue.shade700,
            borderRadius: BorderRadius.circular(8),
          ),
          formatButtonTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12),
          weekendStyle: GoogleFonts.poppins(color: Colors.red.shade300, fontSize: 12),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return const SizedBox.shrink();

            final calendarEvents = events.cast<CalendarEvent>();
            final hasHoliday = calendarEvents.any((e) => e.isHoliday);
            final hasExam = calendarEvents.any((e) => e.isExam);

            return Positioned(
              bottom: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasHoliday)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (hasExam)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (!hasHoliday && !hasExam)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventsForSelectedDate(AcademicCalendarProvider provider) {
    final selectedEvents = provider.getEventsForDate(provider.selectedDate);

    if (selectedEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Events on ${DateFormat('MMMM dd, yyyy').format(provider.selectedDate)}',
            style: GoogleFonts.poppins(
              color: Colors.blue.shade300,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...selectedEvents.map((event) => _buildEventCard(event, compact: false)),
        ],
      ),
    );
  }

  Widget _buildEventsList(AcademicCalendarProvider provider) {
    final filteredEvents = provider.filteredEvents;

    if (filteredEvents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: const Color(0xFF242B3D),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.filter_alt_off, size: 64, color: Colors.grey.shade600),
                const SizedBox(height: 16),
                Text(
                  'No events match this filter',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Group by month
    final eventsByMonth = <String, List<CalendarEvent>>{};
    for (var event in filteredEvents) {
      final monthKey = DateFormat('MMMM yyyy').format(event.date);
      eventsByMonth.putIfAbsent(monthKey, () => []).add(event);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Events',
            style: GoogleFonts.poppins(
              color: Colors.blue.shade300,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...eventsByMonth.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    entry.key,
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ...entry.value.map((event) => _buildEventCard(event)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEventCard(CalendarEvent event, {bool compact = true}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF242B3D),
      child: InkWell(
        onTap: () {
          if (compact) {
            final provider = Provider.of<AcademicCalendarProvider>(context, listen: false);
            provider.setSelectedDate(event.date);
            setState(() {
              _focusedDay = event.date;
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: event.typeColor, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: event.typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(event.typeIcon, color: event.typeColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(event.date),
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: event.typeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.eventType,
                            style: GoogleFonts.poppins(
                              color: event.typeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (event.description != null && event.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        event.description!,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade300,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
