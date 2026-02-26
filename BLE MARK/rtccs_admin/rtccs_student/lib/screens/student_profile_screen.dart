import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../models/student.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _isEditing = false;
  bool _isUpdating = false;
  File? _imageFile;
  String? _imageError;

  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _alternateEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final student = profileProvider.student;

    if (student != null) {
      _mobileController.text = student.mobile ?? '';
      _alternateEmailController.text = student.alternateEmail ?? '';
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _alternateEmailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        final int fileSize = await imageFile.length();

        // Check file size (5MB limit)
        if (fileSize > 5 * 1024 * 1024) {
          setState(() {
            _imageError = 'Image size must be less than 5MB';
          });
          return;
        }

        setState(() {
          _imageFile = imageFile;
          _imageError = null;
        });
      }
    } catch (e) {
      setState(() {
        _imageError = 'Failed to pick image: ${e.toString()}';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final student = profileProvider.student;

      if (student == null) {
        throw Exception('Student profile not found');
      }

      // Update profile
      await profileProvider.updateProfile(
        mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
        alternateEmail: _alternateEmailController.text.trim().isEmpty ? null : _alternateEmailController.text.trim(),
        profilePhotoFile: _imageFile,
      );

      if (mounted) {
        setState(() {
          _isEditing = false;
          _imageFile = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Profile updated successfully'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Could not update profile. Please try again.\n${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _imageFile = null;
      _imageError = null;
    });
    _loadProfileData();
  }

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '?';
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final student = profileProvider.student;

    // Security check
    if (student == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1F3A),
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          if (!_isEditing && !_isUpdating)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with profile photo
            _buildProfileHeader(student),

            const SizedBox(height: 24),

            // Profile Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Personal Information Section
                    _buildSectionHeader('Personal Information', Icons.person),
                    _buildInfoCard([
                      _buildInfoRow('Full Name', student.name, Icons.badge, editable: false),
                      _buildInfoRow('Enrollment Number', student.enrollmentNo ?? 'N/A', Icons.numbers, editable: false),
                      _buildInfoRow('PRN', student.prn ?? 'N/A', Icons.confirmation_number, editable: false),
                      _buildInfoRow('UUID', student.uuid, Icons.fingerprint, editable: false, copyable: true),
                    ]),

                    const SizedBox(height: 16),

                    // Academic Information Section
                    _buildSectionHeader('Academic Information', Icons.school),
                    _buildInfoCard([
                      _buildInfoRow('Course / Program', student.program ?? 'N/A', Icons.book, editable: false),
                      _buildInfoRow('Semester', student.semester ?? student.year ?? 'N/A', Icons.calendar_today, editable: false),
                      _buildInfoRow('Division / Batch', student.division ?? 'N/A', Icons.group, editable: false),
                      _buildInfoRow('Class', student.className ?? 'N/A', Icons.class_, editable: false),
                    ]),

                    const SizedBox(height: 16),

                    // Institute Information Section
                    _buildSectionHeader('Institute Information', Icons.business),
                    _buildInfoCard([
                      _buildInfoRow('College / Institute', student.schoolName ?? 'N/A', Icons.account_balance, editable: false),
                      _buildInfoRow('School ID', student.schoolId ?? 'N/A', Icons.tag, editable: false),
                    ]),

                    const SizedBox(height: 16),

                    // Contact Information Section
                    _buildSectionHeader('Contact Information', Icons.contact_phone),
                    _buildInfoCard([
                      _buildInfoRow('Email', student.email ?? 'N/A', Icons.email, editable: false),
                      if (_isEditing)
                        _buildEditableField(
                          'Mobile Number',
                          _mobileController,
                          Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (value.length != 10) {
                                return 'Mobile number must be 10 digits';
                              }
                              if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) {
                                return 'Invalid mobile number';
                              }
                            }
                            return null;
                          },
                        )
                      else
                        _buildInfoRow('Mobile Number', student.mobile ?? 'Not provided', Icons.phone, editable: true),
                      if (_isEditing)
                        _buildEditableField(
                          'Alternate Email',
                          _alternateEmailController,
                          Icons.alternate_email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Invalid email format';
                              }
                            }
                            return null;
                          },
                        )
                      else
                        _buildInfoRow('Alternate Email', student.alternateEmail ?? 'Not provided', Icons.alternate_email, editable: true),
                    ]),

                    const SizedBox(height: 24),

                    // Edit mode buttons
                    if (_isEditing)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isUpdating ? null : _cancelEdit,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(color: Colors.grey.shade400),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdating ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isUpdating
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'Save Changes',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Student student) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade700, const Color(0xFF1A1F3A)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Profile Photo
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.blue.shade300,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : student.profilePhotoUrl != null
                          ? NetworkImage(student.profilePhotoUrl!)
                          : null,
                  child: (_imageFile == null && student.profilePhotoUrl == null)
                      ? Text(
                          _getInitials(student.name),
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            student.name,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Enrollment
          if (student.enrollmentNo != null)
            Text(
              student.enrollmentNo!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.blue.shade200,
              ),
            ),
          const SizedBox(height: 8),
          // Program & Semester
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade800.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${student.program ?? 'Student'} • ${student.semester ?? student.year ?? 'N/A'}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_imageError != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _imageError!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.red.shade300,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade300, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF242B3D),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool editable = false, bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade700.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade300, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    if (editable)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.edit, size: 12, color: Colors.grey.shade500),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (copyable)
                      IconButton(
                        icon: Icon(Icons.copy, size: 18, color: Colors.blue.shade300),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                              backgroundColor: Colors.green.shade700,
                            ),
                          );
                        },
                        tooltip: 'Copy UUID',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade700.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade300, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF1A1F3A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue.shade700),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red.shade500),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: validator,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
