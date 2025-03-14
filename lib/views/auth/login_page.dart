import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicine/views/auth/signup_page.dart';
import '../../core/constants.dart';
import '../main_menu/main_menu.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = ""; // ✅ Store error message

  Future<void> loginUser() async {
    setState(() {
      errorMessage = ""; // ✅ Clear previous errors before attempting login
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      // ✅ If login is successful, navigate to the main menu
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainMenu()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = getErrorMessage(e.code); // ✅ Get user-friendly error message
      });
    }
  }

  // ✅ Function to convert Firebase error codes into user-friendly messages
  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case "invalid-email":
        return "Invalid email format.";
      case "user-disabled":
        return "This user has been disabled.";
      case "user-not-found":
        return "No user found with this email.";
      case "wrong-password":
        return "Incorrect password. Please try again.";
      case "too-many-requests":
        return "Too many attempts. Try again later.";
      default:
        return "Login failed. Please try again.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 40),
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

              Center(
                child: Container(
                  margin: EdgeInsets.only(bottom: 24),
                  child: Image.asset(
                    'assets/images/login-hero.png',
                    height: 300,
                    width: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Student email",
                        prefixIcon: Icon(Icons.email, color: AppColors.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock, color: AppColors.primaryColor),
                        suffixIcon: TextButton(
                          onPressed: () {
                            // Forgot Password Logic
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
                    SizedBox(height: 16),

                    // ✅ Show error message in red if there's any
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          errorMessage,
                          style: TextStyle(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loginUser,
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

                    Center(
                      child: GestureDetector(
                        onTap: () {
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
