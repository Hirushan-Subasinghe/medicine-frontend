import 'package:flutter/material.dart';
import 'package:medicine/views/auth/signup_page.dart';
import '../../core/constants.dart';
import '../main_menu/main_menu.dart';
import '../../controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthController authController = AuthController();

  bool isLoading = false; // ✅ Loading indicator

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

              // Login Form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Email Field
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Student email",
                        prefixIcon: Icon(Icons.email, color: AppColors.primaryColor),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Password Field
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock, color: AppColors.primaryColor),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isLoading = true;
                          });

                          String email = emailController.text.trim();
                          String password = passwordController.text.trim();
                          String? loginResult = await authController.login(email, password);

                          setState(() {
                            isLoading = false;
                          });

                          if (loginResult == "success") {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => MainMenu()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(loginResult ?? "Login failed")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white) // ✅ Show loading
                            : Text("Login", style: AppTextStyles.button),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Register Navigation
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => StudentSignupPage()),
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
