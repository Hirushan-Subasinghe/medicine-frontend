import 'package:flutter/material.dart';
import '../../core/constants.dart';

class StudentSignupPage extends StatefulWidget {
  @override
  _StudentSignupPageState createState() => _StudentSignupPageState();
}

class _StudentSignupPageState extends State<StudentSignupPage> {
  String? selectedLevel;
  final List<String> levels = [
    "Level 1",
    "Level 2",
    "Level 3",
    "Level 4",
    "Level 5",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.person_add, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Student Signup",
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Text("Create an Account", style: AppTextStyles.heading),
                    SizedBox(height: 8),
                    Text("Sign up to continue", style: AppTextStyles.body),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // First Name Field
              TextField(
                decoration: InputDecoration(
                  labelText: "First Name",
                  prefixIcon: Icon(Icons.person, color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Email Field
              TextField(
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email, color: AppColors.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Level Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Level",
                  prefixIcon: Icon(Icons.school, color: AppColors.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                value: selectedLevel,
                items:
                    levels.map((level) {
                      return DropdownMenuItem(value: level, child: Text(level));
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedLevel = value;
                  });
                },
              ),
              SizedBox(height: 16),

              // Contact Number Field
              TextField(
                decoration: InputDecoration(
                  labelText: "Contact Number",
                  prefixIcon: Icon(Icons.phone, color: AppColors.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),

              // University ID Field
              TextField(
                decoration: InputDecoration(
                  labelText: "University ID",
                  prefixIcon: Icon(Icons.badge, color: AppColors.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Password Field
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock, color: AppColors.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Signup Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle Signup
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text("Sign Up", style: AppTextStyles.button),
                ),
              ),
              SizedBox(height: 24),

              // Login Navigation
              Center(
                child: GestureDetector(
                  onTap: () {
                    // Navigate to Login Page
                  },
                  child: Text.rich(
                    TextSpan(
                      text: "Already have an account? ",
                      style: AppTextStyles.body,
                      children: [
                        TextSpan(
                          text: "Login",
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
