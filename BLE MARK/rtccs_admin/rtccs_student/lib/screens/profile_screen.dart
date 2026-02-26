import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../services/photo_service.dart';
import 'dart:io';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final student = profileProvider.student;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: student == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: student.profilePhotoUrl != null ? NetworkImage(student.profilePhotoUrl!) : null,
                    child: student.profilePhotoUrl == null ? const Icon(Icons.person, size: 48) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(student.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(student.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text('UUID: ${student.uuid}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  if (profileProvider.isLoading)
                    const CircularProgressIndicator(),
                  if (profileProvider.error != null)
                    Text(profileProvider.error!, style: const TextStyle(color: Colors.red)),
                  if (profileProvider.success != null)
                    Text(profileProvider.success!, style: const TextStyle(color: Colors.green)),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Change Photo'),
                    onPressed: () async {
                      final file = await PhotoService().captureProfilePhoto();
                      if (file != null) {
                        await context.read<ProfileProvider>().updateProfilePhoto(student.uuid, file);
                        await context.read<ProfileProvider>().fetchProfile(student.uuid);
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
} 