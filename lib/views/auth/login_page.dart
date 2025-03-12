import 'package:flutter/material.dart';
import 'package:medicine/views/auth/signup_page.dart';
import '../../core/constants.dart';
import '../main_menu/main_menu.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 40), // Space from top
              // Centered Title & Subtitle
              Center(
                child: Column(
                  children: [
                    Text(
                      "Sign in to continue",
                      style: AppTextStyles.subheading,
                    ),
                    SizedBox(height: 8),
                    Text("Student Login", style: AppTextStyles.heading),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Centered Image - Enlarged with bottom margin
              Center(
                child: Container(
                  margin: EdgeInsets.only(bottom: 24), // Added bottom margin
                  child: Image.asset(
                    'assets/images/login-hero.png', // Ensure the asset exists
                    height: 300, // Larger size
                    width: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Login Form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Email Field
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Student email",
                        prefixIcon: Icon(
                          Icons.email,
                          color: AppColors.primaryColor,
                        ),
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
                        prefixIcon: Icon(
                          Icons.lock,
                          color: AppColors.primaryColor,
                        ),
                        suffixIcon: TextButton(
                          onPressed: () {
                            // Navigate to Forgot Password Page
                          },
                          child: Text(
                            "Forgot?",
                            style: TextStyle(color: AppColors.primaryColor),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle Login
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => MainMenu()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text("Login", style: AppTextStyles.button),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Register Navigation
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to Register Page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentSignupPage(),
                            ),
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            text: "New to the app? ",
                            style: AppTextStyles.body,
                            children: [
                              TextSpan(
                                text: "Register",
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
            ],
          ),
        ),
      ),
    );
  }
}
