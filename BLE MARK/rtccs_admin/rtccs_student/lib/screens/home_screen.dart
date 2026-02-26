import 'package:flutter/material.dart';
import 'attendance_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'uuid_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RTCCS Student'),
        elevation: 4,
      ),
      body: IndexedStack(
        index: _navIndex,
        children: const [
          AttendanceScreen(),
          HistoryScreen(),
          ProfileScreen(),
          UUIDScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bluetooth), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'My UUID'),
        ],
      ),
    );
  }
} 