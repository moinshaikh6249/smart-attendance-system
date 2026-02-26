import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PhotoService {
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;
  PhotoService._internal();

  final ImagePicker _picker = ImagePicker();

  Future<File?> captureFacePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
} 