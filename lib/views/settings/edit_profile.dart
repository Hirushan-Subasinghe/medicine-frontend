import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants.dart';
import '../../controllers/profile_controller.dart';
import '../../services/firebase_storage_service.dart';
import '../../models/user.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final ProfileController _profileController = ProfileController();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  
  bool _isLoading = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken != null) {
        final user = await _profileController.fetchUserProfile(idToken);
        if (user != null) {
          setState(() {
            _currentUser = user;
            _firstNameController.text = user.firstName;
            _lastNameController.text = user.lastName;
            _phoneController.text = user.phoneNo;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get authentication token');
      }

      String? imageUrl;
      // Upload image if selected
      if (_profileImage != null) {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        imageUrl = await _storageService.uploadProfileImage(_profileImage!, userId);
        
        // Update profile image in backend
        await _profileController.updateProfileImage(idToken, imageUrl);
      }

      // Update profile data in backend
      final success = await _profileController.updateProfile(
        idToken,
        _firstNameController.text,
        _lastNameController.text,
        _phoneController.text,
      );
      
      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Profile update failed');
      }
    } catch (e) {
      print('Error saving profile: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primaryColor),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    // Profile image
                    
                    
                    // Input fields
                    _buildInputField("First name", _firstNameController),
                    _buildInputField("Last name", _lastNameController),
                    _buildInputField("Phone number", _phoneController, keyboardType: TextInputType.phone),
                    
                    // Student information display (non-editable)
                    if (_currentUser?.student != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            "Student Information",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildInfoField("Student Number", _currentUser!.student!.studentNumber),
                          _buildInfoField("Level", _currentUser!.student!.level),
                          _buildInfoField("Academic Year", _currentUser!.student!.academicYear),
                        ],
                      ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(icon: const Icon(Icons.home_outlined), onPressed: () {}),
            IconButton(icon: const Icon(Icons.search_outlined), onPressed: () {}),
            IconButton(icon: const Icon(Icons.person_outlined, color: Colors.red), onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType ?? TextInputType.text,
          decoration: InputDecoration(
            hintText: 'Enter your $label',
            fillColor: Colors.grey[100],
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}