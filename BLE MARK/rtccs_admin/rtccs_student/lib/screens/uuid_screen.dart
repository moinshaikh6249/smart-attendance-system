import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class UUIDScreen extends StatelessWidget {
  const UUIDScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final student = profileProvider.student;
    return Scaffold(
      appBar: AppBar(title: const Text('My UUID')),
      body: Center(
        child: student == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code, size: 80),
                  const SizedBox(height: 24),
                  Text('Your UUID:', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SelectableText(student.uuid, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 24),
                  Text('Show this code to your teacher for registration.', textAlign: TextAlign.center),
                ],
              ),
      ),
    );
  }
} 