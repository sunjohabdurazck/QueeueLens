import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../constants/colors.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  Map<String, dynamic>? _studentData;
  bool _isLoading = true;
  String? _error;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'No user logged in';
          _isLoading = false;
        });
        return;
      }

      final doc = await _firestore.collection('students').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        // Ensure all fields are present with defaults
        final completeData = {
          'name': data['name'] ?? 'Not available',
          'studentId': data['studentID'] ?? 'Not available',
          'email': data['email'] ?? user.email ?? 'Not available',
          'department': data['department'] ?? 'Not available',
          'country': data['country'] ?? 'Not available',
          'batch':
              data['batch'] ??
              _extractBatchFromStudentId(data['studentID'] ?? ''),
          'phone': data['phone'] ?? 'Not provided',
          'profileImage': data['profileImage'],
        };

        setState(() {
          _studentData = completeData;
          _isLoading = false;
        });

        print('Fetched student data: $_studentData'); // Debug log
      } else {
        // If no student document exists, create one with basic info
        await _createStudentDocument(user);
        setState(() {
          _error = 'Student data not found. Created new profile.';
          _isLoading = false;
        });
        // Retry fetching
        await _fetchStudentData();
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
        _isLoading = false;
      });
      print('Error fetching student data: $e'); // Debug log
    }
  }

  Future<void> _createStudentDocument(User user) async {
    try {
      await _firestore.collection('students').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'name': user.displayName ?? 'Student',
        'studentId': '', // Will be filled later
        'department': '',
        'country': '',
        'batch': '',
        'phone': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating student document: $e');
    }
  }

  String _extractBatchFromStudentId(String studentId) {
    if (studentId.length >= 2 && RegExp(r'^\d{9}$').hasMatch(studentId)) {
      return '20${studentId.substring(0, 2)}';
    }
    return 'Unknown';
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: IUTColors.textSecondary,
            ),
          ),
          Text(
            value ?? 'Not available',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: IUTColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text.isEmpty ||
                  confirmPasswordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await user.updatePassword(newPasswordController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password updated successfully'),
                    backgroundColor: IUTColors.success,
                  ),
                );
                Navigator.pop(context);
              } on FirebaseAuthException catch (e) {
                String errorMessage;
                if (e.code == 'requires-recent-login') {
                  errorMessage = 'Please sign in again to change password';
                } else {
                  errorMessage = 'Error: ${e.message}';
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
        await _uploadProfileImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadProfileImage() async {
    final user = _auth.currentUser;
    if (user == null || _profileImage == null) return;

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading profile picture...'),
          backgroundColor: IUTColors.primary,
        ),
      );

      // Create reference to storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');

      // Upload file
      await storageRef.putFile(_profileImage!);

      // Get download URL
      final downloadURL = await storageRef.getDownloadURL();

      // Update Firestore
      await _firestore.collection('students').doc(user.uid).update({
        'profileImage': downloadURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local data
      setState(() {
        _studentData?['profileImage'] = downloadURL;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated!'),
          backgroundColor: IUTColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProfileImage() {
    final imageUrl = _studentData?['profileImage'];

    if (_profileImage != null) {
      return CircleAvatar(
        radius: 40,
        backgroundImage: FileImage(_profileImage!),
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(radius: 40, backgroundImage: NetworkImage(imageUrl));
    } else {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: IUTColors.primary,
          borderRadius: BorderRadius.circular(40),
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 40),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: IUTColors.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchStudentData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header with Editable Image
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: IUTColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Profile Image with edit button
                        Stack(
                          children: [
                            _buildProfileImage(),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: IUTColors.primary,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  onPressed: _pickProfileImage,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _studentData?['name'] ?? 'No Name',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: IUTColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _studentData?['email'] ??
                                    user?.email ??
                                    'No email',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: IUTColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: IUTColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _studentData?['department'] ??
                                      'No Department',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: IUTColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Student Information Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Student Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: IUTColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Student ID', _studentData?['studentId']),
                        const Divider(height: 1),
                        _buildInfoRow(
                          'Department',
                          _studentData?['department'],
                        ),
                        const Divider(height: 1),
                        _buildInfoRow('Country', _studentData?['country']),
                        const Divider(height: 1),
                        _buildInfoRow('Batch', _studentData?['batch']),
                        const Divider(height: 1),
                        _buildInfoRow(
                          'Email',
                          _studentData?['email'] ?? user?.email,
                        ),
                        const Divider(height: 1),
                        _buildInfoRow('Phone', _studentData?['phone']),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Account Actions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: IUTColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: const Text('Email Verification'),
                          trailing: user?.emailVerified == true
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: IUTColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: IUTColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : TextButton(
                                  onPressed: () async {
                                    try {
                                      await user?.sendEmailVerification();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Verification email sent!',
                                          ),
                                          backgroundColor: IUTColors.success,
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Resend'),
                                ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.password_outlined),
                          title: const Text('Change Password'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _changePassword,
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.camera_alt_outlined),
                          title: const Text('Change Profile Picture'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _pickProfileImage,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await FirebaseAuth.instance.signOut();
                          // Navigate to login screen
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error signing out: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
