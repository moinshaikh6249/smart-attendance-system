import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../widgets/student_search_box.dart';
import '../widgets/student_profile_picture.dart';
import '../theme.dart';
import '../widgets/branded_app_bar.dart';
import '../widgets/bottom_nav.dart';

class StudentSearchScreen extends StatefulWidget {
  const StudentSearchScreen({Key? key}) : super(key: key);

  @override
  State<StudentSearchScreen> createState() => _StudentSearchScreenState();
}

class _StudentSearchScreenState extends State<StudentSearchScreen> {
  int navIndex = 4;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load all students when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      studentProvider.loadAllStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final horizontalPadding = isTablet ? 48.0 : 16.0;
    final verticalPadding = isTablet ? 32.0 : 16.0;

    // Local filter for search
    final filteredStudents = _searchQuery.isEmpty
        ? studentProvider.students
        : studentProvider.students.where((s) =>
            s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (s.uuid.toLowerCase().contains(_searchQuery.toLowerCase()))
          ).toList();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrandedAppBar(title: 'Student Search'),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          child: Column(
            children: [
              StudentSearchBox(onChanged: (value) {
                setState(() => _searchQuery = value);
              }),
              const SizedBox(height: 16),
              Expanded(
                child: studentProvider.loading
                    ? const Center(child: CircularProgressIndicator())
                    : studentProvider.error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Error: ${studentProvider.error}',
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
                                    studentProvider.loadAllStudents();
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : filteredStudents.isEmpty
                            ? Center(
                                child: Text(
                                  _searchQuery.isEmpty
                                      ? 'No students found'
                                      : 'No students match your search',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredStudents.length,
                                itemBuilder: (context, i) {
                                  final student = filteredStudents[i];
                                  return Card(
                                    child: ListTile(
                                      leading: StudentProfilePicture(photoUrl: student.profilePhotoUrl),
                                      title: Text(student.name, style: Theme.of(context).textTheme.titleMedium),
                                      subtitle: Text(student.email ?? student.phoneNumber ?? ''),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: navIndex,
          onTap: (i) {
            setState(() => navIndex = i);
            // Add navigation logic for each tab if needed
          },
        ),
      ),
    );
  }
} 