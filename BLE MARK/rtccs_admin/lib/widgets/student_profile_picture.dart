import 'package:flutter/material.dart';

class StudentProfilePicture extends StatelessWidget {
  final String? photoUrl;
  final double size;
  const StudentProfilePicture({Key? key, this.photoUrl, this.size = 48}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(photoUrl!),
        backgroundColor: Colors.grey[200],
      );
    } else {
      return CircleAvatar(
        radius: size / 2,
        child: const Icon(Icons.person, size: 32),
        backgroundColor: Colors.grey[200],
      );
    }
  }
} 