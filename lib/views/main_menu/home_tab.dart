import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants.dart';
import '../../widgets/emergency_fab_menu.dart';
import '../../controllers/profile_controller.dart';
import '../../models/user.dart';
import '../../services/user_state_service.dart';
import 'notification_tab.dart';
import 'map_tab.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  UserModel? currentUser;
  final ProfileController _profileController = ProfileController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final idToken = await firebaseUser.getIdToken();
        if (idToken != null) {
          final user = await _profileController.fetchUserProfile(idToken);
          if (mounted) {
            setState(() {
              currentUser = user;
              isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading user: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.home, color: Colors.white),
            SizedBox(width: 8),
            Text("Home", style: TextStyle(color: Colors.white, fontSize: 25)),
          ],
        ),
        backgroundColor: AppColors.primaryColor, // Top bar
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserBanner(), // Banner with secondary color now
            _buildCategoriesSection(),
            _buildAdditionalSection(),
          ],
        ),
      ),
      floatingActionButton: const EmergencyFabMenu(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildUserBanner() {
    String userName = "Student";
    String userDescription = "Stay updated with important notifications and quick access to materials.";

    if (currentUser != null) {
      userName = "${currentUser!.firstName} ${currentUser!.lastName}";
      
      // Create personalized description based on student data
      if (currentUser!.student != null) {
        final student = currentUser!.student!;
        final level = student.level.replaceAll('_', ' ');
        userDescription = "Welcome to your academic portal! You are currently in $level, Academic Year ${student.academicYear}. Stay connected with your studies and important updates.";
      } else {
        userDescription = "Welcome to your academic portal! Access your materials, notifications, and important university resources.";
      }
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor, // Changed to secondary color
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isLoading ? "Welcome, Loading..." : "Welcome, $userName!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            userDescription,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Access",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            children: [
              _buildCategoryItem(Icons.school, "LMS", url: "https://ekel.kln.ac.lk/login/index.php"),
              _buildCategoryItem(Icons.local_library, "Faculty Library", url: "https://medicine.kln.ac.lk/units/library/"),
              _buildCategoryItem(Icons.library_books, "University Library", url: "https://library.kln.ac.lk/"),
              _buildCategoryItem(Icons.public, "University Website", url: "https://www.kln.ac.lk/"),
              _buildCategoryItem(Icons.home_work, "Faculty Website", url: "https://medicine.kln.ac.lk/"),
              _buildCategoryItem(Icons.person, "Student Portal", url: "https://medicine.kln.ac.lk/index.php/mbbs-student-portal.html"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label, {String? url}) {
    return Builder(
      builder: (context) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () async {
            if (url != null) {
              try {
                final uri = Uri.parse(url);
                print('Trying to launch: $url');
                
                // Try in-app web view first (works better on emulators)
                bool launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
                print('In-app web view launch result: $launched');
                
                // If in-app failed, try external application
                if (!launched && await canLaunchUrl(uri)) {
                  launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                  print('External launch result: $launched');
                }
                
                // If external failed, try platform default
                if (!launched && await canLaunchUrl(uri)) {
                  launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
                  print('Platform default launch result: $launched');
                }
                
                if (!launched) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not launch $url. Please install a web browser or try on a real device.'),
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                print('Error launching URL: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            } else {
              // Handle category tap
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primaryColor, size: 32),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tools & Features",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Column(
            children: [
              _buildFeatureCard(
                "Student Materials",
                "Access your study materials, notes, and resources",
                Icons.folder,
              ),
              _buildFeatureCard(
                "Notifications",
                "View your notifications and announcements",
                Icons.notifications,
              ),
              _buildFeatureCard(
                "Campus Map",
                "Navigate around the campus easily",
                Icons.map,
              ),
              _buildFeatureCard(
                "Contact Faculty",
                "Get in touch with your professors",
                Icons.contact_phone,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryColor),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description, style: TextStyle(fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (title == "Student Materials") {
            // Navigate to Student Materials page
            Navigator.pushNamed(context, '/materials');
          } else if (title == "Notifications") {
            // Navigate to Notifications tab
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => NotificationTab())
            );
          } else if (title == "Campus Map") {
            // Navigate to Map tab
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => MapTab())
            );
          } else if (title == "Contact Faculty") {
            // Show contact popup
            _showContactFacultyPopup();
          }
        },
      ),
    );
  }

  void _showContactFacultyPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.contact_phone, color: AppColors.primaryColor, size: 24),
                    SizedBox(width: 8),
                    Text(
                      "Contact Faculty",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                // Phone Numbers
                _buildContactItem(
                  Icons.phone,
                  "+94 11 2961000",
                  () => _makePhoneCall("+94112961000"),
                ),
                _buildContactItem(
                  Icons.phone,
                  "+94 11 2958337", 
                  () => _makePhoneCall("+94112958337"),
                ),
                
                // Email Addresses
                _buildContactItem(
                  Icons.email,
                  "info.med@kln.ac.lk",
                  () => _sendEmail("info.med@kln.ac.lk"),
                ),
                _buildContactItem(
                  Icons.email,
                  "deanmed@kln.ac.lk",
                  () => _sendEmail("deanmed@kln.ac.lk"),
                ),
                
                SizedBox(height: 20),
                Text(
                  "Follow Us",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 10),
                
                // Social Media Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSocialMediaIcon(
                      Icons.facebook,
                      Colors.blue[800]!,
                      "https://web.facebook.com/medicineuok?_rdc=1&_rdr",
                    ),
                    _buildSocialMediaIcon(
                      Icons.video_library,
                      Colors.red,
                      "https://www.youtube.com/user/medicineuok",
                    ),
                    _buildSocialMediaIcon(
                      Icons.alternate_email,
                      Colors.blue[400]!,
                      "https://x.com/MedicineUoK",
                    ),
                    _buildSocialMediaIcon(
                      Icons.business,
                      Colors.blue[700]!,
                      "https://www.linkedin.com/company/medicineuok/",
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

  Widget _buildContactItem(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue[700],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaIcon(IconData icon, Color color, String url) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not make phone call')),
        );
      }
    } catch (e) {
      print('Error making phone call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open email client')),
        );
      }
    } catch (e) {
      print('Error sending email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    } catch (e) {
      print('Error launching URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
