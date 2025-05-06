import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants.dart';
import '../../controllers/profile_controller.dart';
import '../../models/user.dart';
import 'downloadables.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firebase_storage_service.dart';
import '../auth/login_page.dart';

// Import settings pages
import 'package:medicine/views/settings/edit_profile.dart';
import 'package:medicine/views/settings/change_password.dart';
import 'package:medicine/views/settings/forgot_password.dart';
import 'package:medicine/views/settings/notifications.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  UserModel? currentUser;
  final ProfileController _profileController = ProfileController();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken != null) {
      UserModel? user = await _profileController.fetchUserProfile(idToken);
      setState(() {
        currentUser = user;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String newImageUrl = await _storageService.uploadProfileImage(imageFile, userId);
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken != null) {
        bool success = await _profileController.updateProfileImage(idToken, newImageUrl);
        if (success) {
          setState(() {
            currentUser = currentUser?.copyWith(profileImgUrl: newImageUrl);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the profile image from currentUser; fallback to placeholder if missing.
    String imageUrl = (currentUser != null && currentUser!.profileImgUrl.isNotEmpty)
        ? currentUser!.profileImgUrl
        : "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.person, color: Colors.white),
            SizedBox(width: 8),
            Text("User Profile", style: TextStyle(color: Colors.white, fontSize: 25)),
          ],
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // New Profile Header Layout - Image left, details right
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left side - Profile Image
                  GestureDetector(
                    onTap: () => _pickAndUploadImage(),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundImage: imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : const AssetImage("assets/images/profile_placeholder.png") as ImageProvider,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Right side - User Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User name
                        Text(
                          currentUser != null
                              ? "${currentUser!.firstName} ${currentUser!.lastName}"
                              : "Student Name",
                          style: const TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Student number
                        Text(
                          currentUser != null && currentUser!.student != null
                              ? "Student Number: ${currentUser!.student!.studentNumber}"
                              : "Student Number: ",
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Student level
                        Text(
                          currentUser != null && currentUser!.student != null
                              ? "Level: ${currentUser!.student!.level}"
                              : "Level: ",
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            
            // Menu items section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Academic",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
            // Academic menu items
            _buildMenuItem(Icons.book, "Student Materials", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DownloadablesPage()),
              );
            }),
            _buildMenuItem(Icons.warning, "Ragging Causes", () {}),
            
            // Settings section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Settings",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
            // Settings menu items as tiles
            _buildMenuItem(Icons.person, "Edit Profile", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfilePage()),
              );
            }),
            _buildMenuItem(Icons.lock, "Change Password", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
              );
            }),
            _buildMenuItem(Icons.password, "Forgot Password", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
              );
            }),
            _buildMenuItem(Icons.notifications, "Notifications", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
            }),
            
            // Logout section with some spacing
            const SizedBox(height: 10),
            _buildMenuItem(
              Icons.logout,
              "Log Out",
              () => _showLogoutDialog(context),
              isLogout: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap,
      {bool isLogout = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: isLogout ? Colors.red : AppColors.primaryColor),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isLogout ? Colors.red : Colors.black,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Log Out",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Are you sure you want to log out?",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                                (route) => false,
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Log Out",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}