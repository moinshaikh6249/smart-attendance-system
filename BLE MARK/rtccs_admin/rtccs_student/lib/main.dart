import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/recovery_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/school_provider.dart';
import 'providers/subject_provider.dart';
import 'providers/class_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/ble_broadcast_page.dart';
import 'screens/student_profile_screen.dart';
import 'screens/student_settings_screen.dart';

// Optional module providers
import 'providers/optional/schedule_provider.dart';
import 'providers/optional/fees_provider.dart';
import 'providers/optional/results_provider.dart';
import 'providers/optional/internal_marks_provider.dart';
import 'providers/optional/exam_timetable_provider.dart';
import 'providers/optional/hall_ticket_provider.dart';
import 'providers/optional/academic_calendar_provider.dart';

// Optional module screens
import 'screens/more_screen.dart';
import 'screens/optional/class_schedule_screen.dart';
import 'screens/optional/fees_paid_screen.dart';
import 'screens/optional/internal_marks_screen.dart';
import 'screens/optional/results_screen.dart';
import 'screens/optional/exam_timetable_screen.dart';
import 'screens/optional/hall_ticket_screen.dart';
import 'screens/optional/academic_calendar_screen.dart';
import 'screens/optional/module_placeholders.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RTCCSStudentApp());
}

class RTCCSStudentApp extends StatelessWidget {
  const RTCCSStudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers (always available)
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => SchoolProvider()),
        ChangeNotifierProvider(create: (_) => SubjectProvider()),
        ChangeNotifierProvider(create: (_) => ClassProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Optional module providers (feature-flagged)
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => FeesProvider()),
        ChangeNotifierProvider(create: (_) => ResultsProvider()),
        ChangeNotifierProvider(create: (_) => InternalMarksProvider()),
        ChangeNotifierProvider(create: (_) => ExamTimetableProvider()),
        ChangeNotifierProvider(create: (_) => HallTicketProvider()),
        ChangeNotifierProvider(create: (_) => AcademicCalendarProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) => MaterialApp(
          title: 'BLE Mark Student',
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          // Core routes (always available)
          '/': (context) => const SplashScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/registration': (context) => const RegistrationScreen(),
          '/recovery': (context) => const RecoveryScreen(),
          '/main': (context) => const MainNavigationScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/ble_broadcast': (context) => const BleBroadcastPage(),
          '/profile': (context) => const StudentProfileScreen(),
          '/settings': (context) => const StudentSettingsScreen(),
          
          // Optional module routes (feature-flagged)
          '/more': (context) => const MoreScreen(),
          '/class_schedule': (context) => const ClassScheduleScreen(),
          '/fees_paid': (context) => const FeesPaidScreen(),
          '/hostel_attendance': (context) => const HostelAttendanceScreen(),
          '/itle': (context) => const ITLEScreen(),
          '/certificates': (context) => const CertificatesScreen(),
          '/exam_timetable': (context) => const ExamTimetableScreen(),
          '/register_subject': (context) => const RegisterSubjectScreen(),
          '/internal_marks': (context) => const InternalMarksScreen(),
          '/results': (context) => const ResultsScreen(),
          '/calendar': (context) => const AcademicCalendarScreen(),
          '/feedback': (context) => const FeedbackScreen(),
        },
        ),
      ),
    );
  }
}
