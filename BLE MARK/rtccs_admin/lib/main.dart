import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/school_provider.dart';
import 'providers/student_provider.dart';
import 'providers/admin_profile_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/pending_attendance_screen.dart';
import 'screens/student_approval_screen.dart';
import 'screens/student_search_screen.dart';
import 'screens/requests_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/admin_profile_screen.dart';
import 'screens/login_activity_screen.dart';
import 'theme.dart';
import 'screens/qr_generator_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => SchoolProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => AdminProfileProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) => MaterialApp(
          title: 'RTCCS Smart Attendance Admin',
          theme: appTheme,
          darkTheme: ThemeData.dark(),
          themeMode: settingsProvider.themeMode,
          home: const SplashScreen(),
        routes: {
          // '/': (context) => const RootScreen(), // Removed to fix assertion error
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/attendance': (context) => const AttendanceScreen(),
          '/pending_attendance': (context) => const PendingAttendanceScreen(),
          '/approve': (context) => const StudentApprovalScreen(),
          '/search': (context) => const StudentSearchScreen(),
          '/requests': (context) => const RequestsScreen(),
          '/reports': (context) => const ReportsScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/qr_generator': (context) => const QRGeneratorScreen(),
          '/admin_profile': (context) => const AdminProfileScreen(),
          '/login_activity': (context) => const LoginActivityScreen(),
        },
        ),
      ),
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.user != null) {
      return const DashboardScreen();
    } else {
      return const LoginScreen();
    }
  }
}
